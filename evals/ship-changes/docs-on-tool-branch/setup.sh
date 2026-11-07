# On a tool-generated branch name with an uncommitted docs-only change.
make_tasks_repo
seed_gh_state
cd "$REPO"
git switch -q -c claude/brave-lovelace-7f3a
cat >> README.md <<'EOF'

## Storage

Tasks live in `~/.tasks.json`. Set `TASKS_FILE` to keep a separate list, for example one per project:

```bash
TASKS_FILE=.tasks.json tasks list
```

## Exit codes

- `0`: the command ran.
- `2`: unknown command; the usage line is printed.
EOF
