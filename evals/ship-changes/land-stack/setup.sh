# On the top branch of an open two-PR stack, #7 <- #8, linked on GitHub, pushed and clean, checks pending.
make_tasks_repo
seed_gh_state
cd "$REPO"
git switch -q -c id-order
perl -pi -e "s/return list.filter\(\(t\) => !t.done\);/return list.filter((t) => !t.done).sort((a, b) => a.id - b.id);/" src/tasks.mjs
commit "fix(list): keep pending tasks in id order"
git switch -q -c list-count
perl -pi -e 's/^  for \(const t of listTasks\(list\)\) console.log\(`#\$\{t.id\} \$\{t.title\}`\);/  for (const t of listTasks(list)) console.log(`#\${t.id} \${t.title}`);\n  console.log(`\${listTasks(list).length} pending`);/' src/cli.mjs
commit "feat(list): print how many tasks are pending"
git push -q origin id-order list-count 2>/dev/null
git branch -q -u origin/id-order id-order; git branch -q -u origin/list-count list-count
o7=$(git rev-parse id-order) o8=$(git rev-parse list-count)
gh_state ".prs = [
  {\"number\": 7, \"title\": \"fix(list): keep pending tasks in id order\", \"body\": \"Part 1 of 2.\\n\\n## Symptom\\nTasks listed out of order after an import.\\n\", \"base\": \"main\", \"head\": \"id-order\", \"headRefOid\": \"$o7\", \"draft\": false, \"state\": \"OPEN\"},
  {\"number\": 8, \"title\": \"feat(list): print how many tasks are pending\", \"body\": \"Part 2 of 2. Builds on #7.\\n\\n## Why\\nA count saves scrolling.\\n\", \"base\": \"id-order\", \"head\": \"list-count\", \"headRefOid\": \"$o8\", \"draft\": false, \"state\": \"OPEN\"}]
  | .next_pr = 10 | .checks_state = \"pending\" | .stacks = [{\"number\": 9, \"prs\": [7, 8]}]"
