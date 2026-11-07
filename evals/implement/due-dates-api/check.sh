source "$EVAL_HERE/implement/lib.sh"
# The costly choice: how a due date is stored and passed, which the bot and the dashboard build on.
costly='addTask|signature|\bAPI\b|callers?|consumers?|\bbot\b|dashboard|data model|schema|stor(e|ed|age|ing)|tasks\.json|time ?zones?|calendar|instant|date-only|date only|timestamp|clock|stored as|saved as|\bfield\b'
check_skill_loaded
check_asked_costly "$costly"
check_no_needless_questions "$costly"
check_ci_ran
check_scope '^(src/[^/]+\.mjs|test/[^/]+\.m?js|README\.md)$'
check_evidence
check_report_shape
