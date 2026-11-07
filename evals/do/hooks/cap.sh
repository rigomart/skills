#!/usr/bin/env bash
# PreToolUse hook: ends the run at the first tool call that matches the
# scenario's cap, .claude/eval-cap (an extended regex over "<tool> <input JSON>"),
# so a run stops once it has picked a playbook, copied its steps and started.
d="$CLAUDE_PROJECT_DIR/.claude"
[ -s "$d/eval-cap" ] || exit 0
call=$(jq -r '"\(.tool_name) \(.tool_input | tojson)"')
printf '%s' "$call" | grep -Eq -f "$d/eval-cap" || exit 0
printf '%s\n' "$call" | cut -c1-300 >> "$d/eval-cap.log"
jq -n '{continue: false, stopReason: "eval cap reached",
  hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: "eval cap reached"}}'
