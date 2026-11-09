check_skill_loaded
check_ran ran_stack_ready 'stack-ready'
if gh_calls | grep -Eq '^stack merge (8|9)( |$).*--yes'; then pass stack_merged_from_top; else fail stack_merged_from_top "no 'gh stack merge 8 --yes' (or stack 9): $(gh_calls | grep -E '^(stack|pr) merge' | paste -sd'|' -)"; fi
if gh_calls | grep -Eq '^pr merge'; then fail no_pr_merge "ran: $(gh_calls | grep -E '^pr merge' | head -1)"; else pass no_pr_merge; fi
expect both_merged "states: $(jq -c '[.prs[] | {number, state}]' "$EVAL_GH_STATE/state.json")" \
  jq -e '[.prs[] | select(.number == 7 or .number == 8) | .state] == ["MERGED", "MERGED"]' "$EVAL_GH_STATE/state.json"
if gh_calls | grep -q -- '--admin'; then fail no_admin "used --admin"; else pass no_admin; fi
if final_text | grep -Eiq 'merged'; then pass reported_merged; else fail reported_merged "final reply does not say the stack merged"; fi
check_reported_url 7
check_reported_url 8
