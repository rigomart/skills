# On main with an uncommitted feature (task priorities) and a stray .DS_Store.
make_tasks_repo
seed_gh_state
cd "$REPO"
cat > src/tasks.mjs <<'EOF'
const PRIORITIES = ["high", "normal", "low"];

export function addTask(list, title, { priority = "normal" } = {}) {
  if (!PRIORITIES.includes(priority)) throw new Error(`priority must be one of ${PRIORITIES.join(", ")}`);
  const id = list.reduce((max, t) => Math.max(max, t.id), 0) + 1;
  const task = { id, title, done: false, priority };
  return { list: [...list, task], task };
}

export function completeTask(list, id) {
  if (!list.some((t) => t.id === id)) throw new Error(`no task with id ${id}`);
  return list.map((t) => (t.id === id ? { ...t, done: true } : t));
}

const rank = (t) => PRIORITIES.indexOf(t.priority ?? "normal");

export function listTasks(list) {
  return list.filter((t) => !t.done).sort((a, b) => rank(a) - rank(b) || a.id - b.id);
}
EOF
perl -0pi -e 's/  const \{ list: next, task \} = addTask\(list, args.join\(" "\)\);/  const i = args.indexOf("--priority");\n  const priority = i === -1 ? undefined : args.splice(i, 2)[1];\n  const { list: next, task } = addTask(list, args.join(" "), { priority });/' src/cli.mjs
perl -pi -e 's/^  for \(const t of listTasks\(list\)\) console.log\(`#\$\{t.id\} \$\{t.title\}`\);/  for (const t of listTasks(list)) console.log(`#\${t.id} [\${t.priority ?? "normal"}] \${t.title}`);/' src/cli.mjs
perl -pi -e 's/usage: tasks add <title>/usage: tasks add [--priority high|normal|low] <title>/' src/cli.mjs
cat >> test/tasks.test.mjs <<'EOF'

test("high priority tasks list first", () => {
  let { list } = addTask([], "low one", { priority: "low" });
  ({ list } = addTask(list, "urgent", { priority: "high" }));
  ({ list } = addTask(list, "plain"));
  assert.deepEqual(listTasks(list).map((t) => t.title), ["urgent", "plain", "low one"]);
});

test("unknown priorities are rejected", () => {
  assert.throws(() => addTask([], "x", { priority: "urgent" }), /priority must be one of/);
});
EOF
perl -0pi -e 's/tasks add Write the release notes\n/tasks add Write the release notes\ntasks add --priority high Fix the login bug\n/' README.md
printf '\0\0\0\1Bud1' > .DS_Store
