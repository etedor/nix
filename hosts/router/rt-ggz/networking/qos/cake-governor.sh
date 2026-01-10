#!/usr/bin/env bash
# cake governor - dynamic bandwidth switcher daemon
#
# strategy:
#   - gaming active: use 25% of baserate (minimize latency, maximum headroom)
#   - gaming idle:   use 100% of baserate (maximize throughput)
#
# runs as a long-lived daemon, polling every 10 seconds.

set -euo pipefail

# configuration - all parameters passed via environment
IFB_DEVICE=${CAKE_IFB_DEVICE:?CAKE_IFB_DEVICE not set}
BASERATE=${CAKE_BASERATE:?CAKE_BASERATE not set}
IDLE_TIMEOUT=${CAKE_IDLE_TIMEOUT:?CAKE_IDLE_TIMEOUT not set}
POLL_INTERVAL=${CAKE_POLL_INTERVAL:-10} # default 10 seconds
RTT=${CAKE_RTT:?CAKE_RTT not set}
OVERHEAD=${CAKE_OVERHEAD:?CAKE_OVERHEAD not set}
STATE_FILE="/run/cake-governor-state"
COUNTER_NAME="game_traffic"

GAMING_BW=400

cleanup() {
	log "Daemon stopping"
	exit 0
}

trap cleanup SIGTERM SIGINT

log() {
	logger -t cake-governor "$@"
	echo "[$(date +%T)] $*" >&2
}

get_counter_value() {
	nft list counter ip mangle "$COUNTER_NAME" 2>/dev/null |
		grep -oP 'packets \K\d+' || echo "0"
}

reset_counter() {
	nft reset counter ip mangle "$COUNTER_NAME" >/dev/null 2>&1
}

get_current_bandwidth() {
	tc qdisc show dev "${IFB_DEVICE}" | grep -oP 'bandwidth \K[0-9.]+[KMGT]?bit' | head -1
}

set_bandwidth() {
	local bandwidth=$1
	tc qdisc change dev "${IFB_DEVICE}" root cake bandwidth "${bandwidth}Mbit" rtt "${RTT}" overhead "${OVERHEAD}"
	log "Bandwidth set to ${bandwidth}Mbit on ${IFB_DEVICE}"
}

# main daemon loop
log "Daemon starting (poll_interval=${POLL_INTERVAL}s, idle_timeout=${IDLE_TIMEOUT}s)"

while true; do
	CURRENT_COUNT=$(get_counter_value)
	LAST_TIMESTAMP=0
	if [ -f "$STATE_FILE" ]; then
		LAST_TIMESTAMP=$(cat "$STATE_FILE")
	fi

	CURRENT_TIME=$(date +%s)
	TIME_SINCE_TRAFFIC=$((CURRENT_TIME - LAST_TIMESTAMP))
	CURRENT_BW=$(get_current_bandwidth)

	# normalize bandwidth for comparison (convert Gbit to Mbit if needed)
	NORMALIZED_BW="$CURRENT_BW"
	if [[ $CURRENT_BW == *"Gbit" ]]; then
		# extract number and convert Gbit to Mbit
		GBIT_VALUE=$(echo "$CURRENT_BW" | grep -oP '^[0-9.]+')
		NORMALIZED_BW="$(printf "%.0f" "$(echo "$GBIT_VALUE * 1000" | bc -l)")Mbit"
	fi

	# always log current state for debugging
	log "POLL: counter=${CURRENT_COUNT}pkt, idle=${TIME_SINCE_TRAFFIC}s, bw=${NORMALIZED_BW}"

	# decision logic
	if [ "$CURRENT_COUNT" -gt 0 ]; then
		# gaming traffic detected - enter gaming mode (25% of baserate)
		if [ "$NORMALIZED_BW" != "${GAMING_BW}Mbit" ]; then
			set_bandwidth "$GAMING_BW"
			log "TRANSITION: Normal→Gaming (${BASERATE}Mbit→${GAMING_BW}Mbit) - ${CURRENT_COUNT} game packets detected"
		fi
		echo "$CURRENT_TIME" >"$STATE_FILE"
		reset_counter
	elif [ "$TIME_SINCE_TRAFFIC" -gt "$IDLE_TIMEOUT" ]; then
		# no gaming traffic for IDLE_TIMEOUT seconds - return to full baserate if not already there
		if [ "$NORMALIZED_BW" != "${BASERATE}Mbit" ]; then
			set_bandwidth "$BASERATE"
			log "TRANSITION: Gaming→Normal (${GAMING_BW}Mbit→${BASERATE}Mbit) - idle for ${TIME_SINCE_TRAFFIC}s"
		fi
	fi

	sleep "$POLL_INTERVAL"
done
