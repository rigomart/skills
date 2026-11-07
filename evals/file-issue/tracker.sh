# Sourced by a scenario's setup.sh after evals/lib/fixture.sh.

make_tracked_repo() {
  make_tasks_repo
  seed_gh_state
  mkdir -p "$REPO/docs/agents"
  cat > "$REPO/docs/agents/issue-tracker.md" <<'EOF'
# Issue tracker

Issues live on GitHub, in acme/tasks. Each issue gets one type label:

- `bug`: something that worked, or should work, and doesn't.
- `enhancement`: one change, landable in one pull request.
- `spec`: a plan too big for one pull request; its slices are sub-issues.
- `idea`: a problem worth solving that is not ready to build.
- `documentation`: docs only.

`dependencies` is applied by Dependabot; don't add it by hand.
EOF
  commit "docs: describe the issue tracker"
  git -C "$REPO" push -q origin main 2>/dev/null
  gh_state '.labels = [
    {"name": "bug", "description": "Something is not working", "color": "d73a4a"},
    {"name": "enhancement", "description": "One change, landable in one PR", "color": "a2eeef"},
    {"name": "spec", "description": "A plan split into sub-issues", "color": "5319e7"},
    {"name": "idea", "description": "Parked, not ready to build", "color": "fbca04"},
    {"name": "documentation", "description": "Improvements or additions to documentation", "color": "0075ca"},
    {"name": "dependencies", "description": "Applied by Dependabot", "color": "0366d6"}
  ]'
  gh_state '.issues = {
    "3": {"title": "Adding a task with an empty title saves a blank task", "state": "CLOSED", "labels": ["bug"],
      "body": "## What happens\n\n`tasks add` with no title saves a task with an empty title, which shows up in `tasks list` as `#1 `.\n\n## Steps\n\n1. Run `tasks add` with no title.\n2. Run `tasks list`.\n\n## Expected\n\n`tasks add` refuses an empty title.\n\n## Actual\n\nA blank task `#1 ` is listed.\n"},
    "5": {"title": "Add `tasks done` to complete a task", "state": "CLOSED", "labels": ["enhancement"],
      "body": "## What changes\n\nThere is no way to finish a task. `tasks done <id>` marks it complete, and it leaves the list.\n\n## Out of scope\n\nUndoing a completion.\n\n## You see\n\n`tasks done 1` prints `done #1`, and `tasks list` no longer shows #1.\n"},
    "8": {"title": "Show completed tasks in `tasks list`", "state": "OPEN", "labels": ["enhancement"],
      "body": "## What changes\n\nOnce a task is done it disappears from `tasks list`, so there is no way to see what was finished this week. Let `tasks list` show done tasks as well, told apart from pending ones.\n\n## Out of scope\n\nDeleting done tasks.\n\n## You see\n\nAfter `tasks done 1`, `tasks list` can still show #1, marked as done.\n"},
    "9": {"title": "Sync tasks between machines", "state": "OPEN", "labels": ["idea"],
      "body": "## Problem\n\nThe task list lives in one file on one machine, so tasks added on a laptop are missing on the desktop.\n\n## Angles\n\n- Point `TASKS_FILE` at a synced folder.\n- A small sync server.\n\n## Open questions\n\n- What happens when both machines change the same task?\n\n## Would unpark it\n\nThree users asking for it.\n"},
    "10": {"title": "Spec: tags on tasks", "state": "OPEN", "labels": ["spec"],
      "body": "## Problem\n\nA long list has no way to group tasks, so work and home tasks mix.\n\n## Shape\n\nTasks carry tags, and `tasks list` filters by them.\n\n```text\n$ tasks list --tag work\n#2 Write the release notes [work]\n```\n\n## Decisions\n\n- A task can have several tags.\n\n## Out of scope\n\nNested tags.\n"},
    "11": {"title": "Add tags with `tasks add --tag`", "state": "OPEN", "labels": ["enhancement"], "parent": 10,
      "body": "## What changes\n\n`tasks add --tag work <title>` stores the tag on the task.\n\n## Depends on\n\nNothing.\n\n## Out of scope\n\nFiltering by tag.\n\n## You see\n\n`tasks add --tag work Write notes` prints `added #3 Write notes [work]`.\n"},
    "12": {"title": "Document the TASKS_FILE variable", "state": "OPEN", "labels": ["documentation"],
      "body": "## What changes\n\nThe README never mentions `TASKS_FILE`, so nobody knows the list can live somewhere other than the home folder.\n\n## You see\n\nThe README has a section on `TASKS_FILE` with an example.\n"}
  }'
}
