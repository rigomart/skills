source "$EVAL_HERE/implement/lib.sh"
check_skill_loaded
check_ran read_issue 'gh issue view (#?12|.*/issues/12)'
check_before_first
check_repro
if run_node_tests "$1/oracle.test.mjs"; then pass fixed; else fail fixed "ids still repeat after a task is done"; fi
check_ci_ran
check_scope '^(src/tasks\.mjs|test/[^/]+\.m?js)$'
check_evidence
check_no_needless_questions
check_report_shape
