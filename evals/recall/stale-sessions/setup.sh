# Three past chats that live state has moved past:
# - a chat from 3 days ago left PR #4 (list --json) open, waiting on review; it merged 2 days ago.
# - a chat from 3 days ago left PR #5 (due dates) with a failing test; a fix pushed
#   yesterday made its checks pass.
# - a chat from 2 days ago left the undo command uncommitted on undo-done; it was
#   committed, pushed and opened as PR #7, checks passing.
source "$EVAL_HERE/recall/lib.sh"
recall_repo
cd "$REPO"
gh_json '.issues = {
  "2": {title: "tasks list should print JSON for scripts", body: "A `--json` flag for `tasks list`."},
  "3": {title: "Tasks need due dates", body: "`tasks add Pay rent --due 2026-12-01`."}}'

at 3; git switch -q -c list-json; change_list_json; commit_push "feat(list): add --json output"
git switch -q main; git switch -q -c due-dates; change_due_dates; commit_push "feat(add): accept a due date"
at 2; git switch -q main; git merge -q --squash list-json 2>/dev/null; commit "feat(list): add --json output (#4)"
git push -q origin main 2>/dev/null; git push -q origin --delete list-json 2>/dev/null; git branch -q -D list-json
pr 4 list-json MERGED "feat(list): add --json output" "Closes #2."
gh_json '.issues["2"].state = "CLOSED"'
at 1; git switch -q due-dates; git checkout -q main -- src/tasks.mjs test/tasks.test.mjs; change_due_dates us
commit_push "fix(add): read US-style due dates too"
pr 5 due-dates OPEN "feat(add): accept a due date" "Part of #3. Tasks get a \`due\` date, read by parseDue."

at 1; git switch -q main; git switch -q -c undo-done; change_undo; commit_push "feat(cli): add tasks undo"
pr 7 undo-done OPEN "feat(cli): add tasks undo" "\`tasks undo <id>\` marks a done task open again."
git switch -q main

recall_isolate
claude_session 3 41a7c3d2-list-json <<'CHAT'
U Add a --json flag to tasks list, issue #2.
A Opened PR #4 (feat(list): add --json output). lint and test pass. It's waiting on review.
U Thanks, I'll ask for a review.
CHAT
codex_session 3 2026-11-04T16-20-due-dates <<'CHAT'
U Due dates, issue #3.
A Opened PR #5. The test for 12/01/2026 fails: parseDue only reads 2026-12-01.
U Leave it red for now, I'll decide which date formats we take.
CHAT
claude_session 2 9c55e0b4-undo <<'CHAT'
U Start a tasks undo command.
A On branch undo-done, undoTask and the undo command are written in src/tasks.mjs and src/cli.mjs, not committed or pushed yet.
U OK, stop there for today.
CHAT
snapshot
