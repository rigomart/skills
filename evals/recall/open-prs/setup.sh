# Main with three open PRs: #4 adds `list --json` (checks pass), #5 adds due dates
# (its test fails), #6 is a docs draft (checks pass). A branch, undo-done, was
# never pushed, and main has an uncommitted README edit. One past chat, which
# agrees with live state.
source "$EVAL_HERE/recall/lib.sh"
recall_repo
cd "$REPO"
gh_json '.issues = {
  "2": {title: "tasks list should print JSON for scripts", body: "I pipe `tasks list` into jq. A `--json` flag would save parsing the text."},
  "3": {title: "Tasks need due dates", body: "`tasks add Pay rent --due 2026-12-01`, and `list` shows the date."}}'

at 6; git switch -q -c list-json; change_list_json; commit_push "feat(list): add --json output"
pr 4 list-json OPEN "feat(list): add --json output" "Closes #2. \`tasks list --json\` prints the open tasks as JSON."
at 3; git switch -q main; git switch -q -c due-dates; change_due_dates; commit_push "feat(add): accept a due date"
pr 5 due-dates OPEN "feat(add): accept a due date" "Part of #3. Tasks get a \`due\` date, read by parseDue."
at 2; git switch -q main; git switch -q -c docs-store
printf '\n## Where tasks live\n\nTasks are saved in `~/.tasks.json`. Set `TASKS_FILE` to use another file.\n' >> README.md
commit_push "docs: say where tasks are stored"
pr 6 docs-store OPEN "docs: say where tasks are stored" "Documents the store file and TASKS_FILE."
gh_json '(.prs[] | select(.number == 6)).draft = true'
at 1; git switch -q main; git switch -q -c undo-done; change_undo; commit "feat(cli): add tasks undo"
git switch -q main
printf '\n## Install\n\n```bash\nnpm install -g\n' >> README.md

recall_isolate
claude_session 2 0b6c1f52-due-dates <<'CHAT'
U Add due dates to tasks, issue #3. Read the date the user types.
A Opened PR #5 (feat(add): accept a due date). parseDue reads 2026-12-01, but the test for 12/01/2026 fails: it only takes ISO dates. Should it accept US-style dates too?
U Leave it failing for now, I need to decide which formats we support.
A Left PR #5 as it is, with the failing test.
CHAT
snapshot
