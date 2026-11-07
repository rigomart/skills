# lib.sh: setup and check helpers shared by the do scenarios.

# Setup: install the scenario's hooks as project settings.
# do_hooks [cap regex] [follow-up message]
#   cap: an extended regex over "<tool> <input JSON>"; the run ends at the first
#        tool call that matches it (hooks/cap.sh). Empty for no cap.
#   follow-up: sent back as the user's next message the first time the agent
#        stops (hooks/followup.sh).
do_hooks() {
  mkdir -p "$REPO/.claude/hooks"
  cp "$EVAL_HERE/do/hooks/cap.sh" "$EVAL_HERE/do/hooks/followup.sh" "$REPO/.claude/hooks/"
  printf '%s\n' "${1:-}" | grep . > "$REPO/.claude/eval-cap" || true
  [ -z "${2:-}" ] || printf '%s' "$2" > "$REPO/.claude/eval-followup"
  cat > "$REPO/.claude/settings.json" <<'EOF'
{
  "hooks": {
    "PreToolUse": [{ "hooks": [{ "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/cap.sh" }] }],
    "Stop": [{ "hooks": [{ "type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/followup.sh" }] }]
  }
}
EOF
}

# Setup: commit the scenario's starting state on main and push it.
commit_pushed() { commit "$1" && git -C "$REPO" push -q origin main 2>/dev/null; }

# The main agent's tool calls and follow-ups as one JSON array, in transcript
# order: {seq, kind: "tool", id, name, input} or {seq, kind: "followup"}.
do_events() {
  jq -c -n '[inputs] | to_entries | map(.key as $i | .value as $v
    | if $v.type == "assistant" and $v.parent_tool_use_id == null then
        [$v.message.content // [] | to_entries[] | select(.value.type == "tool_use")
          | {seq: ($i * 1000 + .key), kind: "tool", id: .value.id, name: .value.name, input: .value.input}]
      elif $v.type == "user" and $v.parent_tool_use_id == null and ($v.isSynthetic // false)
        and ($v.message.content | tostring | test("Stop hook feedback")) then [{seq: ($i * 1000), kind: "followup"}]
      else [] end) | add // []' "$TRANSCRIPT"
}

