#!/usr/bin/env bash
# Stop hook: the first time the agent stops, sends .claude/eval-followup back as
# the user's next message. It reaches the agent as "Stop hook feedback: <text>".
d="$CLAUDE_PROJECT_DIR/.claude"
[ -f "$d/eval-followup" ] || exit 0
msg=$(cat "$d/eval-followup"); mv "$d/eval-followup" "$d/eval-followup.sent"
jq -n --arg r "$msg" '{decision: "block", reason: $r}'
