# On branch due-dates: one commit, uncommitted edits and two new untracked files,
# with bad and good comments seeded across all three. check.sh lists them.
source "$EVAL_HERE/comments/lib.sh"
make_comments_repo
git checkout -q -b due-dates

cat > src/store.mjs <<'EOF'
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

export const storePath = () => process.env.TASKS_FILE || join(homedir(), ".tasks.json");

export function load(path = storePath()) {
  if (!existsSync(path)) return [];
  // Notepad saves UTF-8 files with a BOM, which JSON.parse rejects.
  const text = readFileSync(path, "utf8").replace(/^﻿/, "");
  // parse the file and return its tasks
  return JSON.parse(text).tasks;
}

export function save(tasks, path = storePath()) {
  writeFileSync(path, JSON.stringify({ tasks }, null, 2) + "\n");
}
EOF
commit "fix: read task files saved with a BOM"

perl -0pi -e 's/export function addTask\(list, title\) \{/export function addTask(list, title, { due } = {}) {/; s/  const task = \{ id, title, done: false \};/  \/\/ now stores the due date too\n  const task = { id, title, done: false, ...(due && { due }) };/' src/tasks.mjs
cat >> src/tasks.mjs <<'EOF'

// ---------------------------------------------------------------------------
// Due dates
// ---------------------------------------------------------------------------

/**
 * Returns the open tasks due before `date`, soonest first.
 * Tasks without a due date are left out.
 * @param {Array<object>} list
 * @param {Date} date
 * @returns {Array<object>}
 */
export function dueBefore(list, date) {
  return listTasks(list)
    .filter((t) => t.due && new Date(t.due) < date)
    .sort((a, b) => new Date(a.due) - new Date(b.due));
}
EOF

cat > src/dates.mjs <<'EOF'
// TODO: accept relative dates like "tomorrow"
export function parseDue(text) {
  const date = new Date(`${text}T00:00:00Z`);
  if (Number.isNaN(date.getTime())) throw new Error(`invalid due date ${text}, use YYYY-MM-DD`);
  return date;
}
EOF

cat > test/due.test.mjs <<'EOF'
import { test } from "node:test";
import assert from "node:assert/strict";
import { mkdtempSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { addTask, dueBefore } from "../src/tasks.mjs";
import { parseDue } from "../src/dates.mjs";
import { load } from "../src/store.mjs";

test("dueBefore lists the soonest task first", () => {
  let { list } = addTask([], "later", { due: "2026-03-01" });
  ({ list } = addTask(list, "sooner", { due: "2026-02-01" }));
  ({ list } = addTask(list, "no date"));
  const due = dueBefore(list, parseDue("2026-04-01"));
  assert.deepEqual(due.map((t) => t.title), ["sooner", "later"]);
});

test("load reads a file saved with a BOM", () => {
  const path = join(mkdtempSync(join(tmpdir(), "tasks-")), "tasks.json");
  // lint-ignore-next-line max-len
  const saved = '﻿{"tasks":[{"id":1,"title":"write docs","done":false,"due":"2026-01-02"},{"id":2,"title":"ship it","done":true}]}';
  writeFileSync(path, saved);
  assert.equal(load(path).length, 2);
});
EOF
snapshot_seed
