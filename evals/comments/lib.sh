# lib.sh: setup and check helpers shared by the comments scenarios.
# setup.sh and check.sh source it from "$EVAL_HERE/comments/lib.sh".

# The tasks repo plus what the scenarios lean on: a lint rule with an ignore
# directive, a package entry point (so exports are public API), and comments on
# lines no scenario touches, which must survive.
make_comments_repo() {
  make_tasks_repo
  seed_gh_state
  cd "$REPO" || return 1
  cat > scripts/lint.mjs <<'EOF'
// Fails on trailing whitespace, lines over 100 characters and console.log outside the CLI entry point.
// "// lint-ignore-next-line <rule>" turns one rule off for the next line.
import { readdirSync, readFileSync } from "node:fs";
import { join } from "node:path";

const rules = {
  "trailing-whitespace": (line) => /\s+$/.test(line),
  "max-len": (line) => line.length > 100,
  "no-console": (line, path) => /console\.log/.test(line) && path !== join("src", "cli.mjs"),
};

let problems = 0;
for (const dir of ["src", "test"]) {
  let files = [];
  try { files = readdirSync(dir).filter((f) => f.endsWith(".mjs")); } catch { continue; }
  for (const f of files) {
    const path = join(dir, f);
    const lines = readFileSync(path, "utf8").split("\n");
    lines.forEach((line, i) => {
      const ignored = (lines[i - 1] ?? "").match(/lint-ignore-next-line ([\w-]+)/)?.[1];
      for (const [rule, broken] of Object.entries(rules)) {
        if (rule !== ignored && broken(line, path)) { console.error(`${path}:${i + 1}: ${rule}`); problems++; }
      }
    });
  }
}
if (problems) process.exit(1);
console.log("lint: ok");
EOF
  perl -0pi -e 's/  "type": "module",\n/  "type": "module",\n  "exports": { ".": ".\/src\/tasks.mjs", ".\/store": ".\/src\/store.mjs" },\n/' package.json
  perl -0pi -e 's/(\n  return list\.map)/\n  \/\/ mark the matching task done$1/; s/(\nexport function listTasks)/\n\/\/ Open tasks, in the order they were added.$1/' src/tasks.mjs
  perl -0pi -e 's/(\nconst \[command)/\n\/\/ first argument is the command, the rest are its arguments$1/' src/cli.mjs
  commit "chore: lint line length and export the task API"
  git push -q origin main 2>/dev/null
}

# Copy the seeded working tree next to the repo, so check.sh can tell comment
# edits from code edits.
snapshot_seed() {
  local dest; dest="$(dirname "$REPO")/seeded"
  mkdir -p "$dest"
  (cd "$REPO" && tar --exclude=.git -cf - .) | (cd "$dest" && tar -xf -)
}

# A JS file with its comments, blank lines and trailing spaces removed. A "//"
# right after a non-space character is kept, so a URL in a string still counts
# as code; a "/*" inside a string would still be stripped.
code_only() {
  perl -0pe 's{/\*.*?\*/}{}gs; s{(^|[ \t])//[^\n]*}{$1}mg; s/[ \t]+$//mg; s/\n\s*\n/\n/g; s/^\s+//' "$1"
}

repo_files() { (cd "$1" && find . -type f -not -path './.git/*' -not -path './.claude/*' | sed 's|^\./||' | sort); }

# check_no_code_edits: every file matches its seeded copy once comments are stripped.
check_no_code_edits() {
  local seed changed="" f
  seed="$(dirname "$REPO")/seeded"
  for f in $( (repo_files "$seed"; repo_files "$REPO") | sort -u); do
    if [ ! -f "$seed/$f" ]; then changed="$changed $f(new)"; continue; fi
    if [ ! -f "$REPO/$f" ]; then changed="$changed $f(deleted)"; continue; fi
    case "$f" in
      *.mjs|*.js) [ "$(code_only "$seed/$f")" = "$(code_only "$REPO/$f")" ] || changed="$changed $f" ;;
      *) cmp -s "$seed/$f" "$REPO/$f" || changed="$changed $f" ;;
    esac
  done
  if [ -z "$changed" ]; then pass no_code_edits; else fail no_code_edits "code changed in${changed}"; fi
}

# comment_above <file> <anchor ERE>: the last non-blank line before the first
# line matching the anchor. Exits 2 when no line matches. The anchor goes in
# through the environment because awk -v would eat its backslashes.
comment_above() {
  ANCHOR=$2 awk '$0 ~ ENVIRON["ANCHOR"] { print prev; found = 1; exit } NF { prev = $0 } END { exit found ? 0 : 2 }' "$1"
}
is_comment() { printf '%s' "$1" | grep -Eq '^[[:space:]]*(//|/[*]|[*])'; }

# check_comments <bad|good> <labels>: each label line is
# "<file><TAB><kind><TAB><text ERE or -><TAB><anchor ERE or ->".
# A bad comment is removed when its text is gone from the file and no comment
# sits right above its anchor, so rewording it does not count. A good comment
# is kept when its text is still there and a comment still sits right above its
# anchor, so tightening it does.
check_comments() {
  local want=$1 total=0 ok=0 missed="" file kind text anchor above has_text has_comment good
  while IFS=$'\t' read -r file kind text anchor; do
    [ -n "$file" ] || continue
    total=$((total + 1))
    has_text=0; has_comment=0
    if [ "$text" != - ] && grep -Eq -e "$text" "$REPO/$file" 2>/dev/null; then has_text=1; fi
    if [ "$anchor" != - ]; then
      if ! above=$(comment_above "$REPO/$file" "$anchor" 2>/dev/null); then missed="$missed $kind($file:no-anchor)"; continue; fi
      is_comment "$above" && has_comment=1
    fi
    [ "$text" = - ] && [ "$want" = good ] && has_text=1
    [ "$anchor" = - ] && [ "$want" = good ] && has_comment=1
    if [ "$want" = bad ]; then good=$(( !has_text && !has_comment )); else good=$(( has_text && has_comment )); fi
    if [ "$good" = 1 ]; then ok=$((ok + 1)); else missed="$missed $kind($file)"; fi
  done <<<"$2"
  local name=good_kept word=lost
  if [ "$want" = bad ]; then name=bad_removed word=left; fi
  if [ "$ok" = "$total" ]; then pass "$name"; else fail "$name" "$ok/$total; $word:$missed"; fi
}

model_rank() { case "$1" in *haiku*) echo 1 ;; *sonnet*) echo 2 ;; *opus*) echo 3 ;; *fable*) echo 4 ;; *) echo 0 ;; esac; }

# check_checker: a subagent got the checker brief from references/checker.md,
# and no subagent ran on a model above the session's. A spawn that names no
# model runs on the session's model.
check_checker() {
  local session above m
  if subagent_spawns | jq -e -s 'any(.[]; (.prompt // "") | contains("When you are unsure whether a comment fits, it does not.") and contains("Add nothing beyond the findings."))' >/dev/null; then
    pass checker_spawned
  else
    fail checker_spawned "no subagent got the checker brief from references/checker.md ($(subagent_spawns | wc -l | tr -d ' ') spawns)"
  fi
  session=$(model_rank "$EVAL_MODEL")
  above=$(subagent_models | while read -r m; do
    [ "$m" = unset ] && continue
    [ "$(model_rank "$m")" -gt "$session" ] && echo "$m"
  done | paste -sd, -)
  if [ -z "$above" ]; then pass checker_not_above_session; else fail checker_not_above_session "spawned on $above, session is $EVAL_MODEL"; fi
}
