# A README whose storage section, between Usage and Exit codes, was drafted with AI tells.
# Exit codes has an em dash of its own, outside the section the user names.
make_tasks_repo
seed_gh_state
here=$(dirname "${BASH_SOURCE[0]}")
{ echo; cat "$here/section.md"; cat "$here/after.md"; } >> "$REPO/README.md"
commit "docs: describe storage and exit codes"
git -C "$REPO" push -q origin main
