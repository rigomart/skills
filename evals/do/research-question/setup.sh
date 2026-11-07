# On main: a "what's the best X" question. The run stops at the first web call or subagent, so it needs no web.
source "$EVAL_HERE/do/lib.sh"
make_tasks_repo
seed_gh_state
do_hooks '^(Agent|Task|WebSearch|WebFetch) '
