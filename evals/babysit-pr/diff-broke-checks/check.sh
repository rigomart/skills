source "$EVAL_HERE/$EVAL_SKILL/lib.sh"
check_skill_loaded
check_read_failed_log
check_ran ran_lint_locally '(npm (run )?(-s |--silent )?lint|node scripts/lint)'
check_ran ran_tests_locally '(npm (run )?(-s |--silent )?test|npm t( |$)|node --test)'
expect lint_fixed "lint fails on the PR head" head_passes "node scripts/lint.mjs"
expect tests_fixed "tests fail on the PR head" head_passes "node --test"
# The fix is in countPending: the PR's test for it still asserts the same thing.
expect kept_test "the PR's test changed" sh -c "git -C '$REMOTE' diff --quiet '$(start_head)' '$(remote_head)' -- test/"
check_one_push
check_no_force_push
check_reruns
check_no_own_wait
check_waited_after_change
check_not_merged
check_handed_back_ready
