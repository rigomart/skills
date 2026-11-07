# lib.sh: setup and check helpers shared by the recall scenarios.
#
# Privacy: eval runs keep the real $HOME, and recall's sessions.sh reads chats from
# ~/.claude/projects and ~/.codex/sessions. Every scenario calls recall_isolate,
# which points sessions.sh at fixture chats in the run's temp dir and installs
# guard.sh as a hook that blocks any tool call reaching the real ones.
# check_no_real_chats fails a run that tried.

WORK() { dirname "$REPO"; }

# Setup: export commit dates <days> ago, so the fixture's history has a timeline.
at() {
  local t; t=$(perl -e 'print time - $ARGV[0] * 86400' "$1")
  export GIT_AUTHOR_DATE="@$t +0000" GIT_COMMITTER_DATE="@$t +0000"
}

# Setup: the tasks repo, 20 days old, with gh state seeded and fake CI running
# lint and test (and any extra checks given as JSON) on every pushed commit.
recall_repo() { # recall_repo [extra checks JSON]
  at 20
  make_tasks_repo
  git -C "$REMOTE" config core.logAllRefUpdates always
  seed_gh_state
  gh_json --arg remote "$REMOTE" --argjson extra "${1:-"{}"}" \
    '.ci = {checks: ({lint: "node scripts/lint.mjs", test: "node --test"} + $extra), delay: 0, remote: $remote, list_rollup: true}
     | del(.checks, .required_checks)'
}
gh_json() { local tmp; tmp=$(mktemp); jq "$@" "$EVAL_GH_STATE/state.json" > "$tmp" && mv "$tmp" "$EVAL_GH_STATE/state.json"; }

# Setup: commit on the current branch and push it.
commit_push() { commit "$1" && git -C "$REPO" push -q -u origin "$(git -C "$REPO" branch --show-current)" 2>/dev/null; }

# Setup: add a PR to the fake gh state. pr <number> <head> <state> <title> <body>
pr() {
  gh_json --argjson n "$1" --arg head "$2" --arg st "$3" --arg title "$4" --arg body "$5" \
    '.prs += [{number: $n, title: $title, body: $body, base: "main", head: $head, state: $st, draft: false}]
     | .next_pr = ([.next_pr, $n + 1] | max)'
}

# Setup: point sessions.sh at fixture chats and install the guard. Call it before
# writing sessions and before snapshot.
recall_isolate() {
  local w; w=$(cd "$(WORK)" && pwd -P)
  mkdir -p "$w/chats/claude-projects" "$w/chats/codex-sessions" "$REPO/.claude/hooks"
  echo ".claude/" >> "$REPO/.git/info/exclude"
  cp "$EVAL_HERE/recall/guard.sh" "$REPO/.claude/hooks/guard.sh"
  jq -n --arg c "$w/chats/claude-projects" --arg x "$w/chats/codex-sessions" '{
    env: {RECALL_CLAUDE_PROJECTS: $c, RECALL_CODEX_SESSIONS: $x},
    hooks: {PreToolUse: [{hooks: [{type: "command", command: "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/guard.sh"}]}]}
  }' > "$REPO/.claude/settings.json"
}
chats() { echo "$(cd "$(WORK)" && pwd -P)/chats"; }
repo_path() { git -C "$REPO" worktree list --porcelain | sed -n 's/^worktree //p' | head -1; }

