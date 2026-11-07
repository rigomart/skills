# lib.sh: setup and check helpers shared by the implement scenarios.

# Setup: commit the scenario's starting state on main, push it, and record it as
# the base the checks diff against.
commit_base() {
  commit "$1"
  git -C "$REPO" push -q origin main 2>/dev/null
  git -C "$REPO" rev-parse HEAD > "$(dirname "$REPO")/base"
}
base() { cat "$(dirname "$REPO")/base"; }

# Each path the run changed against the base, committed or not, untracked files
# included. .evidence/ is left out: the evidence checks cover it.
changed_paths() {
  { git -C "$REPO" diff --name-only "$(base)"; git -C "$REPO" ls-files --others --exclude-standard; } \
    | grep -v '^\.evidence/' | sort -u
}

# check_scope <regex of allowed paths> [problem]: nothing outside the allowed
# paths changed, and the scenario found no problem of its own.
check_scope() {
  local extra; extra=$(changed_paths | grep -Ev "$1" || true)
  if [ -n "$extra" ]; then fail diff_in_scope "changed $(printf '%s' "$extra" | paste -sd, -)"
  elif [ -n "${2:-}" ]; then fail diff_in_scope "$2"
  else pass diff_in_scope; fi
}

# evidence_written: .evidence/<change>/evidence.md exists. evidence_untracked:
# git never tracked it, and it is ignored through info/exclude, not .gitignore.
check_evidence() {
  local f tracked src
  f=$(cd "$REPO" && ls .evidence/*/evidence.md 2>/dev/null | head -1)
  if [ -z "$f" ]; then
    fail evidence_written "no .evidence/<change>/evidence.md"; fail evidence_untracked "no evidence.md"; return
  fi
  pass evidence_written
  tracked=$( (git -C "$REPO" ls-files .evidence; git -C "$REPO" log --all --not "$(base)" --format= --name-only -- .evidence) | sort -u | paste -sd, -)
  src=$(git -C "$REPO" check-ignore -v --no-index "$f" | cut -d: -f1)
  if [ -n "$tracked" ]; then fail evidence_untracked "git tracks $tracked"
  elif [ "$src" != "$(git -C "$REPO" rev-parse --git-path info/exclude)" ]; then fail evidence_untracked "ignored by '${src:-nothing}', not info/exclude"
  else pass evidence_untracked; fi
}

run_node_tests() { perl -e 'alarm 120; exec @ARGV' node --test "$@" >/dev/null 2>&1; }

# repro_fails_before: the test files the run added or changed fail when run
# against the base's source. repro_passes_after: they pass in the final tree.
check_repro() {
  local tests tmp t
  tests=$(changed_paths | grep -E '(^test/.*|\.test)\.m?js$' | while read -r t; do [ -f "$REPO/$t" ] && echo "$t"; done)
  if [ -z "$tests" ]; then
    fail repro_fails_before "no test added or changed"; fail repro_passes_after "no test added or changed"; return
  fi
  tmp=$(mktemp -d)
  git -C "$REPO" archive "$(base)" | tar -x -C "$tmp"
  for t in $tests; do mkdir -p "$tmp/$(dirname "$t")"; cp "$REPO/$t" "$tmp/$t"; done
  # shellcheck disable=SC2086
  if (cd "$tmp" && run_node_tests $tests); then fail repro_fails_before "$(echo $tests) pass on the base"; else pass repro_fails_before; fi
  # shellcheck disable=SC2086
  if (cd "$REPO" && run_node_tests $tests); then pass repro_passes_after; else fail repro_passes_after "$(echo $tests) fail after the change"; fi
  rm -rf "$tmp"
}

# before_captured: the run saw the code without its fix run: a test run or a
# node script before its first edit to src/, or one with src/ put back to the
# base (git stash, a checkout or restore of src/, a worktree) after it.
check_before_first() {
  if tool_uses | jq -e -s '
      def cmd: .input.command // "";
      def EDIT: "(sed -i|perl -[a-z]*i)[^\\n]*src/|tee [^|;&\\n]*src/|>>? *(\\./)?src/|python[0-9]*[\\s\\S]*src/[\\s\\S]*(write|replace)|writeFileSync\\([^)]*src/";
      def RUN: "node (--test|-e|--input-type|[^ -][^ ]*\\.m?js)|npm (run )?test|npm t\\b|\\bsh [^ ]+\\.sh";
      def at(re): [cmd | match(re)][0].offset;
      def edits_src: ((.name | test("^(Edit|Write|MultiEdit)$")) and (.input.file_path // "" | test("(^|/)src/")))
        or (.name == "Bash" and at(EDIT) != null);
      def runs_code: .name == "Bash" and at(RUN) != null;
      def runs_before_edit: .name == "Bash" and at(RUN) != null and at(EDIT) != null and at(RUN) < at(EDIT);
      def restores_base: .name == "Bash"
        and (cmd | test("git stash($|[ \\n;&|]+(-q|-u|push|--|[;&|\\n]|$))|git (checkout|restore)[^\\n]*src/|git worktree add"));
      (map(edits_src) | index(true)) as $edit
      | ($edit != null and (any(.[:$edit][]; runs_code) or (.[$edit] | runs_before_edit)))
        or (any(.[]; restores_base and runs_code))
        or ((map(restores_base) | index(true)) as $r | $r != null and any(.[$r + 1:][]; runs_code))' >/dev/null; then
    pass before_captured
  else
    fail before_captured "no test or CLI run on the code without the fix"
  fi
}

# What counts as asking the user, read from the final reply (code removed):
# - a question: a sentence ending in "?" that is not an offer ("want me to",
#   "shall I", "would you like me to"); one line per paragraph or top-level
#   list item holding one, so the topic can be read from the whole item;
# - a request: a "Needs you" paragraph that asks for something (confirm, decide,
#   choose, say, answer...) and each numbered item after it, or every numbered
#   item when that paragraph sends the user to them ("answer questions 1 and 2");
#   and any numbered item that gives a recommendation, the skill's question shape.
# An AskUserQuestion call counts as a question too.
OFFER='(want me to|shall I|would you like me to|do you want me to)\b'
asks() { # asks question|request
  final_text | OFFER=$OFFER KIND=$1 perl -0ne '
    s/```.*?```//gs;
    my $needs = 0;
    my $all = /needs you[^\n]*\b(answer|questions?)\b/i;
    for my $item (split /\n[ \t]*\n|\n(?=(?:\d+[.)]|[-*+])\s)/) {
      (my $flat = $item) =~ s/\s*\n\s*/ /g; $flat =~ s/^\s+//;
      my $numbered = $flat =~ /^\d+[.)]\s/;
      if ($flat =~ /needs you/i) { $needs = $flat =~ /\b(confirm|decide|choose|pick|say|tell|answer|approve|prefer|rather|overturn|let me know)\b/i }
      elsif (!$numbered) { $needs = 0 }
      (my $plain = $flat) =~ s/`[^`]*`//g;
      my @q = grep { !/$ENV{OFFER}/i } ($plain =~ /([^.!?]*\?)/g);
      print "$flat\n" if $ENV{KIND} eq "question" ? @q : ($needs or ($numbered and ($all or $flat =~ /recommend/i)));
    }'
  [ "$1" = question ] && tool_uses | jq -r 'select(.name=="AskUserQuestion") | .input.questions[]? | "\(.question) \([.options[]?.label] | join(" / "))"'
  return 0
}

# no_needless_questions [regex]: every question is about what the regex names
# (the costly choice, or a defect the run found and left out of the change), or
# states the choice already made or offers to change it ("I went with", "if
# you'd rather"): a decision offered for overturn, which the skill asks for.
DECIDED="\\bI (went with|picked|chose|used|kept|made it|set it|defaulted)\\b|if you'?d rather|if you prefer|one-line change|easy to change"
check_no_needless_questions() {
  local needless
  needless=$(asks question | grep -Eiv "$DECIDED" | { if [ -n "${1:-}" ]; then grep -Eiv "$1"; else cat; fi; } || true)
  if [ -z "$needless" ]; then pass no_needless_questions; else fail no_needless_questions "asked: $(printf '%s' "$needless" | head -2 | cut -c1-160 | paste -sd'|' -)"; fi
}

# asked_costly_choice <regex of the costly topic>: a question or request is about it.
check_asked_costly() {
  if { asks question; asks request; } | grep -Eiq "$1"; then pass asked_costly_choice; else fail asked_costly_choice "no question or Needs you item matched /$1/"; fi
}

# report_shape: the final reply is the skill's report: a result paragraph, a
# Needs you line (or numbered questions, when it stopped to ask), a link to .evidence/<change>/evidence.md or a PR, none of the
# sections the skill calls wrong, no test counts, and short enough for one screen.
check_report_shape() {
  local r problems="" n section
  r=$(final_text)
  if [ -z "$r" ]; then fail report_shape "no final reply"; return; fi
  printf '%s\n' "$r" | perl -00 -ne '$n++ if !/^\s*([-*+]|\d+[.)])\s/ && !/needs you|^\W*risks|evidence\.md|\/pull\/\d/i; END { exit !$n }' \
    || problems="$problems; no result paragraph"
  printf '%s' "$r" | grep -qi 'needs you' || [ -n "$(asks request)" ] || problems="$problems; no Needs you line"
  printf '%s' "$r" | grep -Eq '\.evidence/[^[:space:]]+/evidence\.md|/pull/[0-9]' || problems="$problems; no link to .evidence/<change>/evidence.md or a PR"
  section=$(printf '%s\n' "$r" | grep -v 'evidence\.md' \
    | grep -Eio '^[[:space:]]*([-*][[:space:]]+)?(#+[[:space:]]*)?(\*\*)?(Changed|Changes|What changed|What I changed|Evidence|Decisions?|Decisions made|Not done|Files changed|Summary|Verification|Testing|Tests)(\*\*)?[[:space:]]*(:|$)' \
    | head -1 | sed -E 's/^[[:space:]#*-]+//; s/[*:[:space:]]+$//')
  [ -z "$section" ] || problems="$problems; has a '$section' section"
  printf '%s' "$r" | grep -Eiq '\b[0-9]+ (unit |new |existing |passing |regression )?(tests?|specs?)\b|\b[0-9]+/[0-9]+ (tests? )?pass|\b[0-9]+ passing\b|tests? \([0-9]+( of [0-9]+)?\)|\b[0-9]+ of [0-9]+ (tests?|pass)' \
    && problems="$problems; states a test count"
  n=$(printf '%s\n' "$r" | grep -c '[^[:space:]]')
  [ "$n" -le 20 ] || problems="$problems; $n lines"
  if [ -z "$problems" ]; then pass report_shape; else fail report_shape "${problems#; }"; fi
}

check_ci_ran() {
  check_ran ran_tests '(npm (run )?(-s |--silent )?test|npm t( |$)|node --test)'
  check_ran ran_lint '(npm (run )?(-s |--silent )?lint|node scripts/lint)'
}
