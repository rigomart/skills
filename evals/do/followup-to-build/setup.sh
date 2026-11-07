# On main: a question first, then a follow-up asking for a change. The run stops at the first edit to src/ or test/, or the first subagent.
source "$EVAL_HERE/do/lib.sh"
make_tasks_repo
seed_gh_state
do_hooks '^(Agent|Task) |^(Edit|Write|MultiEdit|NotebookEdit) .*"file_path":"[^"]*/(src|test)/' \
  'New message from the user: Make it print `no task with id <n>` and exit with code 1, without the stack trace.'
