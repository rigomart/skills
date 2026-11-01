#!/usr/bin/env bash
# List recent Claude Code and Codex sessions that ran in any worktree of the current repo.
#
# Usage: sessions.sh [--days N] [<term>...]
#
# Run it from inside the repo. Prints one tab-separated row per session, newest first:
#   modified  agent  prompts  hits  path  first-prompt  last-prompt
# prompts counts the user's messages. hits counts the user's messages matching any
# term (case-insensitive extended regexes); with terms, sessions with no hit are left
# out. --days sets the window by last modification (default 7). Prompts are cut to
# 160 characters; read a whole session with jq or by grepping its path.

set -u

command -v jq >/dev/null || { echo "sessions.sh needs jq" >&2; exit 2; }

days=7
if [ "${1:-}" = "--days" ]; then
  [ -n "${2:-}" ] || { sed -n '4p' "$0" | sed 's/^# *//' >&2; exit 2; }
  days=$2
  shift 2
fi
terms=$(IFS='|'; echo "$*")

worktrees=$(git worktree list --porcelain 2>/dev/null | sed -n 's/^worktree //p')
[ -n "$worktrees" ] || { echo "sessions.sh: run it inside a git repo" >&2; exit 2; }

# One JSON string per user prompt, from either transcript format.
read -r -d '' PROMPTS <<'JQ'
def flat: if type == "string" then . elif type == "array" then map(.text? // "") | join("\n") else "" end;
(if .type == "user" and (.isMeta // false) == false then .message.content
   | if type == "string" then . else map(select(.type == "text") | .text) | join("\n") end
 elif .type == "response_item" and .payload.type == "message" and .payload.role == "user" then .payload.content | flat
 else empty end)
| select(length > 0)
| select(test("^\\s*(<|\\[Request interrupted|# AGENTS\\.md|Caveat:|Base directory for this skill)") | not)
JQ

row() {
  local agent=$1 file=$2
  jq -c "$PROMPTS" "$file" 2>/dev/null | jq -rs --arg agent "$agent" --arg file "$file" --arg terms "$terms" '
    def cut: gsub("\\s+"; " ") | .[0:160];
    (if $terms == "" then 0 else map(select(test($terms; "i"))) | length end) as $hits
    | select(length > 0 and ($terms == "" or $hits > 0))
    | [$agent, (length | tostring), ($hits | tostring), $file, (first | cut), (last | cut)] | @tsv'
}

mtime() { stat -f '%Sm' -t '%Y-%m-%dT%H:%M' "$1" 2>/dev/null || date -r "$1" '+%Y-%m-%dT%H:%M'; }

{
  while IFS= read -r wt; do
    slug=$(printf '%s' "$wt" | tr '/.' '--')
    dir="$HOME/.claude/projects/$slug"
    [ -d "$dir" ] || continue
    find "$dir" -maxdepth 1 -name '*.jsonl' -mtime "-$days" | while IFS= read -r f; do
      r=$(row claude "$f") && [ -n "$r" ] && printf '%s\t%s\n' "$(mtime "$f")" "$r"
    done
  done <<<"$worktrees"

  if [ -d "$HOME/.codex/sessions" ]; then
    find "$HOME/.codex/sessions" -name '*.jsonl' -mtime "-$days" | while IFS= read -r f; do
      cwd=$(head -n 1 "$f" | jq -r 'select(.type == "session_meta") | .payload.cwd // empty' 2>/dev/null)
      [ -n "$cwd" ] && grep -Fxq -- "$cwd" <<<"$worktrees" || continue
      r=$(row codex "$f") && [ -n "$r" ] && printf '%s\t%s\n' "$(mtime "$f")" "$r"
    done
  fi
} | sort -r
