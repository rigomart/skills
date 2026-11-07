# On main with a storage migration and a due-date feature that uses it, uncommitted.
make_tasks_repo
seed_gh_state
cd "$REPO"
mkdir -p migrations
cat > migrations/v2-due-dates.mjs <<'EOF'
// Version 2 gives every task a due date field, null when it has none.
export const version = 2;

export function migrate(data) {
  return { version, tasks: data.tasks.map((t) => ({ due: null, ...t })) };
}
EOF
cat > src/store.mjs <<'EOF'
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { migrate, version } from "../migrations/v2-due-dates.mjs";

export const storePath = () => process.env.TASKS_FILE || join(homedir(), ".tasks.json");

export function load(path = storePath()) {
  if (!existsSync(path)) return [];
  let data = JSON.parse(readFileSync(path, "utf8"));
  if ((data.version ?? 1) < version) data = migrate(data);
  return data.tasks;
}

export function save(tasks, path = storePath()) {
  writeFileSync(path, JSON.stringify({ version, tasks }, null, 2) + "\n");
}
EOF
cat > test/store.test.mjs <<'EOF'
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, writeFileSync, readFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { load, save } from "../src/store.mjs";

test("a version 1 file loads with empty due dates", () => {
  const path = join(mkdtempSync(join(tmpdir(), "tasks-")), "tasks.json");
  writeFileSync(path, JSON.stringify({ tasks: [{ id: 1, title: "a", done: false }] }));
  assert.deepEqual(load(path), [{ due: null, id: 1, title: "a", done: false }]);
});

test("save writes the current version", () => {
  const path = join(mkdtempSync(join(tmpdir(), "tasks-")), "tasks.json");
  save([], path);
  assert.equal(JSON.parse(readFileSync(path, "utf8")).version, 2);
});
EOF
cat > src/tasks.mjs <<'EOF'
export function addTask(list, title, { due = null } = {}) {
  if (due !== null && !/^\d{4}-\d{2}-\d{2}$/.test(due)) throw new Error("due must be YYYY-MM-DD");
  const id = list.reduce((max, t) => Math.max(max, t.id), 0) + 1;
  const task = { id, title, done: false, due };
  return { list: [...list, task], task };
}

export function completeTask(list, id) {
  if (!list.some((t) => t.id === id)) throw new Error(`no task with id ${id}`);
  return list.map((t) => (t.id === id ? { ...t, done: true } : t));
}

export function listTasks(list) {
  return list.filter((t) => !t.done);
}
EOF
perl -0pi -e 's/  const \{ list: next, task \} = addTask\(list, args.join\(" "\)\);/  const i = args.indexOf("--due");\n  const due = i === -1 ? null : args.splice(i, 2)[1];\n  const { list: next, task } = addTask(list, args.join(" "), { due });/' src/cli.mjs
perl -pi -e 's/^  for \(const t of listTasks\(list\)\) console.log\(`#\$\{t.id\} \$\{t.title\}`\);/  for (const t of listTasks(list)) console.log(`#\${t.id} \${t.title}\${t.due ? ` (due \${t.due})` : ""}`);/' src/cli.mjs
perl -pi -e 's/usage: tasks add <title>/usage: tasks add [--due YYYY-MM-DD] <title>/' src/cli.mjs
cat >> test/tasks.test.mjs <<'EOF'

test("tasks keep their due date", () => {
  const { task } = addTask([], "file taxes", { due: "2026-04-15" });
  assert.equal(task.due, "2026-04-15");
  assert.throws(() => addTask([], "x", { due: "tomorrow" }), /YYYY-MM-DD/);
});
EOF
perl -0pi -e 's/tasks add Write the release notes\n/tasks add Write the release notes\ntasks add --due 2026-04-15 File taxes\n/' README.md
