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
