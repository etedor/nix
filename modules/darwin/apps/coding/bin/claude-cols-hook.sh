# inject current terminal width as additionalContext for Claude Code.
# called as SessionStart / UserPromptSubmit / PostCompact hook.
# arg $1 = hookEventName (also the conditional emit policy):
#   SessionStart, PostCompact: always emit
#   UserPromptSubmit: emit only when changed since last emission
#
# resolution: walk PPID chain to find a TTY-attached process, then read
# the kernel's record of the PTY size via stty. Per-window accurate, live
# (kernel is updated by the terminal emulator's TIOCSWINSZ on resize).
set -u
event="${1:?event name required}"
cache="$HOME/.cache/claude-code"
last_file="$cache/cols-last"

cols=
pid=$PPID
for _ in 1 2 3 4 5 6 7 8; do
  tty=$(ps -o tty= -p "$pid" 2>/dev/null | tr -d ' ')
  if [ -n "$tty" ] && [ "$tty" != "??" ]; then
    cols=$(stty size < "/dev/$tty" 2>/dev/null | awk '{print $2}')
    break
  fi
  pid=$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ')
  [ -z "$pid" ] || [ "$pid" = "1" ] && break
done
[ -z "$cols" ] && cols=80

if [ "$event" = "UserPromptSubmit" ]; then
  last=$(cat "$last_file" 2>/dev/null || true)
  [ "$cols" = "$last" ] && exit 0
fi

mkdir -p "$cache" 2>/dev/null
printf '%s\n' "$cols" > "$last_file"

jq -nc \
  --arg c "$cols" \
  --arg e "$event" \
  '{hookSpecificOutput:{hookEventName:$e,additionalContext:("Terminal width: "+$c+" columns. Wrap shell commands with \\ continuations to fit.")}}'
