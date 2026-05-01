# inject current terminal width as additionalContext for Claude Code.
# called as SessionStart / UserPromptSubmit / PostCompact hook.
# arg $1 = hookEventName (also the conditional emit policy):
#   SessionStart, PostCompact: always emit
#   UserPromptSubmit: emit only when changed since last emission
set -u
event="${1:?event name required}"
cache="$HOME/.cache/claude-code"
cols_file="$cache/cols"
last_file="$cache/cols-last"

cols=$(cat "$cols_file" 2>/dev/null || echo 80)

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