# The main agent's tasks as one JSON array, in creation order:
# {id, seq, seg, created, subject, description, status}. created is the subject
# and description the task was created with; the rest is its final state. seg
# is 1 before the first follow-up, 2 after it. Built on task_calls, joined with
# the transcript order; prints an error and an empty array when they disagree.
do_tasks() {
  local calls; calls=$(task_calls | jq -s .)
  jq -n --argjson ev "$(do_events)" --argjson calls "$calls" '
    ($ev | map(select(.kind == "followup") | .seq)) as $b
    | [$ev[] | select(.kind == "tool" and (.name == "TaskCreate" or .name == "TaskUpdate"))] as $tc
    | if ($tc | length) != ($calls | length) then ("task_calls has \($calls | length) calls, the transcript \($tc | length)" | halt_error(1)) else . end
    | [range(0; $tc | length) as $k | {seq: $tc[$k].seq} + $calls[$k]] | map(select(.error | not))
    | reduce .[] as $c ({order: [], t: {}};
        ($c.task // "?\($c.seq)") as $id
        | if $c.tool == "TaskCreate" then
            .order += [$id]
            | .t[$id] = {id: $id, seq: $c.seq, seg: (1 + ($b | map(select(. < $c.seq)) | length)),
                created: "\($c.subject // "") \($c.description // "")",
                subject: ($c.subject // ""), description: ($c.description // ""), status: ($c.status // "pending")}
          else .t[$id] = ((.t[$id] // {id: $id, seq: $c.seq, seg: 0, created: "", subject: "", description: "", status: "pending"})
            + ({subject: $c.subject, description: $c.description, status: $c.status} | with_entries(select(.value != null)))) end)
    | [.order[] as $id | .t[$id]]' || echo '[]'
}

# Each numbered step's lead paragraph in a playbook, one per line.
playbook_steps() { awk '/^[0-9]+\. /{ sub(/^[0-9]+\. /, ""); print }' "$SKILL_DIR/playbooks/$1.md"; }

# The jq both step checks share: norm (formatting marks, quotes and spacing
# dropped), $S (the playbook's steps, normed), $T (the segment's tasks) and
# match_step (the index of the first task in $T created with step $i's text).
DO_JQ_DEFS='
  def norm: gsub("[`*]"; "") | gsub("[‘’]"; "'"'"'") | gsub("[“”]"; "\"") | gsub("\\s+"; " ") | ltrimstr(" ") | rtrimstr(" ");
  ($steps | map(norm)) as $S
  | [$tasks[] | select(.seg == $seg)] as $T
  | def made($i): [$T | to_entries[] | select(.value.created | norm | contains($S[$i])) | .key][0];
    def final_text: "\(.subject) \(.description)" | norm;'

# A tool call that does a step's work, not a read: a file edit, a skill load
# (the Skill tool, or a read of another skill's SKILL.md), a subagent, a web call,
# or a shell command that writes, commits or runs code. Quoted text is dropped
# first, and so are calls to the skill's own scripts/steps, which run before the
# list by design.
DO_JQ_WORK='
  def work: (.name | test("^(Edit|Write|MultiEdit|NotebookEdit|Skill|Agent|Task|WebSearch|WebFetch|EnterWorktree)$"))
    or (.name == "Read" and (.input.file_path // "" | test("skills/[a-z-]+/SKILL\\.md$")) and (.input.file_path | test("skills/do/SKILL\\.md$") | not))
    or (.name == "Bash" and (.input.command // "" | gsub("\"[^\"]*\"|'"'"'[^'"'"']*'"'"'"; "\"\"")
      | gsub("((bash|sh) )?[^ ;&|]*scripts/steps( [a-z]+)?"; "")
      | test("\\bgit( -C [^ ]+)? (commit|add|checkout|switch|stash|worktree|push|reset|restore|apply|merge|rebase)\\b|\\bsed -i|\\bperl -[a-z]*i|\\btee |\\b(mkdir|touch|rm|mv|cp) |\\bnpm (install|ci|test|t|run)\\b|\\b(node|python3?|bash|sh) [^-]|\\bgh (pr|issue) (create|edit|comment|merge|close)|(^|[^0-9&>])>>?\\s*(?!/dev/null)[^\\s&]")));'

# check_picked <playbook> [segment]: the agent read that playbook in the
# segment. picked_<playbook> for the first message, switched_to_<playbook> after
# the follow-up.
check_picked() {
  local pb=$1 seg=${2:-1} name read
  if [ "$seg" = 1 ]; then name="picked_$pb"; else name="switched_to_$pb"; fi
  read=$(do_events | jq -r --argjson seg "$seg" '
    (map(select(.kind == "followup") | .seq)) as $b
    | .[] | select(.kind == "tool") | . as $e
    | select((1 + ($b | map(select(. < $e.seq)) | length)) == $seg)
    | "\(.input.file_path // "") \(.input.command // "")" | scan("playbooks/([a-z]+)\\.md") | .[0]' | sort -u | paste -sd, -)
  if printf ',%s,' "$read" | grep -q ",$pb,"; then pass "$name"; else fail "$name" "read playbooks [${read}], not $pb"; fi
}

# check_steps <playbook> [segment]: the checks on the list the agent made for that
# playbook in the segment (1 before the follow-up, 2 after it).
#   <pb>_steps_copied: each step's text, word for word, is in a task as it ended.
#   <pb>_steps_first: the list's first tasks are the steps, in order, as created.
#   <pb>_list_before_work: no step's work began before the list held every step.
check_steps() {
  local pb=$1 seg=${2:-1} r
  r=$(jq -n --argjson tasks "$(do_tasks)" --argjson ev "$(do_events)" --argjson seg "$seg" \
    --argjson steps "$(playbook_steps "$pb" | jq -R . | jq -s .)" "$DO_JQ_DEFS $DO_JQ_WORK"'
    ([0] + ($ev | map(select(.kind == "followup") | .seq)))[$seg - 1] as $start
    | ($ev | map(select(.kind == "followup") | .seq) | .[$seg - 1] // 1e18) as $end
    | if ($T | length) == 0 then {copied: "no task list", first: "no task list", work: "no task list"} else
      [range(0; $S | length) as $i | select([$T[] | final_text | contains($S[$i])] | any | not) | $i + 1] as $missing
      | [range(0; $S | length) as $i | select(($T[$i].created // "" | norm | contains($S[$i])) | not) | $i + 1] as $unordered
      | [range(0; $S | length) as $i | made($i)] as $made
      | {copied: (if $missing == [] then null
           else "step \($missing | map(tostring) | join(",")) not word for word; tasks: \($T | map(.subject[:60]) | join(" | "))" end),
         first: (if $unordered == [] then null
           else "task \($unordered[0]) is \"\($T[$unordered[0] - 1].subject // "missing" | .[:80])\", not step \($unordered[0])" end),
         work: (if ($made | any(. == null)) then "the list never held every step"
           else ($made | map($T[.].seq) | max) as $done
           | [$ev[] | select(.kind == "tool" and .seq > $start and .seq < $done and .seq < $end) | select(work)] as $early
           | if $early == [] then null
             else "\($early[0].name) before the list was done: \($early[0].input | tostring | .[:120])" end end)}
      end')
  for c in copied first work; do
    local name detail
    case $c in copied) name="${pb}_steps_copied" ;; first) name="${pb}_steps_first" ;; work) name="${pb}_list_before_work" ;; esac
    detail=$(printf '%s' "$r" | jq -r ".$c // empty")
    if [ -z "$r" ]; then fail "$name" "could not read the task list"
    elif [ -z "$detail" ]; then pass "$name"; else fail "$name" "$detail"; fi
  done
}

# check_skips <playbook> <segment> <steps that must be skipped> <steps that may stay open> <full|capped>
# <pb>_skips_have_reasons: no step was deleted; a step marked skipped says
# "skip: <reason>" after its text ("skip shipping: <reason>" counts too, a bare
# "(skipped)" does not); each step the run did not do (the listed
# ones) carries one; and, in a full run, every other step ended completed.
check_skips() {
  local pb=$1 seg=$2 required=$3 open=$4 mode=$5 r
  r=$(jq -n -r --argjson tasks "$(do_tasks)" --argjson seg "$seg" --arg mode "$mode" \
    --argjson required "[$(printf '%s' "$required" | tr ' ' ,)]" --argjson open "[$(printf '%s' "$open" | tr ' ' ,)]" \
    --argjson steps "$(playbook_steps "$pb" | jq -R . | jq -s .)" "$DO_JQ_DEFS"'
    [range(0; $S | length) as $i | made($i) as $k | select($k != null) | $T[$k] as $t
      | ($t | final_text | split($S[$i]) | join(" ")) as $extra
      | ($extra | test("skip[a-z]*( [a-z]+)?: *[^ ]..."; "i")) as $skipped
      | if $t.status == "deleted" then "step \($i + 1) deleted"
        elif ($extra | test("skip"; "i")) and ($skipped | not) then "step \($i + 1) skipped without \"skip: <reason>\": \($extra[:80])"
        elif ($required | index($i + 1)) and ($skipped | not) then "step \($i + 1) not done but ended \($t.status) with no \"skip: <reason>\""
        elif $mode == "full" and ($open | index($i + 1) | not) and $t.status != "completed" and ($skipped | not) then "step \($i + 1) left \($t.status)"
        else empty end]
    | if [range(0; $S | length) as $i | made($i)] | all(. == null) then "no step in the task list" else join("; ") end')
  if [ -z "$r" ]; then pass "${pb}_skips_have_reasons"; else fail "${pb}_skips_have_reasons" "$r"; fi
}

# reply_no_process: the final reply leaves the playbook and its steps out.
check_reply() {
  local hit; hit=$(final_text | grep -Eio '.{0,40}(playbook|\bsteps? [0-9]|task list).{0,40}' | head -1)
  if [ -z "$(final_text)" ]; then fail reply_no_process "no final reply"
  elif [ -z "$hit" ]; then pass reply_no_process; else fail reply_no_process "says: $hit"; fi
}

# Prints a NOTE line naming the call the cap stopped the run at, if any.
note_cap() { [ -s "$REPO/.claude/eval-cap.log" ] && echo "NOTE capped at: $(head -1 "$REPO/.claude/eval-cap.log" | cut -c1-160)"; return 0; }
