# lib.sh: setup and check helpers shared by the glossary scenarios.

# Setup: the tasks repo grown into one that names three concepts inconsistently.
#   A group of tasks: "board" in the CLI, Bucket in the code, "folder" in the README and issues.
#   A finished task: "done" in the CLI, resolved in the code and in one error message.
#   "archive": hiding done tasks (tasks archive) and the export file (tasks export).
# AGENTS.md holds the agent notes; CLAUDE.md only imports it.
make_boards_repo() {
  make_tasks_repo
  seed_gh_state
  cd "$REPO" || return 1
  cat > src/tasks.mjs <<'EOF'
export function addTask(list, title, bucketId = null) {
  const id = list.reduce((max, t) => Math.max(max, t.id), 0) + 1;
  const task = { id, title, bucketId, resolved: false, archived: false };
  return { list: [...list, task], task };
}

export function resolveTask(list, id) {
  const task = list.find((t) => t.id === id);
  if (!task) throw new Error(`no task with id ${id}`);
  if (task.resolved) throw new Error(`task ${id} is already resolved`);
  return list.map((t) => (t.id === id ? { ...t, resolved: true } : t));
}

export function archiveResolved(list) {
  return list.map((t) => (t.resolved ? { ...t, archived: true } : t));
}

export function listTasks(list, bucketId) {
  return list.filter((t) => !t.resolved && !t.archived && (bucketId == null || t.bucketId === bucketId));
}
EOF
  cat > src/buckets.mjs <<'EOF'
export function createBucket(buckets, name) {
  if (buckets.some((b) => b.name === name)) throw new Error(`board ${name} already exists`);
  const id = buckets.reduce((max, b) => Math.max(max, b.id), 0) + 1;
  return [...buckets, { id, name }];
}

export function findBucket(buckets, name) {
  const bucket = buckets.find((b) => b.name === name);
  if (!bucket) throw new Error(`no board named ${name}`);
  return bucket;
}
EOF
  cat > src/store.mjs <<'EOF'
import { readFileSync, writeFileSync, existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

export const storePath = () => process.env.TASKS_FILE || join(homedir(), ".tasks.json");

export function load(path = storePath()) {
  if (!existsSync(path)) return { tasks: [], buckets: [] };
  const data = JSON.parse(readFileSync(path, "utf8"));
  return { tasks: data.tasks ?? [], buckets: data.buckets ?? [] };
}

export function save(state, path = storePath()) {
  writeFileSync(path, JSON.stringify(state, null, 2) + "\n");
}

export function exportArchive(state, file = "tasks-archive.json") {
  writeFileSync(file, JSON.stringify({ exportedAt: new Date().toISOString(), ...state }, null, 2) + "\n");
  return file;
}
EOF
  cat > src/cli.mjs <<'EOF'
#!/usr/bin/env node
import { addTask, resolveTask, archiveResolved, listTasks } from "./tasks.mjs";
import { createBucket, findBucket } from "./buckets.mjs";
import { load, save, exportArchive } from "./store.mjs";

const [command, ...args] = process.argv.slice(2);
const state = load();
const flag = (name) => { const i = args.indexOf(name); return i < 0 ? null : args.splice(i, 2)[1]; };

if (command === "add") {
  const board = flag("--board");
  const bucketId = board ? findBucket(state.buckets, board).id : null;
  const { list, task } = addTask(state.tasks, args.join(" "), bucketId);
  save({ ...state, tasks: list });
  console.log(`added #${task.id} ${task.title}${board ? ` to board ${board}` : ""}`);
} else if (command === "done") {
  save({ ...state, tasks: resolveTask(state.tasks, Number(args[0])) });
  console.log(`done #${args[0]}`);
} else if (command === "list") {
  const board = flag("--board");
  const bucketId = board ? findBucket(state.buckets, board).id : undefined;
  for (const t of listTasks(state.tasks, bucketId)) console.log(`#${t.id} ${t.title}`);
} else if (command === "board" && args[0] === "add") {
  save({ ...state, buckets: createBucket(state.buckets, args[1]) });
  console.log(`added board ${args[1]}`);
} else if (command === "archive") {
  const tasks = archiveResolved(state.tasks);
  save({ ...state, tasks });
  console.log(`archived ${tasks.filter((t) => t.archived).length} done tasks`);
} else if (command === "export") {
  console.log(`wrote archive to ${exportArchive(state)}`);
} else {
  console.error("usage: tasks add <title> [--board <name>] | done <id> | list [--board <name>] | board add <name> | archive | export");
  process.exit(2);
}
EOF
  cat > test/tasks.test.mjs <<'EOF'
import { test } from "node:test";
import assert from "node:assert/strict";
import { addTask, resolveTask, archiveResolved, listTasks } from "../src/tasks.mjs";
import { createBucket } from "../src/buckets.mjs";

test("addTask assigns increasing ids", () => {
  const { list } = addTask([], "write docs");
  const { task } = addTask(list, "ship it");
  assert.equal(task.id, 2);
});

test("resolved tasks leave the list", () => {
  const { list } = addTask([], "write docs");
  assert.deepEqual(listTasks(resolveTask(list, 1)), []);
});

test("archiving keeps open tasks", () => {
  const { list } = addTask([], "write docs");
  assert.equal(archiveResolved(list)[0].archived, false);
});

test("bucket names are unique", () => {
  assert.throws(() => createBucket(createBucket([], "Home"), "Home"));
});
EOF
  cat > README.md <<'EOF'
# tasks

A small command-line task list.

## Usage

```bash
tasks add Write the release notes
tasks list
tasks done 1
```

## Folders

Group tasks into folders. Create a folder, then add tasks to it and list just that folder:

```bash
tasks board add Home
tasks add Fix the sink --board Home
tasks list --board Home
```

A task with no folder shows up in the plain `tasks list`.

## Cleaning up

`tasks archive` moves every resolved task out of your list. They stay in the task file, so nothing is lost.

`tasks export` writes the archive, a snapshot of every task and folder, to `tasks-archive.json` in the current directory. Keep it as a backup or move it to another machine.
EOF
  cat > AGENTS.md <<'EOF'
# Agent notes

- Run `npm test` and `npm run lint` before committing.
- Commit messages follow Conventional Commits.
EOF
  printf '@AGENTS.md\n' > CLAUDE.md
  commit "feat: boards, archive and export"
  git push -q origin main 2>/dev/null
  gh_state '.issues = {
    "4": {"title": "Folder names should be case-insensitive", "body": "`tasks list --board home` fails when the folder is called Home.", "labels": ["bug"]},
    "5": {"title": "Deleting a bucket with tasks in it", "body": "There is no way to remove a bucket. What should happen to its tasks?", "labels": ["enhancement"]},
    "6": {"title": "Show resolved tasks with list --all", "body": "I want to see what I finished this week.", "labels": ["enhancement"]},
    "7": {"title": "Import an archive on a new machine", "body": "`tasks export` writes the archive, but nothing reads it back.", "labels": ["enhancement"]}
  }'
}

