# Open PR #7 with a sound change; its CI passes once it runs.
source "$EVAL_HERE/$EVAL_SKILL/lib.sh"
make_repo
git switch -q -c empty-list-hint
empty_hint_change
commit "feat(cli): say so when nothing is pending"
git push -q -u origin empty-list-hint 2>/dev/null
open_pr "feat(cli): say so when nothing is pending" "$(printf '## Why\nAn empty list printed nothing, so it looked broken.\n\n## What changed\n`tasks list` prints `nothing to do` when no task is pending.\n')"
