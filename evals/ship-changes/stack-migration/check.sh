check_skill_loaded
n=$(new_prs | wc -l | tr -d ' ')
if [ "$n" = 2 ]; then pass two_prs; else fail two_prs "$n PRs opened"; fi
bottom=$(new_prs | jq -r 'select(.base=="main") | .number' | head -1)
[ -n "$bottom" ] || { fail bottom_targets_main "no PR targets main"; exit 0; }
pass bottom_targets_main
bhead=$(pr_field "$bottom" .head)
top=$(new_prs | jq -r --arg b "$bhead" 'select(.base==$b) | .number' | head -1)
[ -n "$top" ] || { fail top_targets_bottom "no PR targets $bhead"; exit 0; }
pass top_targets_bottom
thead=$(pr_field "$top" .head)
expect top_branched_from_bottom "$thead does not contain $bhead" git -C "$REMOTE" merge-base --is-ancestor "$bhead" "$thead"
expect bottom_has_migration "migrations/v2-due-dates.mjs missing at $bhead" git -C "$REMOTE" cat-file -e "$bhead:migrations/v2-due-dates.mjs"
if git -C "$REMOTE" show "$bhead:src/cli.mjs" | grep -q -- '--due'; then fail bottom_excludes_feature "the --due flag is in the bottom PR"; else pass bottom_excludes_feature; fi
expect top_has_feature "--due missing at $thead" sh -c "git -C '$REMOTE' show '$thead:src/cli.mjs' | grep -q -- '--due'"
expect remote_main_unchanged "origin/main moved" test "$(git -C "$REMOTE" rev-list --count main)" = 2
check_conventional_commits "main..$thead" "feat|fix|refactor|chore|build|perf"
check_clean_tree
first() { pr_field "$1" .body | sed '/^[[:space:]]*$/d' | head -1; }
if first "$bottom" | grep -Eq '^Part 1 of 2'; then pass bottom_names_place; else fail bottom_names_place "first line: '$(first "$bottom")'"; fi
if first "$top" | grep -Eq "^Part 2 of 2\. Builds on #$bottom"; then pass top_names_place; else fail top_names_place "first line: '$(first "$top")'"; fi
check_ran ran_lint '(npm (run )?(-s |--silent )?lint|node scripts/lint)'
c=$(bash_cmds | grep -Ec '(npm (run )?(-s |--silent )?test|npm t( |$)|node --test)' || true)
if [ "${c:-0}" -ge 2 ]; then pass ran_tests_per_layer; else fail ran_tests_per_layer "tests ran $c time(s) for two layers"; fi
check_no_draft
check_title "$bottom" "feat|fix|refactor|chore|build|perf"
check_title "$top" "feat"
check_template_by_type "$bottom"
check_template_by_type "$top"
check_pr_text "$bottom"
check_pr_text "$top"
check_not_merged
check_reported_url "$bottom"
check_reported_url "$top"
