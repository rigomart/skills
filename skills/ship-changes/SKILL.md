---
name: ship-changes
description: Branch, commit, push and open a PR or a stack in the project's conventions, then land it. Use when asked to ship, commit, push, open or land a PR, or prepare work for review.
---

# Ship Changes

## Read the project first

Before shipping, learn the project's own rules and follow them over the defaults here:

- `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`: commit style, PR rules, required checks, anything they ask you to surface in a PR.
- A PR template: `.github/pull_request_template.md`, `.github/PULL_REQUEST_TEMPLATE/`, `PULL_REQUEST_TEMPLATE.md`, or `docs/PULL_REQUEST_TEMPLATE.md`.
- `git log --oneline -20`: the commit convention actually in use.
- The CI workflows (`.github/workflows/*.yml` or the project's CI config): the commands a PR must pass.
- The default branch: `gh repo view --json defaultBranchRef --jq .defaultBranchRef.name`. This skill calls it `main`.

## Branch Naming

Branch names should be short, lowercase, hyphenated, and based on the actual change. If an issue number is central, include it after the topic, not as the whole name.

```text
items-inline-editing
fix-inbox-count-optimism
docs-agent-dev-server-rules
items-inline-editing-135
```

## Branch Creation

First inspect the current branch and worktree state:

```bash
git status --short
git branch --show-current
git rev-parse --show-toplevel
```

When working in a worktree, do not assume the branch should be based on `main`. Treat the checked-out worktree branch as the base unless the user explicitly asks to rebase, retarget, or start over from `main`.

Part of the branch may already have landed through a squash merge, which `git log origin/main..HEAD` still lists. Check each commit ahead of `main` with `gh pr list --state merged --search <sha>`. When the lower ones already merged, put only the rest on a new descriptive branch from `origin/main` with `git rebase --onto origin/main <last-merged-sha> <new-branch>`, and leave the worktree's branch as it is.

If the current branch is already a descriptive feature branch for the work being shipped, keep using it. If it is `main`, `master`, or any name that isn't about the change, such as one a tool generated (`t3/fe15b4fb`, `claude/…`, `codex/…`) or a generic one (`wip`, `fix`), create a new descriptive branch from the current `HEAD`:

```bash
git switch -c <descriptive-branch-name>
```

Do not move, reset, or recreate the worktree from `main` just to make a shipping branch. Only change the base when the user asks or when the current branch clearly cannot be pushed or used for a PR.

## One PR or a Stack

Default to one PR. Split into a stack only when the work has a seam a reviewer would review separately, and each piece is useful on its own:

- a migration, then the API that uses it, then the UI
- a refactor, then the feature it makes room for
- a contract change, then its callers

When the work splits, follow [references/stack.md](references/stack.md).

## Verification

Before committing, run the `comments` skill on the diff if it is installed, alongside any review the project runs before a commit.

The head you push passes what CI runs: the lint, format, typecheck, build, and test commands from the CI workflows, each run on its own through the project's package scripts or task runner. A build that skips tests does not prove they type-check. A green run of those commands earlier in the session counts; rerun only what the edits since then can break (after a comments-only edit, lint and format).

A user-visible change also needs proof in the real app, which lint and tests don't give. When the work already saved evidence (an `evidence.md` and its artifacts, under `.evidence/` or the verification skill's folder), build the PR from it: its images go in Screenshots, its numbers in Measurements, its repro in Verification. Retake an image only when a later commit changed what it shows. When there is none, capture it with the `implement` skill if it is installed, or the project's verification skill.

## Commit Strategy

Use one commit when the changes form one coherent feature or fix. Use multiple commits when changes are independently reviewable, such as production code plus a docs-only policy change, a refactor before a feature, or unrelated fixes discovered during the work.

Every commit uses the project's commit style. When the project has none, use Conventional Commits. Before committing, confirm the staged diff only contains intended files.

```text
feat(items): add inline item editing
fix(inbox): keep optimistic count in sync
docs(agents): document local dev server policy
refactor(items): extract date update hook
```

## PR Format

Use a conventional PR title matching the main commit or the overall change. Open every PR ready for review, never as a draft.

```text
feat(items): add inline item editing
```

The body is a briefing for a reviewer who has the diff. The title's type picks its template; open that file before writing the body. When the project doesn't use Conventional Commits, use the type the change would get under them. A change that mixes types takes the title's type, which already names the main change.

| Title type | Template |
| --- | --- |
| `feat`, or a type not listed | [feature.md](references/pr-templates/feature.md) |
| `fix` | [fix.md](references/pr-templates/fix.md) |
| `refactor` | [refactor.md](references/pr-templates/refactor.md) |
| `perf` | [performance.md](references/pr-templates/performance.md) |
| `docs` | [docs.md](references/pr-templates/docs.md) |
| `chore`, `ci`, `build`, `test`, `style` | [maintenance.md](references/pr-templates/maintenance.md) |
| `revert` | [revert.md](references/pr-templates/revert.md) |

When the project has its own PR template, its headings replace these; fill them with what the type's template asks for.

Every template, in every PR:

- Write each section the template has; don't add or drop any. Screenshots is the one conditional section, and its template says when.
- No `## Summary` or `## Test plan` boilerplate, file-by-file lists, or SHAs. If a command was not run, say why instead of listing it.
- Compromises, including any the project's agent instructions ask you to surface, go in Tradeoffs, Fix, or Blast radius, whichever the template has.
- Run the `unslop` skill on the title, the body and each commit message body if it is installed, before you commit or open the PR.
- End with the closing issue reference when the work is issue-backed (see Closing issues).

### Screenshots

A change a user can see carries images in its PR: UI, layout, styling, copy, icons, an app's or a TUI's screens. A `fix` carries them only when the symptom shows on screen. CLI output goes in a text block of the real output instead, which a reviewer can search and diff.

Take, check, and attach them as [references/screenshots.md](references/screenshots.md) says.

### Closing issues

The PR body must reference the issue it closes when the work is tied to an issue. Look for the issue number in the session context, the user's request, branch name, commit messages, recent issue discussion, or the diff itself.

Use GitHub closing syntax, such as `Closes #123`, so merging the PR closes the issue automatically. If an issue appears relevant but cannot be identified, ask the user before creating the PR instead of guessing. If the change is clearly not issue-backed, such as a small agent-instruction cleanup requested directly in chat, omit the closing line and continue creating the PR.

## Landing

Opening a PR does not merge it. Land only when the user asks to merge or land it; "ship it" asks for the PR. When asked, follow [references/landing.md](references/landing.md), or [references/stack.md](references/stack.md) for a stack.

## Report

The PR link, one per layer for a stack; its branch and head; the images attached, or why a visible change has none; and whether auto-merge is armed.
