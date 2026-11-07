# On main, where `tasks list` prints "undefined" for each title (a typo, t.titel), next to where a count command would go.
source "$EVAL_HERE/implement/lib.sh"
make_tasks_repo
seed_gh_state
cd "$REPO"
perl -0pi -e 's/console\.log\(`#\$\{t\.id\} \$\{t\.title\}`\)/console.log(`#\${t.id} \${t.titel}`)/' src/cli.mjs
grep -q 't.titel' src/cli.mjs
commit_base "refactor: tidy the list output"
