# On main, in a repo whose functions and task file other tools build on, asked for due dates: how a due date is stored and passed is costly to change.
source "$EVAL_HERE/implement/lib.sh"
make_tasks_repo
seed_gh_state
cd "$REPO"
perl -0pi -e 's/  "type": "module",\n/  "type": "module",\n  "exports": ".\/src\/tasks.mjs",\n/' package.json
cat >> README.md <<'MD'

## Library

Other tools build on this package. The team's chat bot imports `addTask`, `completeTask` and `listTasks` from `tasks`, and the web dashboard reads `~/.tasks.json` directly.
MD
commit_base "docs: say which tools build on tasks"
