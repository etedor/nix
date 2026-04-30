# sourced by writeShellScriptBin — variables injected above
set -euo pipefail

MAX_LINES=5000

list_hosts() {
  echo "hosts:"
  for h in $CLAUDE_HOSTS; do printf "  %s\n" "$h"; done
  echo "switches:"
  for h in $CLAUDE_SWITCHES; do printf "  %s\n" "$h"; done
}

# leading wrapper flags
while [[ $# -gt 0 ]]; do
  case $1 in
    --max-lines=*) MAX_LINES="${1#--max-lines=}"; shift ;;
    --max-lines)   MAX_LINES="$2"; shift 2 ;;
    *) break ;;
  esac
done

[[ $# -ge 1 ]] || { list_hosts; exit 0; }
host=$1; shift

# 141 = SIGPIPE from head closing the pipe early — the cap worked, not a failure
normalize_rc() { [[ $1 -eq 141 ]] && echo 0 || echo "$1"; }

case $host in
  --help|-h)
    cat <<HELP
usage: claude-run [--max-lines=N] <host> [command...]
  NixOS hosts: runs 'ssh claude@<host> sudo <command>'
  switches (sw-*): runs show commands via netmiko
  no command: shows allowed commands (sudo -l)
  --list: shows available targets
  --max-lines: cap output lines (default ${MAX_LINES})

examples:
  claude-run rt-ggz wg show all
  claude-run rt-ggz vtysh -c "show bgp summary"
  claude-run rt-ggz ip -j addr show                # JSON
  claude-run rt-ggz nft -j list ruleset            # JSON
  claude-run rt-ggz journalctl -u blocky --no-pager -n 20
  claude-run --max-lines=100 rt-ggz nft list ruleset
  claude-run rt-ggz nfw                            # bounded by --max-lines
  claude-run rt-ggz nfw --dpt=22                   # filtered firewall logs
  claude-run sw-garage show interfaces status
HELP
    exit 0 ;;
  --list)
    list_hosts; exit 0 ;;
  sw-*)
    [[ $# -gt 0 ]] || { echo "error: switch <host> requires a show command" >&2; exit 2; }
    [[ "$*" == show* ]] || { echo "error: switch only accepts 'show ...' commands" >&2; exit 2; }
    set +o pipefail
    switch-cli "$host" "$@" | head -n "$MAX_LINES"
    rc=${PIPESTATUS[0]}
    set -o pipefail
    rc=$(normalize_rc "$rc")
    [[ $rc -ne 0 ]] && echo "error: switch-cli for $host failed (exit $rc)" >&2
    exit "$rc" ;;
  *)
    if [[ $# -eq 0 ]]; then
      set +o pipefail
      ssh claude@"$host" sudo -l | head -n "$MAX_LINES"
      rc=${PIPESTATUS[0]}
      set -o pipefail
      rc=$(normalize_rc "$rc")
      [[ $rc -eq 255 ]] && echo "error: ssh to $host failed (transport)" >&2
      exit "$rc"
    fi
    cmd=""; for arg in "$@"; do cmd+=" $(printf '%q' "$arg")"; done
    set +o pipefail
    ssh claude@"$host" sudo $cmd | head -n "$MAX_LINES"
    rc=${PIPESTATUS[0]}
    set -o pipefail
    rc=$(normalize_rc "$rc")
    [[ $rc -eq 255 ]] && echo "error: ssh to $host failed (transport)" >&2
    exit "$rc" ;;
esac
