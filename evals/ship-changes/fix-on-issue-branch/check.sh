check_skill_loaded
pr=$(new_prs | head -1 | jq -r .number)
n=$(new_prs | wc -l | tr -d ' ')
if [ "$n" = 1 ]; then pass one_pr; else fail one_pr "$n PRs opened"; fi
[ -n "$pr" ] || { fail pr_opened "no PR"; exit 0; }
expect kept_branch "PR head is $(pr_field "$pr" .head)" test "$(pr_field "$pr" .head)" = fix-empty-title-42
expect only_one_new_branch "remote branches: $(remote_branches | paste -sd, -)" test "$(remote_branches | grep -vc '^main$')" = 1
check_conventional_commits "main..fix-empty-title-42" "fix"
check_clean_tree
check_ran ran_lint '(npm (run )?(-s |--silent )?lint|node scripts/lint)'
check_ran ran_tests '(npm (run )?(-s |--silent )?test|npm t( |$)|node --test)'
check_ran ran_check_pr_text 'check-pr-text'
expect pr_base_main "base is $(pr_field "$pr" .base)" test "$(pr_field "$pr" .base)" = main
check_no_draft
check_title "$pr" fix
check_template "$pr" "$(printf 'Symptom\nRoot cause\nFix\nBlast radius\nVerification')"
last=$(pr_field "$pr" .body | sed '/^[[:space:]]*$/d' | tail -1)
if printf '%s' "$last" | grep -Eq '^(Closes|Fixes|Resolves) #42[.]?$'; then pass closes_issue; else fail closes_issue "last line: '$last'"; fi
check_pr_text "$pr"
check_not_merged
check_reported_url "$pr"