# Setup: the glossary settled for that repo, wired into AGENTS.md.
add_settled_glossary() {
  cat > "$REPO/GLOSSARY.md" <<'EOF'
# tasks

A command-line task list for one person, kept in a single task file.

## Language

**Task**:
One thing to do, with a title. It is open until it is Done.
_Avoid_: item, todo

**Board**:
A named group of Tasks. A Task belongs to at most one Board.
_Avoid_: folder, bucket, list
_Code_: `Bucket`

**Done**:
The state of a Task the user has finished. A Done Task leaves the list.
_Avoid_: resolved, completed, closed
_Code_: `resolved`

**Archive**:
To hide every Done Task from the task file's views for good. Archived Tasks are kept, not deleted.
_Avoid_: clean up

**Export**:
A snapshot of every Task and Board, written to a file the user keeps as a backup.
_Avoid_: archive, backup file

## Relationships

- A **Board** holds many **Tasks**; a **Task** belongs to at most one **Board**
- Only a **Done** **Task** can be **Archived**
EOF
  cat >> "$REPO/AGENTS.md" <<'EOF'
- Use the terms in `GLOSSARY.md` for the concepts it defines, in conversation, code, issues, commits and UI copy. When a concept you need is missing, or a term seems to mean two things, say so instead of inventing a synonym.
EOF
  commit "docs: add a glossary"
  git push -q origin main 2>/dev/null
}

# Setup: install the follow-up hook. The first time the agent stops, the
# message comes back as the user's next one ("Stop hook feedback: <text>").
followup_hook() {
  mkdir -p "$REPO/.claude/hooks"
  cp "$EVAL_HERE/glossary/hooks/followup.sh" "$REPO/.claude/hooks/"
  printf '%s' "$1" > "$REPO/.claude/eval-followup"
  cat > "$REPO/.claude/settings.json" <<'EOF'
{ "hooks": { "Stop": [{ "hooks": [{ "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/followup.sh" }] }] } }
EOF
}

