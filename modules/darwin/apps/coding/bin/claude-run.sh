#!/usr/bin/env bash
set -euo pipefail
[[ $# -ge 1 ]] || { echo "usage: claude-run <host> [command...]" >&2; exit 1; }
host=$1; shift

case $host in
  --help|-h)
    echo "usage: claude-run <host> [command...]"
    echo "  NixOS hosts: runs 'ssh claude@<host> sudo <command>'"
    echo "  switches (sw-*): runs show commands via netmiko"
    echo "  no command: shows allowed commands (sudo -l)"
    exit 0 ;;
  sw-*)
    [[ $# -gt 0 ]] || { echo "switch: pass a show command" >&2; exit 1; }
    [[ "$*" == show* ]] || { echo "switch: only show commands allowed" >&2; exit 1; }
    exec switch-cli "$host" "$@" ;;
  *)
    [[ $# -gt 0 ]] || exec ssh claude@"$host" sudo -l
    exec ssh claude@"$host" sudo "$@" ;;
esac
