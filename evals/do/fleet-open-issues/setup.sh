# On main, with three open issues. The run stops at the first owner it starts: a subagent or a worktree.
source "$EVAL_HERE/do/lib.sh"
make_tasks_repo
seed_gh_state
gh_state '.issues["21"] = {"title": "`tasks done` with an unknown id prints a stack trace", "body": "`tasks done 99` on an empty list prints a Node stack trace. It should print `no task with id 99` and exit 1."}
  | .issues["22"] = {"title": "Add `tasks count`", "body": "Print how many tasks are still open, as a bare number."}
  | .issues["23"] = {"title": "`tasks list` looks cramped", "body": "The list output is hard to scan with more than a few tasks. Show me a few directions before we pick one."}'
do_hooks '^(Agent|Task|EnterWorktree) |^Bash .*git worktree add'
