#!/usr/bin/env bash
file="$CLAUDE_TOOL_INPUT_FILE_PATH"
[ -z "$file" ] || [ ! -f "$file" ] && exit 0
cd "$CLAUDE_PROJECT_DIR" 2>/dev/null || exit 0

if [ -f treefmt.toml ] || [ -f .treefmt.toml ]; then
	treefmt "$file" 2>/dev/null
else
	treefmt --config-file ~/.config/treefmt/treefmt.toml --tree-root . "$file" 2>/dev/null
fi
exit 0
