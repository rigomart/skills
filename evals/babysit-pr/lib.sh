# Shared by the babysit-pr scenarios, which all babysit PR #7, whose CI runs the fixture's lint and test on each pushed commit.

PR=7

make_repo() { # the tasks repo, with the remote logging every ref update so checks can count pushes
  make_tasks_repo
  git -C "$REMOTE" config core.logAllRefUpdates always
}

# A change the PR makes: `nothing to do` when no task is pending. Touches src/cli.mjs only.
empty_hint_change() {
  perl -0pi -e 's/  for \(const t of listTasks\(list\)\) console.log\(`#\$\{t.id\} \$\{t.title\}`\);/  const pending = listTasks(list);\n  if (!pending.length) console.log("nothing to do");\n  for (const t of pending) console.log(`#\${t.id} \${t.title}`);/' src/cli.mjs
  grep -q 'nothing to do' src/cli.mjs
}

# A change the PR makes: `list` ends with how many tasks are pending, from a new countPending
# with its test. pending_count_change [filter] [debug]: the filter countPending uses, and
# whether it leaves a debug console.log behind, which lint rejects outside src/cli.mjs.
pending_count_change() {
  local filter=${1:-'!t.done'} log=""
  [ -z "${2:-}" ] || log='  console.log("countPending", pending);'$'\n'
  printf '\nexport function countPending(list) {\n  const pending = list.filter((t) => %s).length;\n%s  return pending;\n}\n' "$filter" "$log" >> src/tasks.mjs
  perl -pi -e 's/import \{ addTask, completeTask, listTasks \}/import { addTask, completeTask, countPending, listTasks }/' src/cli.mjs test/tasks.test.mjs
  perl -0pi -e 's/(  for \(const t of listTasks\(list\)\) console.log\(`#\$\{t.id\} \$\{t.title\}`\);\n)/$1  console.log(`\${countPending(list)} pending`);\n/' src/cli.mjs
  cat >> test/tasks.test.mjs <<'JS'

test("countPending counts the tasks not done", () => {
  let { list } = addTask([], "write docs");
  ({ list } = addTask(list, "ship it"));
  ({ list } = addTask(list, "tell users"));
  assert.equal(countPending(completeTask(list, 2)), 2);
});
JS
  grep -q 'countPending(list)} pending' src/cli.mjs
}

# main gains a test for an error message src/tasks.mjs does not give, so main's test check fails.
break_main_test() {
  git -C "$REPO" switch -q main
  cat >> test/tasks.test.mjs <<'JS'

test("completeTask names the missing task", () => {
  assert.throws(() => completeTask([], 9), /task 9 not found/);
});
JS
  commit "test(tasks): check the error for a missing task"
  git -C "$REPO" push -q origin main 2>/dev/null
}

# Opens PR #7 for the current branch, already pushed. CI runs stay pending for <delay> seconds
# unless watched; <flaky> maps a check to how many of its first runs fail with a network error.
open_pr() { # open_pr <title> <body> [delay] [flaky json]
  local tmp; tmp=$(mktemp)
  seed_gh_state
  jq --argjson n "$PR" --arg title "$1" --arg body "$2" --arg head "$(git -C "$REPO" branch --show-current)" \
    --argjson delay "${3:-30}" --argjson flaky "${4:-"{}"}" --arg remote "$REMOTE" --arg start "$(git -C "$REPO" rev-parse HEAD)" '
    .prs = [{number: $n, title: $title, body: $body, base: "main", head: $head, draft: false, state: "OPEN"}]
    | .next_pr = $n + 1
    | .ci = {checks: {lint: "node scripts/lint.mjs", test: "node --test"}, delay: $delay, flaky: $flaky, head_lag: 5,
             remote: $remote, start_head: $start}' "$EVAL_GH_STATE/state.json" > "$tmp" && mv "$tmp" "$EVAL_GH_STATE/state.json"
}

pr_branch() { pr_field "$PR" .head; }
remote_head() { git -C "$REMOTE" rev-parse "refs/heads/$(pr_branch)" 2>/dev/null; }
start_head() { jq -r .ci.start_head "$EVAL_GH_STATE/state.json"; }
# Updates to the PR branch on the remote after setup: pushes, and merges from gh pr update-branch.
branch_updates() { git -C "$REMOTE" reflog show --format=%H "refs/heads/$(pr_branch)" 2>/dev/null | sed 1d | wc -l | tr -d ' '; }
max_reruns() { jq '[.ci_runs[]?.jobs[].attempts] | (max // 1) - 1' "$EVAL_GH_STATE/state.json"; }
# The last reply only: a run that waited on a background command ends more than one turn.
last_reply() { jq -rs 'map(select(.type=="result")) | last | .result // ""' "$TRANSCRIPT"; }
head_passes() { # head_passes <command>: the command passes on the PR head's tree
  local d r; d=$(mktemp -d)
  git -C "$REMOTE" archive "$(remote_head)" | tar -x -C "$d"
  (cd "$d" && sh -c "$1") >/dev/null 2>&1; r=$?
  rm -rf "$d"; return $r
}

