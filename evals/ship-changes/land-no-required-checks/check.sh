check_skill_loaded
check_ran ran_can_auto_merge 'can-auto-merge'
check_not_merged
expect pr_still_open "PR #7 is $(pr_field 7 .state)" test "$(pr_field 7 .state)" = OPEN
if final_text | grep -Eiq 'required (status )?checks?'; then pass explained_no_required_checks; else fail explained_no_required_checks "final reply never mentions the missing required checks"; fi
