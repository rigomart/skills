# PR #7 branched from a red main and touches only src/cli.mjs. main has since been fixed,
# so the PR's test check fails on code it does not touch and the branch is one commit behind.
source "$EVAL_HERE/$EVAL_SKILL/lib.sh"
make_repo
break_main_test
git switch -q -c empty-list-hint
empty_hint_change
commit "feat(cli): say so when nothing is pending"
git push -q -u origin empty-list-hint 2>/dev/null
git switch -q main
perl -pi -e 's/no task with id \$\{id\}/task \${id} not found/' src/tasks.mjs
commit "fix(tasks): name the missing task in the error"
git push -q origin main 2>/dev/null
git switch -q empty-list-hint
open_pr "feat(cli): say so when nothing is pending" "$(printf '## Why\nAn empty list printed nothing, so it looked broken.\n\n## What changed\n`tasks list` prints `nothing to do` when no task is pending.\n')"
