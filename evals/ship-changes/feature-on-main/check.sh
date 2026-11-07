check_skill_loaded
pr=$(new_prs | head -1 | jq -r .number)
branch=$(new_prs | head -1 | jq -r .head)
n=$(new_prs | wc -l | tr -d ' ')
if [ "$n" = 1 ]; then pass one_pr; else fail one_pr "$n PRs opened"; fi
[ -n "$pr" ] || { fail pr_opened "no PR"; exit 0; }
if [ "$branch" != main ]; then pass new_branch; else fail new_branch "PR head is main"; fi
check_branch_name "$branch"
expect remote_main_unchanged "origin/main moved" test "$(git -C "$REMOTE" rev-list --count main)" = 2
expect pushed_head "origin/$branch differs from the local branch" test "$(git -C "$REMOTE" rev-parse "$branch")" = "$(git -C "$REPO" rev-parse "$branch")"
check_conventional_commits "main..$branch" "feat|docs"
if git -C "$REMOTE" log --name-only --format= "main..$branch" | grep -q '.DS_Store'; then fail no_stray_files ".DS_Store was committed"; else pass no_stray_files; fi
check_clean_tree '\.DS_Store$'
check_ran ran_lint '(npm (run )?(-s |--silent )?lint|node scripts/lint)'
check_ran ran_tests '(npm (run )?(-s |--silent )?test|npm t( |$)|node --test)'
check_ran ran_check_pr_text 'check-pr-text'
expect pr_base_main "base is $(pr_field "$pr" .base)" test "$(pr_field "$pr" .base)" = main
check_no_draft
check_title "$pr" feat
check_template "$pr" "$(printf 'Why\nWhat changed\nDecisions\nBlast radius\nVerification')"
check_pr_text "$pr"
check_not_merged
check_reported_url "$pr"