# Setup: write a fixture chat from stdin, one message per line: "U <text>" for the
# user, "A <text>" for the agent, with \n for a line break. Its mtime is <days> ago.
#   claude_session <days ago> <id>    codex_session <days ago> <id>
claude_session() {
  local dir f; dir="$(chats)/claude-projects/$(repo_path | tr '/.' '--')"; mkdir -p "$dir"; f="$dir/$2.jsonl"
  session_lines | jq -c --arg cwd "$(repo_path)" --arg id "$2" '
    if .role == "U" then {type: "user", isMeta: false, cwd: $cwd, sessionId: $id, message: {role: "user", content: .text}}
    else {type: "assistant", cwd: $cwd, sessionId: $id, message: {role: "assistant", content: [{type: "text", text: .text}]}} end' > "$f"
  age "$1" "$f"
}
codex_session() {
  local dir f; dir="$(chats)/codex-sessions/2026/11"; mkdir -p "$dir"; f="$dir/rollout-$2.jsonl"
  { jq -nc --arg cwd "$(repo_path)" --arg id "$2" '{type: "session_meta", payload: {id: $id, cwd: $cwd, originator: "codex_cli"}}'
    session_lines | jq -c '{type: "response_item", payload: {type: "message", role: (if .role == "U" then "user" else "assistant" end),
      content: [{type: (if .role == "U" then "input_text" else "output_text" end), text: .text}]}}'; } > "$f"
  age "$1" "$f"
}
session_lines() { perl -ne 'print "$1\t$2\n" if /^([UA]) (.*)$/' | jq -Rc 'split("\t") | {role: .[0], text: (.[1:] | join("\t") | gsub("\\\\n"; "\n"))}'; }
age() { perl -e '$t = time - $ARGV[0] * 86400; utime $t, $t, $ARGV[1]' "$1" "$2"; }

# Setup, last: record what the run must leave as it found it.
snapshot() { state_now > "$(WORK)/snapshot"; }
state_now() {
  echo "== status"; git -C "$REPO" status --porcelain=v1 -uall
  echo "== refs"; git -C "$REPO" for-each-ref --format='%(refname) %(objectname)' refs/heads refs/tags refs/stash
  echo "== HEAD"; git -C "$REPO" symbolic-ref -q HEAD || git -C "$REPO" rev-parse HEAD
  echo "== worktrees"; git -C "$REPO" worktree list --porcelain | grep '^worktree '
  echo "== files"; (cd "$REPO" && git ls-files -co --exclude-standard -z | xargs -0 shasum 2>/dev/null)
  echo "== remote"; git -C "$REMOTE" for-each-ref --format='%(refname) %(objectname)'
  echo "== gh"; jq -S '{prs: [.prs[] | del(.checksDone, .autoMerge)], issues, labels, releases}' "$EVAL_GH_STATE/state.json"
  echo "== chats"; (cd "$(chats)" && find . -type f | sort | xargs shasum)
}

# The brief: the last reply, since a run that waits on a subagent ends more than one turn.
brief() { jq -rs 'map(select(.type=="result")) | last | .result // ""' "$TRANSCRIPT"; }
# brief_lines <regex>: the brief's lines matching it, case-insensitive.
brief_lines() { brief | grep -Ei -- "$1" || true; }

# no_real_chats: the guard hook ran on the run's tool calls and blocked none, and
# no call in the transcript (subagents' included) names a real .claude or .codex
# path or the home directory.
check_no_real_chats() {
  local log="$REPO/.claude/eval-guard.log" bad
  bad=$(tool_uses | jq -c '{tool_name: .name, tool_input: .input}' | while IFS= read -r call; do
    printf '%s' "$call" | CLAUDE_PROJECT_DIR=$REPO GUARD_REPLAY=1 bash "$EVAL_HERE/recall/guard.sh" 2>&1 >/dev/null | head -1
  done | head -1)
  if [ ! -s "$log" ] && [ -n "$(tool_uses)" ]; then fail no_real_chats "the guard hook never ran"
  elif grep -q '^BLOCK' "$log" 2>/dev/null; then fail no_real_chats "$(grep -m1 '^BLOCK' "$log")"
  elif [ -n "$bad" ]; then fail no_real_chats "$bad"
  else pass no_real_chats; fi
}

# nothing_changed: the repo's files, index, branches, stash and worktrees, the
# remote, the fake GitHub and the fixture chats are as setup left them. A fetch
# (remote-tracking refs) is allowed.
check_nothing_changed() {
  local d; d=$(diff "$(WORK)/snapshot" <(state_now) | grep '^[<>]' | head -3 | cut -c1-120 | paste -sd'|' -)
  local edits; edits=$(tool_uses | jq -r 'select(.name | test("^(Edit|Write|MultiEdit|NotebookEdit)$")) | .input.file_path' | head -2 | paste -sd, -)
  if [ -n "$d" ]; then fail nothing_changed "$d"
  elif [ -n "$edits" ]; then fail nothing_changed "edited $edits"
  else pass nothing_changed; fi
}

