# On the branch of open PR #7, pushed and clean.
make_tasks_repo
seed_gh_state
cd "$REPO"
git switch -q -c priority-sort
perl -pi -e "s/return list.filter\(\(t\) => !t.done\);/return list.filter((t) => !t.done).sort((a, b) => a.id - b.id);/" src/tasks.mjs
commit "fix(list): keep pending tasks in id order"
git push -q -u origin priority-sort 2>/dev/null
oid=$(git rev-parse HEAD)
gh_state ".prs = [{\"number\": 7, \"title\": \"fix(list): keep pending tasks in id order\", \"body\": \"## Symptom\\nTasks listed out of order after an import.\\n\", \"base\": \"main\", \"head\": \"priority-sort\", \"headRefOid\": \"$oid\", \"draft\": false, \"state\": \"OPEN\"}] | .next_pr = 8 | .checks_state = \"pending\""
