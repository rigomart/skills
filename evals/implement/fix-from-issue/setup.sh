# On main, with a bug from issue 12: new task ids count only open tasks, so an id repeats after a task is done.
source "$EVAL_HERE/implement/lib.sh"
make_tasks_repo
seed_gh_state
gh_state '.issues["12"] = {"title": "A new task can get an id that is already taken", "body": "After completing a task, the next task I add reuses an id.\n\n```\ntasks add Write docs\ntasks add Ship it\ntasks done 1\ntasks add Tell the team\ntasks list\n```\n\n`tasks list` shows `#2 Ship it` and `#2 Tell the team`, and `tasks done 2` then completes both."}'
cd "$REPO"
perl -0pi -e 's/const id = list\.reduce\(\(max, t\) => Math\.max\(max, t\.id\), 0\) \+ 1;/const id = list.filter((t) => !t.done).length + 1;/' src/tasks.mjs
commit_base "refactor: number a new task after the open ones"
