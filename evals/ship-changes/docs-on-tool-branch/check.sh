check_skill_loaded
pr=$(new_prs | head -1 | jq -r .number)
branch=$(new_prs | head -1 | jq -r .head)
n=$(new_prs | wc -l | tr -d ' ')
if [ "$n" = 1 ]; then pass one_pr; else fail one_pr "$n PRs opened"; fi
[ -n "$pr" ] || { fail pr_opened "no PR"; exit 0; }
if printf '%s' "$branch" | grep -q '^claude/'; then fail renamed_tool_branch "PR head is $branch"; else pass renamed_tool_branch; fi
check_branch_name "$branch"
if remote_branches | grep -q '^claude/'; then fail tool_branch_not_pushed "pushed a claude/ branch"; else pass tool_branch_not_pushed; fi
check_conventional_commits "main..$branch" "docs"
check_clean_tree
expect pr_base_main "base is $(pr_field "$pr" .base)" test "$(pr_field "$pr" .base)" = main
check_no_draft
check_title "$pr" docs
check_template "$pr" "$(printf 'Why\nWhat changed')"
check_pr_text "$pr"
check_not_merged
check_reported_url "$pr"
