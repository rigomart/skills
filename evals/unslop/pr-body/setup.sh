# A fix's PR body, drafted with AI tells, waiting in the repo for an edit before the PR opens.
make_tasks_repo
seed_gh_state
cp "$(dirname "${BASH_SOURCE[0]}")/source.md" "$REPO/pr-body.md"
