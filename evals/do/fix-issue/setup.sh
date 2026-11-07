# On main, with issue #3: the usage line misspells "done". A one-line copy fix, so the build playbook skips review.
source "$EVAL_HERE/do/lib.sh"
make_tasks_repo
seed_gh_state
gh_state '.issues["3"] = {"title": "The usage message misspells done", "body": "Running `tasks` with no command prints\n\n```\nusage: tasks add <title> | dnoe <id> | list\n```\n\nIt should say `done`."}'
perl -pi -e 's/\| done <id>/| dnoe <id>/' "$REPO/src/cli.mjs"
commit_pushed "refactor: tidy the usage line"
do_hooks
