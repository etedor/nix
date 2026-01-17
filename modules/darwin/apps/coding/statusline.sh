#!/usr/bin/env bash
# claude code statusline: display context window usage

input=$(cat)

model=$(echo "$input" | jq -r '.model.display_name')
percent_used=$(echo "$input" | jq -r '.context_window.used_percentage // 0')

# round to integer
percent_used=$(printf "%.0f" "$percent_used")

echo "[$model] Context: ${percent_used}%"
