# A user guide of over 400 words, drafted with AI tells, committed and waiting for an edit before it is published.
make_tasks_repo
seed_gh_state
mkdir -p "$REPO/docs"
cp "$(dirname "${BASH_SOURCE[0]}")/source.md" "$REPO/docs/guide.md"
commit "docs: add a getting started guide"
git -C "$REPO" push -q origin main
