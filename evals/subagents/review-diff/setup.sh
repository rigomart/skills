# The tasks repo on overdue-tasks, one commit ahead of main: due dates and an
# `overdue` command. overdueTasks keeps done tasks instead of open ones, and
# `add --due` drops the date (splice(i, 1)[1] is always undefined). The tests pass.
make_tasks_repo
seed_gh_state
cd "$REPO"
git checkout -q -b overdue-tasks
cat > src/tasks.mjs <<'EOF'
export function addTask(list, title, { due } = {}) {
  const id = list.reduce((max, t) => Math.max(max, t.id), 0) + 1;
  const task = { id, title, done: false, ...(due && { due }) };
  return { list: [...list, task], task };
}

export function completeTask(list, id) {
  if (!list.some((t) => t.id === id)) throw new Error(`no task with id ${id}`);
  return list.map((t) => (t.id === id ? { ...t, done: true } : t));
}

export function listTasks(list) {
  return list.filter((t) => !t.done);
}

// Open tasks due before `today` (YYYY-MM-DD), oldest first.
export function overdueTasks(list, today) {
  return list.filter((t) => t.due && t.due < today && t.done).sort((a, b) => a.due.localeCompare(b.due));
}
EOF
cat > src/cli.mjs <<'EOF'
#!/usr/bin/env node
import { addTask, completeTask, listTasks, overdueTasks } from "./tasks.mjs";
import { load, save } from "./store.mjs";

const [command, ...args] = process.argv.slice(2);
const list = load();

if (command === "add") {
  const i = args.indexOf("--due");
  const due = i === -1 ? undefined : args.splice(i, 1)[1];
  const { list: next, task } = addTask(list, args.join(" "), { due });
  save(next);
  console.log(`added #${task.id} ${task.title}`);
} else if (command === "done") {
  save(completeTask(list, Number(args[0])));
  console.log(`done #${args[0]}`);
} else if (command === "list") {
  for (const t of listTasks(list)) console.log(`#${t.id} ${t.title}`);
} else if (command === "overdue") {
  const today = new Date().toISOString().slice(0, 10);
  for (const t of overdueTasks(list, today)) console.log(`#${t.id} ${t.title} (due ${t.due})`);
} else {
  console.error("usage: tasks add [--due YYYY-MM-DD] <title> | done <id> | list | overdue");
  process.exit(2);
}
EOF
cat >> test/tasks.test.mjs <<'EOF'

test("overdueTasks skips tasks without a due date", () => {
  const { list } = addTask([], "someday");
  assert.deepEqual(overdueTasks(list, "2026-01-01"), []);
});
EOF
perl -pi -e 's/^import \{ addTask, completeTask, listTasks \} from/import { addTask, completeTask, listTasks, overdueTasks } from/' test/tasks.test.mjs
perl -0pi -e 's/tasks done 1\n/tasks done 1\ntasks add --due 2026-12-01 Renew the domain\ntasks overdue\n/' README.md
commit "feat: add due dates and an overdue command"