# Bash commands that run wait-green, as opposed to only reading it with cat or head.
wait_green_runs() {
  bash_cmds_oneline | perl -ne 'for my $part (split /;|&&|\|\||\|/) {
    if ($part =~ /wait-green/ && $part !~ /^\s*(cat|head|tail|less|more|sed|grep|rg|ls|wc|file|stat|chmod|test|\[)\b/) { print; last } }'
}
bash_cmds_oneline() { tool_uses | jq -r 'select(.name=="Bash") | .input.command | gsub("\n"; " ")'; }
# The last reply with any "not ready for your review" (or "isn't ready ...") taken out, to look for a claim that it is ready.
claims_ready() { last_reply | perl -0pe "s/\\b(not|isn't|isn’t)\\s+ready for your review//gi" | grep -iq 'ready for your review'; }

# Tools that wake the agent later: a wakeup it schedules is a polling loop too.
own_wakeups() { tool_uses | jq -r 'select((.name | test("^(ScheduleWakeup|CronCreate|Monitor)$")) and (.input.stop != true)) | .name'; }

check_no_own_wait() { # no sleep, polling loop, scheduled wakeup or watch of its own instead of wait-green
  local own
  own=$(bash_cmds | grep -E '(^|[^[:alnum:]_-])sleep[[:space:]]+[0-9]|(^|[;&|({[:space:]])(while|until)[[:space:]]|--watch|gh run watch' | head -1)
  own=${own:-$(own_wakeups | head -1)}
  if [ -z "$own" ]; then pass no_own_wait; else fail no_own_wait "ran: $(printf '%s' "$own" | tr '\n' ' ' | cut -c1-120)"; fi
}

# Each part of each Bash command, in the order they ran: "wait" for a wait-green run, "change" for a
# push, branch update or rerun, "other" for the rest.
command_parts() {
  bash_cmds_oneline | perl -ne 'for my $part (split /;|&&|\|\||\|/) {
    if ($part =~ /wait-green/) { print $part =~ /^\s*(cat|head|tail|less|more|sed|grep|rg|ls|wc|file|stat|chmod|test|\[)\b/ ? "other\n" : "wait\n" }
    elsif ($part =~ /git push|update-branch|gh run rerun/) { print "change\n" } else { print "other\n" } }'
}

check_waited_after_change() { # a wait-green started after the last push, branch update or rerun
  local parts change wait
  parts=$(command_parts)
  change=$(printf '%s\n' "$parts" | grep -nx change | tail -1 | cut -d: -f1)
  wait=$(printf '%s\n' "$parts" | grep -nx wait | tail -1 | cut -d: -f1)
  if [ -z "$wait" ]; then fail waited_after_change "never ran wait-green"
  elif [ "$wait" -gt "${change:-0}" ]; then pass waited_after_change
  else fail waited_after_change "the last wait-green ran before the last push, branch update or rerun"; fi
}

check_reruns() { # at most one rerun per check
  local n; n=$(max_reruns)
  if [ "$n" -le 1 ]; then pass one_rerun_per_check; else fail one_rerun_per_check "a check was rerun $n times"; fi
}

check_no_force_push() {
  local prev="" sha forced=""
  for sha in $(git -C "$REMOTE" reflog show --format=%H "refs/heads/$(pr_branch)" | awk '{a[NR]=$0} END {for (i = NR; i > 0; i--) print a[i]}'); do
    [ -n "$prev" ] && ! git -C "$REMOTE" merge-base --is-ancestor "$prev" "$sha" && forced="$prev -> $sha"
    prev=$sha
  done
  if [ -z "$forced" ]; then pass no_force_push; else fail no_force_push "rewrote $forced"; fi
}

check_no_push() { # fixed nothing: the PR branch is where setup left it
  local n; n=$(branch_updates)
  if [ "$n" = 0 ]; then pass no_push; else fail no_push "the PR branch changed $n time(s)"; fi
}

check_one_push() { # every known fix went out in one push
  local n; n=$(branch_updates)
  if [ "$n" = 1 ]; then pass one_push; else fail one_push "the PR branch changed $n time(s)"; fi
}

check_read_failed_log() { check_ran read_failed_log 'gh run view .*--log|gh api .*/logs'; }

# CI finished green on the PR branch's latest commit.
head_green() {
  jq -e --arg sha "$(remote_head)" '[.ci_runs[]? | select(.sha == $sha)] | last
    | . != null and all(.jobs[]; .status == "completed" and .conclusion == "success")' "$EVAL_GH_STATE/state.json" >/dev/null
}

check_handed_back_ready() {
  local r; r=$(last_reply)
  if ! printf '%s' "$r" | grep -q "acme/tasks/pull/$PR"; then fail handed_back_ready "final reply has no link to PR #$PR"
  elif ! claims_ready; then fail handed_back_ready "final reply does not say 'ready for your review'"
  elif ! head_green; then fail handed_back_ready "called it ready before CI passed on $(remote_head | cut -c1-7)"
  else pass handed_back_ready; fi
}
