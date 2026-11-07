# On a descriptive local branch named for issue 42, with an uncommitted fix.
make_tasks_repo
seed_gh_state
gh_state '.issues["42"] = {"title": "Adding a task with an empty title creates a blank task", "body": "`tasks add` with no title, or only spaces, saves a task with an empty title. It shows up in `tasks list` as `#3 ` and can only be removed with `tasks done`."}'
cd "$REPO"
git switch -q -c fix-empty-title-42
perl -0pi -e 's/export function addTask\(list, title\) \{\n/export function addTask(list, title) {\n  title = title.trim();\n  if (!title) throw new Error("a task needs a title");\n/' src/tasks.mjs
perl -0pi -e 's/if \(command === "add"\) \{\n  const \{ list: next, task \} = addTask\(list, args.join\(" "\)\);/if (command === "add") {\n  let added;\n  try {\n    added = addTask(list, args.join(" "));\n  } catch (err) {\n    console.error(err.message);\n    process.exit(1);\n  }\n  const { list: next, task } = added;/' src/cli.mjs
cat >> test/tasks.test.mjs <<'EOF'

test("empty and blank titles are rejected", () => {
  assert.throws(() => addTask([], ""), /needs a title/);
  assert.throws(() => addTask([], "   "), /needs a title/);
});
EOF
