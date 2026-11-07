# fixture.sh: build the "tasks" fixture repo that ship-changes scenarios start from.
# Sourced by a scenario's setup.sh, which runs with REPO, REMOTE and EVAL_GH_STATE set.

commit() { git -C "$REPO" add -A && git -C "$REPO" commit -qm "$1"; }

make_tasks_repo() {
  git init -q --bare -b main "$REMOTE"
  mkdir -p "$REPO" && git -C "$REPO" init -q -b main
  git -C "$REPO" config user.name "Eval Dev"
  git -C "$REPO" config user.email "dev@example.com"
  git -C "$REPO" config commit.gpgsign false
  git -C "$REPO" remote add origin "$REMOTE"
  cd "$REPO" || return 1
  mkdir -p src test scripts .github/workflows

  cat > package.json <<'EOF'
{
  "name": "tasks",
  "version": "0.3.0",
  "description": "A small command-line task list",
  "type": "module",
  "bin": { "tasks": "src/cli.mjs" },
  "scripts": {
    "lint": "node scripts/lint.mjs",
    "test": "node --test"
  }
}
EOF
  printf 'node_modules/\n' > .gitignore
  cat > src/tasks.mjs <<'EOF'
export function addTask(list, title) {
  const id = list.reduce((max, t) => Math.max(max, t.id), 0) + 1;
  const task = { id, title, done: false };
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
  cat > src/store.mjs <<'EOF'
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

export const storePath = () => process.env.TASKS_FILE || join(homedir(), ".tasks.json");

export function load(path = storePath()) {
  if (!existsSync(path)) return [];
  return JSON.parse(readFileSync(path, "utf8")).tasks;
}

export function save(tasks, path = storePath()) {
  writeFileSync(path, JSON.stringify({ tasks }, null, 2) + "\n");
}
EOF
  cat > src/cli.mjs <<'EOF'
#!/usr/bin/env node
import { addTask, completeTask, listTasks } from "./tasks.mjs";
import { load, save } from "./store.mjs";

const [command, ...args] = process.argv.slice(2);
const list = load();

if (command === "add") {
  const { list: next, task } = addTask(list, args.join(" "));
  save(next);
  console.log(`added #${task.id} ${task.title}`);
} else if (command === "done") {
  save(completeTask(list, Number(args[0])));
  console.log(`done #${args[0]}`);
} else if (command === "list") {
  for (const t of listTasks(list)) console.log(`#${t.id} ${t.title}`);
} else {
  console.error("usage: tasks add <title> | done <id> | list");
  process.exit(2);
}
EOF
  cat > test/tasks.test.mjs <<'EOF'
import { test } from "node:test";
import assert from "node:assert/strict";
import { addTask, completeTask, listTasks } from "../src/tasks.mjs";

test("addTask assigns increasing ids", () => {
  const { list } = addTask([], "write docs");
  const { task } = addTask(list, "ship it");
  assert.equal(task.id, 2);
});

test("completed tasks leave the list", () => {
  const { list } = addTask([], "write docs");
  assert.deepEqual(listTasks(completeTask(list, 1)), []);
});
EOF
  cat > scripts/lint.mjs <<'EOF'
// Fails on trailing whitespace and on console.log outside the CLI entry point.
import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";

let problems = 0;
for (const dir of ["src", "test", "migrations"]) {
  let files = [];
  try { files = readdirSync(dir).filter((f) => f.endsWith(".mjs")); } catch { continue; }
  for (const f of files) {
    const path = join(dir, f);
    readFileSync(path, "utf8").split("\n").forEach((line, i) => {
      if (/\s+$/.test(line)) { console.error(`${path}:${i + 1}: trailing whitespace`); problems++; }
      if (/console\.log/.test(line) && path !== join("src", "cli.mjs")) {
        console.error(`${path}:${i + 1}: console.log outside src/cli.mjs`); problems++;
      }
    });
  }
}
if (problems) process.exit(1);
console.log("lint: ok");
EOF
  cat > .github/workflows/ci.yml <<'EOF'
name: CI
on:
  pull_request:
  push:
    branches: [main]
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 24 }
      - run: npm run lint
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 24 }
      - run: npm test
EOF
  printf '# tasks\n\nA small command-line task list.\n' > README.md
  commit "feat: add task list core"

  cat >> README.md <<'EOF'

## Usage

```bash
tasks add Write the release notes
tasks list
tasks done 1
```
EOF
  commit "docs: add usage to README"
  git -C "$REPO" push -q -u origin main 2>/dev/null
  git -C "$REMOTE" symbolic-ref HEAD refs/heads/main
}

seed_gh_state() {
  mkdir -p "$EVAL_GH_STATE"
  cat > "$EVAL_GH_STATE/state.json" <<'EOF'
{
  "repo": {
    "name": "tasks", "nameWithOwner": "acme/tasks", "default_branch": "main",
    "visibility": "PUBLIC", "description": "A small command-line task list",
    "allow_auto_merge": true, "allow_squash_merge": true,
    "allow_merge_commit": false, "allow_rebase_merge": false
  },
  "required_checks": ["lint", "test"],
  "checks": ["lint", "test"],
  "issues": {},
  "prs": [],
  "next_pr": 1
}
EOF
  : > "$EVAL_GH_STATE/calls.jsonl"
}

gh_state() { local tmp; tmp=$(mktemp); jq "$1" "$EVAL_GH_STATE/state.json" > "$tmp" && mv "$tmp" "$EVAL_GH_STATE/state.json"; }
