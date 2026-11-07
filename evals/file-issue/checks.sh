# Sourced by each check.sh after evals/lib/checks.sh.

# Issues filed during the run, as JSON lines in filing order, with their number.
filed_issues() {
  jq -c '.issues // {} | to_entries | map(select(.value.filed) | .value + {number: (.key | tonumber)})
    | sort_by(.filed) | .[]' "$EVAL_GH_STATE/state.json"
}
issue_field() { jq -r --arg n "$1" ".issues[\$n] | $2" "$EVAL_GH_STATE/state.json"; }
# Each gh call, help calls left out: the logged JSON, or just its arguments.
gh_calls_json() { jq -c 'select(any(.argv[]; . == "--help" or . == "-h") | not)' "$EVAL_GH_STATE/calls.jsonl"; }
gh_argvs() { gh_calls_json | jq -c '.argv'; }
# Label values passed to issue create and edit, one per line.
labels_used() {
  gh_argvs | jq -r 'select(.[0]=="issue" and (.[1]=="create" or .[1]=="edit")) | . as $a
    | [range(0; length) as $i | $a[$i] as $x
       | if ($x=="--label" or $x=="-l" or $x=="--add-label") then $a[$i+1]
         elif ($x | test("^--(add-)?label=")) then ($x | sub("^--(add-)?label="; "")) else empty end]
    | .[] | split(",")[] | gsub("^ +| +$"; "")'
}

check_labels_exist() { # every label used exists in the repo, and none was created
  local known bad
  known=$(jq -r '.labels[].name' "$EVAL_GH_STATE/state.json")
  if gh_argvs | jq -e 'select(.[0]=="label" and .[1]=="create")' >/dev/null; then
    fail labels_exist "ran gh label create"; return
  fi
  bad=$(labels_used | grep -vxF "$known" | sort -u | paste -sd, -)
  if [ -z "$bad" ]; then pass labels_exist; else fail labels_exist "used labels the repo lacks: $bad"; fi
}

check_searched_first() { # a search of open and closed issues succeeded before the first issue was filed or commented on
  local first_write first_search
  first_write=$(gh_calls_json | jq -s 'map(.argv[0]=="issue" and (.argv[1]=="create" or .argv[1]=="comment")) | index(true)')
  first_search=$(gh_calls_json | jq -s 'map(.exit == 0 and (
      (.argv[0]=="issue" and .argv[1]=="list" and any(.argv[]; test("^(--search|-S)(=|$)"))
        and (.argv | (index("--state") // index("-s")) as $i | ($i != null and .[$i+1]=="all") or any(.[]; .=="--state=all")))
      or (.argv[0]=="search" and .argv[1]=="issues" and (any(.argv[]; test("^--state")) | not)))) | index(true)')
  if [ "$first_search" = null ]; then fail searched_first "no successful search of open and closed issues"
  elif [ "$first_write" != null ] && [ "$first_search" -gt "$first_write" ]; then fail searched_first "searched only after filing"
  else pass searched_first; fi
}

check_body_files() { # every issue create and comment passed its body as a file
  local n
  n=$(gh_argvs | jq -s '[.[] | select(.[0]=="issue" and (.[1]=="create" or .[1]=="comment"))
    | select(any(.[]; test("^(--body-file|-F)(=|$)")) | not)] | length')
  if [ "$n" = 0 ]; then pass body_files; else fail body_files "$n create or comment calls passed the body inline"; fi
}

check_filed_count() { # check_filed_count <n>
  local got; got=$(filed_issues | wc -l | tr -d ' ')
  expect "filed_$1" "filed $got issues" test "$got" = "$1"
}

check_reported_issues() { # the final reply names every filed issue
  local missing="" n text
  text=$(final_text)
  for n in $(filed_issues | jq -r .number); do
    printf '%s' "$text" | grep -Eq "(#|issues/)$n([^0-9]|$)" || missing="$missing #$n"
  done
  if [ -z "$missing" ]; then pass reported_issues; else fail reported_issues "final reply does not name$missing"; fi
}
