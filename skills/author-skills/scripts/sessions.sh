#!/usr/bin/env bash
# Find and read past agent sessions (Claude Code, Codex, Cursor) for a skill review.
#
# Usage:
#   sessions.sh find <skill-name> [--since YYYY-MM-DD] [<term>...]
#   sessions.sh show <transcript.jsonl> [<from-line> [<to-line>]]
#
# find prints one tab-separated row per session that loaded the skill, edited it,
# named it, or matched a term in a user prompt (terms are case-insensitive extended
# regexes), newest first within each group:
#   group  date  agent  loads  hits  other-skills  path  first-prompt
# group is `used` (the skill was loaded), `edited` (the session changed the skill's
# files), `named` (a prompt names it, never loaded) or `similar` (a prompt matches a
# term, the skill never loaded). other-skills lists the other skills the session
# loaded. Sessions that loaded author-skills or review-skill or ran this script, and Codex
# auto-review sessions, are left out.
#
# show prints a session as one line per event, prefixed with its line number in the
# transcript: user, assistant, tool (name and input), skill (the name of a skill
# it loaded), error, interrupt.

set -u

command -v jq >/dev/null || { echo "sessions.sh needs jq" >&2; exit 2; }

usage() {
  sed -n '5,6p' "$0" | sed 's/^# *//' >&2
  exit 2
}

