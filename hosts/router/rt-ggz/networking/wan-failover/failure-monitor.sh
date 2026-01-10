#!/usr/bin/env bash
set -euo pipefail

PING_INTERVAL=5
MISS_THRESHOLD=2
HIT_THRESHOLD=2

IFACE="$1"
DISTANCE="$2"
TARGET1="$3"
TARGET2="$4"
GATEWAY="$5"

STATE_DIR=/run/wan-failmon
STATE_FILE=$STATE_DIR/$IFACE.state
mkdir -p "$STATE_DIR"

CURL="@curl@/bin/curl"
CONNTRACK="@conntrack@/bin/conntrack"
VTYSH="@frr@/bin/vtysh"

PUSHOVER_USER_KEY="$(grep 'USER_KEY' @pushoverPath@ | cut -d'=' -f2)"
PUSHOVER_API_TOKEN="$(grep 'API_TOKEN' @pushoverPath@ | cut -d'=' -f2)"

log() {
	local level="$1"
	local message="$2"
	echo "[$IFACE] [$level] $message"
}

log_info() {
	log "INFO" "$1"
}

log_warn() {
	log "WARN" "$1"
}

log_error() {
	log "ERROR" "$1"
}

pushover() {
	local title
	local message
	local priority

	title="@hostname@ - $IFACE"
	message="$1"
	priority="${2:-0}"

	if [[ -z $PUSHOVER_USER_KEY || -z $PUSHOVER_API_TOKEN ]]; then
		log_error "Pushover credentials not configured"
		return 1
	fi

	log_info "Sending Pushover notification: $title: $message"

	$CURL -s \
		--form-string "token=$PUSHOVER_API_TOKEN" \
		--form-string "user=$PUSHOVER_USER_KEY" \
		--form-string "title=$title" \
		--form-string "message=$message" \
		--form-string "priority=$priority" \
		https://api.pushover.net/1/messages.json >/dev/null

	return $?
}

vty() {
	log_info "Executing FRR command: $1"
	if $VTYSH -c "configure terminal" -c "$1"; then
		return 0
	else
		log_error "FRR command failed"
		return 1
	fi
}

# usage: default_route <add|remove>
default_route() {
	local action="$1"
	local via_specifier
	local via_description
	local log_verb
	local frr_prefix

	if [ -n "$GATEWAY" ]; then
		via_specifier="$GATEWAY"
		via_description="gateway $GATEWAY"
	else
		via_specifier="$IFACE"
		via_description="interface $IFACE"
	fi

	if [ "$action" == "add" ]; then
		log_verb="Adding"
		frr_prefix="ip route"
	elif [ "$action" == "remove" ]; then
		log_verb="Removing"
		frr_prefix="no ip route"
	else
		log_error "Invalid action '$action' specified for default_route"
		return 1
	fi

	log_info "$log_verb default route via $via_description"
	vty "$frr_prefix 0.0.0.0/0 $via_specifier $DISTANCE"
}

flush_nat() {
	log_info "Flushing NAT connections for interface $IFACE"
	case "$IFACE" in
	@wan0@) $CONNTRACK -D --zone 1 || true ;;
	@wan1@) $CONNTRACK -D --zone 2 || true ;;
	*) ;;
	esac
}

p() {
	local target="$1"
	ping -I "$IFACE" -c 1 -W 2 -q "$target" &>/dev/null
	return $?
}

check_connectivity() {
	if p "$TARGET1"; then
		return 0
	elif p "$TARGET2"; then
		return 0
	else
		log_warn "Connectivity check failed: cannot reach $TARGET1 or $TARGET2 via $IFACE"
		return 1
	fi
}

log_info "Starting WAN failover monitor for $IFACE"
log_info "Using targets: $TARGET1, $TARGET2"

log_info "Performing initial connectivity check"
if check_connectivity; then
	log_info "Interface $IFACE is UP at startup"
	echo up >"$STATE_FILE"
	default_route add
else
	log_info "Interface $IFACE is DOWN at startup"
	echo down >"$STATE_FILE"
	default_route remove
fi

failCount=0
successCount=0

while true; do
	state=$(<"$STATE_FILE")

	if check_connectivity; then
		((successCount += 1))
		failCount=0
	else
		((failCount += 1))
		successCount=0
	fi

	if [[ $state == up && $failCount -ge $MISS_THRESHOLD ]]; then
		log_info "Interface $IFACE is going DOWN"
		echo down >"$STATE_FILE"
		default_route remove
		flush_nat
		pushover "Interface $IFACE is DOWN" 1

	elif [[ $state == down && $successCount -ge $HIT_THRESHOLD ]]; then
		log_info "Interface $IFACE is coming UP"
		echo up >"$STATE_FILE"
		default_route add
		pushover "Interface $IFACE is UP" 0

		if [[ $IFACE == "@wan0@" ]]; then
			log_info "Primary interface @wan0@ is up, flushing connections for backup interface"
			$CONNTRACK -D --zone 2 || true
		fi
	fi

	sleep "$PING_INTERVAL"
done
