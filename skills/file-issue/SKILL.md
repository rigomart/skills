---
name: file-issue
description: Write and file GitHub issues the way the repo tracks work, from a bug or a parked idea to a spec split into sub-issues. Use when asked to file, open or create an issue, or to park a follow-up or a plan as issues.
---

# File an issue

An issue is read later by someone, usually an agent, who has the repo but not this conversation. Write it so they can start from it alone, in the repo's own conventions.

When the user asks for issues, file them. When another skill proposes them (the `implement` skill's issue candidates), list them first, one line each, and file the ones the user picks.

## 1. Read the tracker

Learn the repo's conventions before writing anything:

- **Its docs:** `AGENTS.md`, `CONTRIBUTING.md`, `docs/agents/` (an issue-tracker or labels file), `.github/ISSUE_TEMPLATE/`.
- **Its labels:** `gh label list`, and what each one means: a type per issue, a label for work ready to pick up, labels only tooling applies.
- **Its recent issues:** `gh issue list --state all --limit 10`, then read two or three for title style, sections and labels.
- **Its visibility:** `gh repo view --json nameWithOwner,visibility`.

Use only the labels the repo has; never create one. With no written scheme, follow what recent issues do.

Done when you can name the repo, whether it is public, the label for each issue you will file, and the title style.

## 2. Search for duplicates

Search open and closed issues with the terms the user would use: `gh issue list --state all --search "<terms>"`. A clear duplicate gets a comment with what is new instead of a new issue. A related issue gets a link from the new one. A closed issue that matches a new bug is a regression: link it.

Done when each planned issue is marked new, or names the issue it updates.

## 3. Size and group

One issue per future pull request. Work too big for one PR becomes a spec with one sub-issue per slice, in delivery order, each landable and checkable on its own. When the user groups or splits items, their grouping wins.

Done when each planned issue has a title, a kind, a label, and its parent and blockers if any.

## 4. Write

Each kind has its shape in [references/kinds.md](references/kinds.md): bug, task, idea, spec with slices, and an update comment. Across all of them:

- **What and why, not how.** Describe the behavior the user sees and the reason. Record a technical choice only when it was settled and binds the work: a storage choice, an ADR it amends, a contract it changes.
- **Name things by their terms, not their paths.** Use the glossary's terms, feature names, routes, commands and component names; the reader finds the files from those, and paths go stale within days. A path belongs in an issue only when it is the decision: a module to create, a structure to follow, a document to link.
- **A check anyone can run.** Every task and slice ends with **You see**: the action in the real product, then the screen state or output that follows.
- **Keep the user's life out.** Ideas often start from something personal (a relative's health, money, an employer). Write only generic cases ("a relative's chronic condition", "an evening check-in"): no family members, conditions, names, places or anything that points at the user. If a personal case seems necessary, ask first.

Done when you have reread every body for personal details, and every task and slice has a **You see**.

## 5. File

Write each body to a file with your file tool, then run one plain command per issue from the repo root:

```bash
gh issue create --title "<title>" --label <label> --body-file <file> [--parent <spec>] [--blocked-by <n>]
```

A heredoc or a shell variable in the command breaks on quoting and some sandboxes refuse it; the body file avoids both. File a spec before its slices, and the slices in delivery order, each with `--parent`. Pass `--type` only when the repo uses issue types. A comment on an existing issue goes through `gh issue comment <n> --body-file <file>`.

Done when `gh issue view <spec> --json subIssues,blockedBy` lists every slice, or each issue's URL came back.

## 6. Report

One line per issue: number, title, label. Then the issues you commented on instead of filing, and anything you left out and why.
