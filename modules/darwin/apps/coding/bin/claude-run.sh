# sourced by writeShellScriptBin — variables injected above
set -euo pipefail

list_hosts() {
  echo "hosts:"
  for h in $CLAUDE_HOSTS; do printf "  %s\n" "$h"; done
  echo "switches:"
  for h in $CLAUDE_SWITCHES; do printf "  %s\n" "$h"; done
}

[[ $# -ge 1 ]] || { list_hosts; exit 0; }
host=$1; shift

case $host in
  --help|-h)
    echo "usage: claude-run <host> [command...]"
    echo "  NixOS hosts: runs 'ssh claude@<host> sudo <command>'"
    echo "  switches (sw-*): runs show commands via netmiko"
    echo "  no command: shows allowed commands (sudo -l)"
    echo "  --list: shows available targets"
    echo ""
    echo "examples:"
    echo "  claude-run rt-ggz wg show all"
    echo '  claude-run rt-ggz vtysh -c "show bgp summary"'
    echo "  claude-run rt-ggz ip -br addr show"
    echo "  claude-run rt-ggz nft list ruleset"
    echo "  claude-run rt-ggz journalctl -u blocky --no-pager -n 20"
    echo "  claude-run rt-ggz nfw | head -n50              # firewall logs (routers)"
    echo "  claude-run rt-ggz nfw --dpt=22 | head -n20     # filtered firewall logs"
    echo "  claude-run sw-garage show interfaces status"
    exit 0 ;;
  --list)
    list_hosts; exit 0 ;;
  sw-*)
    [[ $# -gt 0 ]] || { echo "switch: pass a show command" >&2; exit 1; }
    [[ "$*" == show* ]] || { echo "switch: only show commands allowed" >&2; exit 1; }
    exec switch-cli "$host" "$@" ;;
  *)
    [[ $# -gt 0 ]] || exec ssh claude@"$host" sudo -l
    cmd=""; for arg in "$@"; do cmd+=" $(printf '%q' "$arg")"; done
    exec ssh claude@"$host" sudo $cmd ;;
esac