agent_of() {
  case $1 in
    */.codex/*) echo codex ;;
    */agent-transcripts/*) echo cursor ;;
    */.claude/projects/*) echo claude ;;
    *) echo unknown ;;
  esac
}

# One normalized event per line: {l, k, n?, t, ts?, cwd?}.
read -r -d '' NORMALIZE <<'JQ'
def flat: if type == "string" then .
  elif type == "array" then map(if type == "string" then . else (.text // "") end) | join("\n")
  elif . == null then ""
  else tostring end;
def ev($k; $t): {l: input_line_number, k: $k, t: ($t | flat)};
# A tool event, followed by one skill event per skill it loads: a Skill tool call,
# or a short command or read that names <skill>/SKILL.md (long inputs are skill lists).
def tool($n; $input):
  ev("tool"; $input) + {n: $n}
  | ., (if $n == "Skill" then (.t | fromjson? | .skill // empty | split(":") | last)
        elif (.t | length) < 1500 then (.t | [scan("/([a-z0-9-]+)/SKILL\\.md")[0]] | unique | .[])
        else empty end
        | {l: input_line_number, k: "skill", t: .});
def user_text:
  if test("^\\s*\\[Request interrupted") or test("^\\s*<turn_aborted>") then ev("interrupt"; .)
  elif test("^\\s*(<local-command|<task-notification|<system-reminder|<environment_context|<user_instructions|<permissions|<INSTRUCTIONS>|# AGENTS\\.md|Caveat:)") then empty
  else ev("user"; .) end;

def claude:
  if .type == "user" and .isMeta == true then
    .message.content | flat | capture("^Base directory for this skill: (?<d>\\S+)") | ev("skill"; .d | sub("/+$"; "") | split("/") | last)
  elif .type == "user" then
    {l: input_line_number, k: "meta", ts: .timestamp, cwd: .cwd},
    (.message.content | if type == "string" then user_text
      else .[]? | if .type == "text" then (.text | user_text)
        elif .type == "tool_result" and .is_error == true then ev("error"; .content)
        else empty end end)
  elif .type == "assistant" then
    .message.content[]? | if .type == "text" then ev("assistant"; .text)
      elif .type == "tool_use" then tool(.name; .input | tostring)
      else empty end
  else empty end;

def codex:
  if .type == "session_meta" then {l: input_line_number, k: "meta", ts: .payload.timestamp, cwd: .payload.cwd}
  elif .type == "response_item" then .payload as $p |
    if $p.type == "message" and $p.role == "user" then $p.content[]? | (.text // "") | user_text
    elif $p.type == "message" and $p.role == "assistant" then ev("assistant"; $p.content)
    elif $p.type == "function_call" or $p.type == "custom_tool_call" then
      tool($p.name; ($p.arguments // $p.input) | flat)
    elif $p.type == "function_call_output" or $p.type == "custom_tool_call_output" then
      ($p.output | flat) as $o
      | if ($o | test("(?i)exit code:? *[1-9]|exited with code [1-9]|exit_code\\W*[1-9]|command not found|no such file"))
        then ev("error"; $o) else empty end
    else empty end
  elif .type == "event_msg" and .payload.type == "item_completed"
    and .payload.item.type == "CommandExecution" and (.payload.item.exit_code // 0) != 0 then
    ev("error"; ((.payload.item.command | flat) + "\n" + (.payload.item.aggregated_output | flat)))
  else empty end;

def cursor:
  if .role == "user" then
    .message.content[]? | select(.type == "text") | .text
    | ((capture("<user_query>\\s*(?<q>[\\s\\S]*?)\\s*</user_query>") | .q) // .) | user_text
  elif .role == "assistant" then
    .message.content[]? | if .type == "text" then ev("assistant"; .text)
      elif .type == "tool_use" then tool(.name; .input | tostring)
      else empty end
  else empty end;

if $agent == "claude" then claude elif $agent == "codex" then codex else cursor end
JQ

# Reads normalized events as an array; prints one TSV row or nothing.
read -r -d '' SUMMARIZE <<'JQ'
def skill_names: select(.k == "skill") | .t;
def loads($n):
  [ .[] | select(
      (.k == "skill" and .t == $n)
      or (.k == "user" and (.t | contains("<command-name>/" + $n + "</command-name>")))
      or ($agent == "codex" and .k == "user" and (.t | test("\\$" + $n + "([^a-z0-9-]|$)")))
    ) ] | length;
def edits($n):
  [ .[] | select(.k == "tool" and (.t | contains("/" + $n + "/"))
      and ((.n | IN("Write", "Edit", "MultiEdit", "StrReplace", "apply_patch"))
        or (.t | test("\\*\\*\\* (Update|Add|Delete) File")))) ] | length;
def named_re($n):
  if ($n | contains("-")) then "(^|[^a-z0-9-])" + $n + "([^a-z0-9-]|$)"
  else "[/$]" + $n + "\\b|\\b" + $n + " skill\\b" end;

(map(select(.k == "meta")) | first // {}) as $meta
| (map(select(.k == "user")) | map(.t)) as $prompts
| loads($name) as $loads
| select(loads("author-skills") == 0 and loads("review-skill") == 0)
| select(any(.[]; .k == "tool" and (.t | test("(author-skills|review-skill)/scripts/sessions\\.sh"))) | not)
| select(($prompts | first // "") | startswith("The following is the Codex agent history") | not)
| ([$prompts[] | select(test(named_re($name); "i"))] | length) as $named
| (if $terms == "" then 0 else [$prompts[] | select(test($terms; "i"))] | length end) as $hits
| (if edits($name) > 0 then "edited" elif $loads > 0 then "used" elif $named > 0 then "named"
   elif $hits > 0 then "similar" else empty end) as $group
| ([.[] | skill_names] | unique - [$name]
   | if length > 6 then (.[0:6] | join(",")) + ",+\(length - 6)" else join(",") end) as $others
| ($meta.ts // $mtime) as $date
| select($since == "" or $date >= $since)
| [$group, ($date | .[0:16]), $agent, $loads, $hits, ($others | if . == "" then "-" else . end), $path,
   (($prompts | first // "") | gsub("\\s+"; " ") | .[0:120])]
| @tsv
JQ

normalize() {
  jq -c --arg agent "$(agent_of "$1")" "$NORMALIZE" "$1" 2>/dev/null
}

cmd_find() {
  [ $# -ge 1 ] || usage
  local name=$1 since="" terms=() pattern
  shift
  while [ $# -gt 0 ]; do
    case $1 in
      --since) since=${2:-}; shift 2 ;;
      *) terms+=("$1"); shift ;;
    esac
  done

  local joined=""
  if [ ${#terms[@]} -gt 0 ]; then
    joined=$(IFS='|'; printf '%s' "${terms[*]}")
    pattern="$name|$joined"
  else
    pattern=$name
  fi

  local roots=()
  for d in "$HOME/.claude/projects" "$HOME/.codex/sessions" "$HOME/.cursor/projects"; do
    [ -d "$d" ] && roots+=("$d")
  done
  [ ${#roots[@]} -gt 0 ] || { echo "no transcript folders found" >&2; exit 1; }

  printf 'group\tdate\tagent\tloads\thits\tother-skills\tpath\tfirst-prompt\n'
  grep -rliE --include='*.jsonl' -e "$pattern" "${roots[@]}" 2>/dev/null \
    | while IFS= read -r f; do
        agent=$(agent_of "$f")
        case $f in */.cursor/projects/*) [ "$agent" = cursor ] || continue ;; esac
        normalize "$f" | jq -rs \
          --arg name "$name" --arg terms "$joined" --arg since "$since" \
          --arg agent "$agent" --arg path "$f" \
          --arg mtime "$(date -r "$f" +%Y-%m-%dT%H:%M)" \
          "$SUMMARIZE" 2>/dev/null
      done \
    | awk -F '\t' '{ print index("used edited named similar", $1) "\t" $0 }' \
    | sort -t "$(printf '\t')" -k1,1n -k3,3r \
    | cut -f 2-
}

cmd_show() {
  [ $# -ge 1 ] && [ -f "$1" ] || usage
  local from=${2:-0} to=${3:-999999999}
  normalize "$1" | jq -r --argjson from "$from" --argjson to "$to" '
    select(.k != "meta" and .l >= $from and .l <= $to)
    | ({user: 2000, assistant: 800, tool: 300, error: 400, interrupt: 200, skill: 200}[.k]) as $max
    | (.t | if length > $max then .[0:$max] + " [...]" else . end) as $t
    | "\(.l) \(.k)\(if .n then " " + .n else "" end): \($t)"'
}

case ${1:-} in
  find) shift; cmd_find "$@" ;;
  show) shift; cmd_show "$@" ;;
  *) usage ;;
esac
