# checks.sh: helpers for a scenario's check.sh. Each check prints one line,
# "PASS <name>" or "FAIL <name>: <detail>". Sourced with REPO, REMOTE,
# EVAL_GH_STATE and TRANSCRIPT set.

pass() { echo "PASS $1"; }
fail() { echo "FAIL $1: $2"; }
expect() { # expect <name> <detail-on-fail> <command...>
  local name=$1 detail=$2; shift 2
  if "$@" >/dev/null 2>&1; then pass "$name"; else fail "$name" "$detail"; fi
}

tool_uses() { jq -c 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use")' "$TRANSCRIPT"; }
bash_cmds() { tool_uses | jq -r 'select(.name=="Bash") | .input.command'; }
final_text() { jq -r 'select(.type=="result") | .result // empty' "$TRANSCRIPT"; }
gh_calls() { jq -r '.argv | join(" ")' "$EVAL_GH_STATE/calls.jsonl"; }
prs() { jq -c '.prs[]' "$EVAL_GH_STATE/state.json"; }
new_prs() { jq -c --argjson first "${FIRST_NEW_PR:-1}" '.prs[] | select(.number >= $first)' "$EVAL_GH_STATE/state.json"; }
pr_field() { jq -r --argjson n "$1" ".prs[] | select(.number==\$n) | $2" "$EVAL_GH_STATE/state.json"; }
headings() { printf '%s\n' "$1" | grep -E '^## ' | sed -E 's/^## +//; s/[[:space:]]+$//'; }
remote_branches() { git -C "$REMOTE" for-each-ref --format='%(refname:short)' refs/heads; }

skill_loaded() {
  tool_uses | jq -e -s 'any(.[]; (.name=="Skill" and (.input.skill // "" | test("ship-changes"))) or (.name=="Read" and (.input.file_path // "" | test("skills/ship-changes/SKILL.md"))) or (.name=="Bash" and (.input.command // "" | test("skills/ship-changes(/SKILL.md)?"))))' >/dev/null
}

check_skill_loaded() { expect skill_loaded "never invoked or read the ship-changes skill" skill_loaded; }

check_ran() { # check_ran <name> <regex over Bash commands>
  if bash_cmds | grep -Eq "$2"; then pass "$1"; else fail "$1" "no Bash command matched /$2/"; fi
}

check_branch_name() { # check_branch_name <branch>
  local b=$1
  if [ -z "$b" ]; then fail branch_name "no branch"; return; fi
  if printf '%s' "$b" | grep -Eq '^[a-z0-9]+(-[a-z0-9]+)*$' && [ ${#b} -le 50 ] \
     && ! printf '%s' "$b" | grep -Eq '^(main|master|wip|fix|work|changes|update|feature|issue-[0-9]+)$'; then
    pass branch_name
  else
    fail branch_name "'$b' is not a short descriptive lowercase-hyphenated name"
  fi
}

check_conventional_commits() { # check_conventional_commits <range in REMOTE> <allowed types regex>
  local subjects bad
  subjects=$(git -C "$REMOTE" log --format=%s "$1")
  if [ -z "$subjects" ]; then fail conventional_commits "no commits in $1"; return; fi
  bad=$(printf '%s\n' "$subjects" | grep -Ev "^(${2})(\([a-z0-9-]+\))?!?: [^ ]" || true)
  if [ -z "$bad" ]; then pass conventional_commits; else fail conventional_commits "$(printf '%s' "$bad" | head -3 | paste -sd'|' -)"; fi
}

check_clean_tree() { # everything but the listed stray paths was committed
  local left
  left=$(git -C "$REPO" status --porcelain | grep -Ev "${1:-^$}" || true)
  if [ -z "$left" ]; then pass all_changes_committed; else fail all_changes_committed "$(printf '%s' "$left" | paste -sd'|' -)"; fi
}

check_no_draft() {
  if jq -e '[.prs[] | select(.draft)] | length == 0' "$EVAL_GH_STATE/state.json" >/dev/null; then pass not_draft; else fail not_draft "a PR was opened as a draft"; fi
}

check_not_merged() {
  if gh_calls | grep -Eq '^pr merge'; then fail not_merged "ran: $(gh_calls | grep -E '^pr merge' | head -1)"; else pass not_merged; fi
}

check_title() { # check_title <pr> <type regex>
  local t; t=$(pr_field "$1" .title)
  if printf '%s' "$t" | grep -Eq "^(${2})(\([a-z0-9-]+\))?!?: [^ ]"; then pass "pr${1}_title"; else fail "pr${1}_title" "'$t'"; fi
}

check_template() { # check_template <pr> <expected headings, one per line>
  local body got want
  body=$(pr_field "$1" .body)
  got=$(headings "$body")
  want=$2
  if [ "$got" = "$want" ]; then pass "pr${1}_template"; else fail "pr${1}_template" "headings were [$(printf '%s' "$got" | paste -sd, -)], want [$(printf '%s' "$want" | paste -sd, -)]"; fi
}

check_pr_text() {
  local f out; f=$(mktemp); pr_field "$1" .body > "$f"
  if out=$("$SKILL_DIR/scripts/check-pr-text" "$f" 2>&1); then pass "pr${1}_check_pr_text"; else fail "pr${1}_check_pr_text" "$(printf '%s' "$out" | head -2 | paste -sd'|' -)"; fi
  rm -f "$f"
}

check_reported_url() { # check_reported_url <pr>
  if final_text | grep -q "acme/tasks/pull/$1"; then pass "report_pr${1}_url"; else fail "report_pr${1}_url" "final reply has no link to PR #$1"; fi
}

template_for_type() {
  case "$1" in
    fix) printf 'Symptom\nRoot cause\nFix\nBlast radius\nVerification' ;;
    refactor) printf 'Why\nWhat changed\nBehavior unchanged\nBlast radius' ;;
    perf) printf 'Why\nMeasurements\nWhat changed\nBlast radius' ;;
    docs) printf 'Why\nWhat changed' ;;
    chore|ci|build|test|style) printf 'Why\nWhat changed\nVerification' ;;
    revert) printf 'Why\nReverts\nFollow-up' ;;
    *) printf 'Why\nWhat changed\nDecisions\nBlast radius\nVerification' ;;
  esac
}

check_template_by_type() { # check_template_by_type <pr>
  local type; type=$(pr_field "$1" .title | sed -E 's/^([a-z]+).*/\1/')
  check_template "$1" "$(template_for_type "$type")"
}
