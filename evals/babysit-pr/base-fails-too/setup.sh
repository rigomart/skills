# main is red: a test expects an error message src/tasks.mjs does not give. PR #7 branched
# from it, is up to date, and touches only src/cli.mjs, so its test check fails the same way.
source "$EVAL_HERE/$EVAL_SKILL/lib.sh"
make_repo
break_main_test
git switch -q -c empty-list-hint
empty_hint_change
commit "feat(cli): say so when nothing is pending"
git push -q -u origin empty-list-hint 2>/dev/null
open_pr "feat(cli): say so when nothing is pending" "$(printf '## Why\nAn empty list printed nothing, so it looked broken.\n\n## What changed\n`tasks list` prints `nothing to do` when no task is pending.\n')"