# GLOSSARY.md parsed into one JSON line per block:
#   {kind: "entry", term, def, avoid, code} for each **Term** outside Relationships and Flagged ambiguities,
#     up to the next entry or heading,
#   {kind: "flagged", text} for each bullet under a heading about ambiguities or open questions.
# def is the entry's text without its _Avoid_ and _Code_ lines.
glossary_blocks() {
  perl -CSD -e '
    use strict; my ($sec, $cur, @out) = ("");
    sub esc { my $s = shift // ""; $s =~ s/\\/\\\\/g; $s =~ s/"/\\"/g; $s =~ s/\t/ /g; $s =~ s/\n/ /g; $s =~ s/^\s+|\s+$//g; "\"$s\"" }
    sub flush { return unless $cur; if ($cur->{kind} eq "entry") {
        push @out, sprintf(q({"kind":"entry","term":%s,"def":%s,"avoid":%s,"code":%s}), map { esc($cur->{$_}) } qw(term def avoid code));
      } else { push @out, sprintf(q({"kind":"flagged","text":%s}), esc($cur->{text})) } undef $cur }
    while (my $l = <>) { chomp $l;
      if ($l =~ /^(#{1,6})\s+(.*)/) { my ($h, $t) = ($1, $2); flush(); $sec = lc $t if length($h) == 2; next }
      next if $l =~ /^\s*$/;
      next if $sec =~ /relationship/;
      if ($sec =~ /ambigu|open|flag|unresolved|question/) {
        if ($l =~ /^\s*[-*]\s+(.*)/) { flush(); $cur = {kind => "flagged", text => $1} } elsif ($cur) { $cur->{text} .= " $l" }
        next }
      if ($l =~ /^\s*(?:[-*]\s+)?\*\*([^*]+?)\*\*\s*[:\x{2014}-]?\s*(.*)$/) { flush(); $cur = {kind => "entry", term => $1, def => $2, avoid => "", code => ""}; $cur->{term} =~ s/:$//; next }
      next unless $cur;
      if ($l =~ /^\s*[-*]?\s*_?Avoid_?\s*:?_?\s*:?\s*(.*)/i) { $cur->{avoid} .= " $1" }
      elsif ($l =~ /^\s*[-*]?\s*_?Code_?\s*:?_?\s*:?\s*(.*)/i) { $cur->{code} .= " $1" }
      else { $cur->{def} .= " $l" } }
    flush(); print "$_\n" for @out' "$REPO/GLOSSARY.md"
}

check_glossary_written() {
  if [ -f "$REPO/GLOSSARY.md" ] && [ -n "$(glossary_blocks | jq -c 'select(.kind == "entry")' | head -1)" ]; then pass glossary_written
  elif [ -f "$REPO/GLOSSARY.md" ]; then fail glossary_written "GLOSSARY.md has no **Term** entries"
  else fail glossary_written "no GLOSSARY.md at the repo root: $(cd "$REPO" && git status --porcelain | paste -sd, -)"; fi
}

# check_collision <name> <regex>...: one entry names every regex in its term, _Avoid_
# or _Code_ lines, or one flagged ambiguity mentions them all. Case-insensitive.
check_collision() {
  local name=$1; shift
  local res; res=$(glossary_blocks | jq -s -r --args '$ARGS.positional as $re
    | map(if .kind == "entry" then "\(.term) \(.avoid) \(.code)" else .text end) as $texts
    | if any($texts[]; . as $t | all($re[]; . as $r | $t | test($r; "i"))) then "ok" else "" end' "$@")
  if [ "$res" = ok ]; then pass "$name"
  else fail "$name" "no entry or flagged ambiguity names all of [$(printf '%s ' "$@" | sed 's/ $//')]"; fi
}

# check_archive_split: "archive" names two things. Found when an entry with another
# term lists it under _Avoid_ (the export got its own name), or a flagged ambiguity
# names it with the export.
check_archive_split() {
  local res; res=$(glossary_blocks | jq -s -r '
    any(.[]; (.kind == "entry" and (.avoid | test("archive"; "i")) and (.term | test("archiv"; "i") | not))
      or (.kind == "flagged" and (.text | test("archive"; "i")) and (.text | test("export|backup|snapshot"; "i"))))')
  if [ "$res" = true ]; then pass found_archive_split
  else fail found_archive_split "no _Avoid_ line lists archive and no flagged ambiguity names it with the export"; fi
}

# The skill's own check-entries, one FAIL line per problem in GLOSSARY.md's entries.
entry_problems() { "$SKILL_DIR/scripts/check-entries" "$REPO/GLOSSARY.md" 2>&1 | grep '^FAIL' | sed -E 's/^FAIL [^:]*:[0-9]+: //'; }

# entries_no_code: no definition holds a code span, a file path, an environment
# variable or a data type. entries_short: each is one or two sentences.
check_entries() {
  local probs code long; probs=$(entry_problems)
  long=$(printf '%s\n' "$probs" | grep ': [0-9]* sentences:' | cut -d: -f1-2 | head -3 | paste -sd'|' -)
  code=$(printf '%s\n' "$probs" | grep . | grep -v ': [0-9]* sentences:' | cut -d: -f1-2 | head -3 | paste -sd'|' -)
  if [ -z "$code" ]; then pass entries_no_code; else fail entries_no_code "$code"; fi
  if [ -z "$long" ]; then pass entries_short; else fail entries_short "$long"; fi
}

# agents_line: AGENTS.md (the agent file; CLAUDE.md only imports it) has a line that
# tells agents to use the terms in GLOSSARY.md, keeps its notes, and copies no terms.
check_agents_line() {
  local a="$REPO/AGENTS.md"
  if ! grep 'GLOSSARY\.md' "$a" | grep -Eiq '\b(use|follow)\b.*\bterms?\b|\bterms?\b.*\b(use|follow)'; then
    if grep -q 'GLOSSARY\.md' "$REPO/CLAUDE.md"; then fail agents_line "the line went in CLAUDE.md, not AGENTS.md"
    else fail agents_line "no line in AGENTS.md tells agents to use the terms in GLOSSARY.md"; fi
  elif ! grep -q 'npm test' "$a" || ! grep -q 'Conventional Commits' "$a"; then fail agents_line "AGENTS.md lost its existing notes"
  elif grep -Eiq 'bucket|folder|resolved' "$a"; then fail agents_line "AGENTS.md copies terms: $(grep -Eio '.{0,30}(bucket|folder|resolved).{0,30}' "$a" | head -1)"
  else pass agents_line; fi
}

# only_glossary_files: the run changed nothing but GLOSSARY.md and the agent files.
check_only_glossary_files() {
  local changed; changed=$(cd "$REPO" && { git diff --name-only HEAD; git ls-files --others --exclude-standard; } | sort -u \
    | grep -Ev '^(GLOSSARY\.md|AGENTS\.md|CLAUDE\.md)$' | paste -sd, -)
  if [ -z "$changed" ]; then pass only_glossary_files; else fail only_glossary_files "changed $changed"; fi
}

# What the main agent wrote: each text message, then the final reply.
REPLIES_JQ='if .type == "assistant" and .parent_tool_use_id == null then (.message.content[]? | select(.type == "text") | .text)
  elif .type == "result" then (.result // empty) else empty end'
replies() { jq -r "$REPLIES_JQ" "$TRANSCRIPT"; }
# The same, one message per line, paragraphs split by " ¶ ".
reply_lines() { jq -r "$REPLIES_JQ"' | gsub("\\s*\n\\s*\n\\s*"; " ¶ ") | gsub("\n"; " ")' "$TRANSCRIPT"; }

# check_challenged <name> <avoided regex> <term regex>: in a message that names the glossary,
# one paragraph sets the avoided word against the glossary's term: it names both, and
# says not, instead, rather than, avoid, calls, means or defines, or asks.
check_challenged() {
  local hit; hit=$(reply_lines | grep -Ei 'glossary|_?avoid_?' | perl -CSD -ne 'chomp; print "$_\n" for split / \x{B6} /' | grep -Ei "$2" | grep -Ei "$3" \
    | grep -Ei "\b(not|instead|rather than|avoid|calls?|means?|defines?)\b|_Avoid_|\?" | head -1)
  if [ -n "$hit" ]; then pass "$1"; else fail "$1" "no paragraph sets /$2/ against /$3/ in a message naming the glossary"; fi
}

# sketch_uses_terms: the fenced blocks in the replies (the command and output sketch)
# use no avoided term. The one exception is the existing error "task N is already
# resolved", which a sketch may show; the challenge checks cover saying so.
check_sketch_uses_terms() {
  local bad; bad=$(replies | awk '/^[[:space:]]*(```|~~~)/{on=!on; next} on' | grep -v 'is already resolved' \
    | grep -Eio '.{0,30}\b(folders?|buckets?|resolved?|--resolve)\b.{0,20}' | head -2 | paste -sd'|' -)
  if [ -z "$bad" ]; then pass sketch_uses_terms; else fail sketch_uses_terms "$bad"; fi
}

check_read_glossary() {
  if tool_uses | jq -e -s 'any(.[]; (.name == "Read" and (.input.file_path // "" | test("GLOSSARY\\.md$")))
      or (.name == "Bash" and (.input.command // "" | test("GLOSSARY\\.md"))) or (.name == "Grep" and (.input.path // "" | test("GLOSSARY"))))' >/dev/null
  then pass read_glossary; else fail read_glossary "never read GLOSSARY.md"; fi
}
