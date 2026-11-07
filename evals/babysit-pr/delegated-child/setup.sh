# Open PR #7 whose diff leaves a debug console.log in src/tasks.mjs, so lint fails.
# CI has already finished: the parent saw the failure and delegated the fix.
source "$EVAL_HERE/$EVAL_SKILL/lib.sh"
make_repo
git switch -q -c pending-count
pending_count_change '!t.done' debug
commit "feat(list): show how many tasks are pending"
git push -q -u origin pending-count 2>/dev/null
open_pr "feat(list): show how many tasks are pending" "$(printf '## Why\nUsers want to know how much is left.\n\n## What changed\n`tasks list` ends with how many tasks are pending, from a new `countPending`.\n')" 0
