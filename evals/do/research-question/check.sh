source "$EVAL_HERE/do/lib.sh"
note_cap
check_picked research
check_steps research
check_skill_loaded research
notes=$(do_events | jq -r '[.[] | select(.kind == "tool")] | (map(select(.name | test("^(WebSearch|WebFetch|Agent|Task)$"))) | .[0].seq // 1e18) as $search
  | .[] | select(.seq < $search) | select("\(.input.file_path // "") \(.input.command // "")" | test("research/notes\\.md"))
  | select(.name == "Write" or .name == "Edit" or (.name == "Bash" and (.input.command | test(">|tee "))))
  | select("\(.input.content // "") \(.input.new_string // "") \(.input.command // "")" | test("(^|\\n)# .+") and test("constraints"; "i")) | .name' | head -1)
if [ -n "$notes" ]; then pass notes_before_search; else fail notes_before_search "no write of the question and constraints to .evidence/<task>/research/notes.md before the first search"; fi