# next_move: the brief ends on a "Next move" with an action in it.
check_next_move() {
  if brief | perl -0ne 'exit !(/^[^\w\n]*(?:\d+[.)]\s*)?(?:\*\*|__)?\s*next (?:move|step)s?\b[^\n]*?(?::|\*\*|$)\s*(?:\*\*)?\s*\S[^\n]{8,}/mi
      || /^[^\w\n]*(?:\d+[.)]\s*)?(?:\*\*|__)?\s*next (?:move|step)s?\b[^\n]*\n+\s*\S[^\n]{8,}/mi)'; then pass next_move
  else fail next_move "no Next move section with an action"; fi
}

# threads_covered <name>=<regex>...: each thread is named in the brief.
check_threads() {
  local missing="" kv
  for kv in "$@"; do brief | grep -Eqi -- "${kv#*=}" || missing="$missing ${kv%%=*}"; done
  if [ -z "$missing" ]; then pass threads_covered; else fail threads_covered "missing:$missing"; fi
}

# read_past_chats: ran sessions.sh, or read a fixture chat.
check_read_chats() {
  if bash_cmds | grep -q 'sessions\.sh' || tool_uses | jq -e -s 'any(.[]; .input | tostring | test("chats/(claude-projects|codex-sessions)/"))' >/dev/null
  then pass read_past_chats; else fail read_past_chats "never ran sessions.sh or read a past chat"; fi
}

# gh_ok: each gh call that succeeded, as one line of arguments (from the fake gh's log).
gh_ok() { jq -r 'select(.exit == 0) | .argv | join(" ")' "$EVAL_GH_STATE/calls.jsonl"; }
# json_has <regex>: no --json flag, or one whose fields match the regex.
json_has() { awk -v re="--json[= ][^ ]*($1)" '!/--json[= ]/ || $0 ~ re'; }
# tool_output_has <regex>: a tool result the main agent or a subagent got matches it.
tool_output_has() {
  jq -r 'select(.type=="user") | .message.content[]? | select(.type=="tool_result")
    | .content | if type=="string" then . else map(.text? // "") | join("\n") end' "$TRANSCRIPT" | grep -Eq -- "$1"
}

change_list_json() {
  perl -pi -e 's/^  for \(const t of listTasks/  if (args[0] === "--json") console.log(JSON.stringify(listTasks(list)));\n  else for (const t of listTasks/' src/cli.mjs
  printf '\n`tasks list --json` prints the open tasks as JSON, for scripts.\n' >> README.md
}

# Due dates on tasks. change_due_dates [us]: without `us`, parseDue reads only
# 2026-12-01, so the test for 12/01/2026 fails; with it, both pass.
change_due_dates() {
  local us=""
  [ -z "${1:-}" ] || us='  const us = /^(\d{2})\/(\d{2})\/(\d{4})$/.exec(text);
  if (us) return `${us[3]}-${us[1]}-${us[2]}`;
'
  perl -pi -e 's/addTask\(list, title\)/addTask(list, title, due)/; s/const task = \{ id, title, done: false \};/const task = { id, title, done: false, due: due ? parseDue(due) : null };/' src/tasks.mjs
  cat >> src/tasks.mjs <<JS

// A due date as YYYY-MM-DD.
export function parseDue(text) {
${us}  if (/^\d{4}-\d{2}-\d{2}$/.test(text)) return text;
  throw new Error(\`cannot read the date \${text}\`);
}
JS
  perl -pi -e 's/import \{ addTask, completeTask, listTasks \}/import { addTask, completeTask, listTasks, parseDue }/' test/tasks.test.mjs
  cat >> test/tasks.test.mjs <<'JS'

test("parseDue reads ISO and US-style dates", () => {
  assert.equal(parseDue("2026-12-01"), "2026-12-01");
  assert.equal(parseDue("12/01/2026"), "2026-12-01");
});
JS
}

change_undo() {
  cat >> src/tasks.mjs <<'JS'

export function undoTask(list, id) {
  return list.map((t) => (t.id === id ? { ...t, done: false } : t));
}
JS
  perl -pi -e 's/import \{ addTask, completeTask, listTasks \}/import { addTask, completeTask, listTasks, undoTask }/; s/^\} else \{$/} else if (command === "undo") {\n  save(undoTask(list, Number(args[0])));\n  console.log(`undone #\${args[0]}`);\n} else {/' src/cli.mjs
}
