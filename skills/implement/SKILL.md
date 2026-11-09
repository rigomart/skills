---
name: implement
description: Settle a change's decisions, prove it with before and after evidence, and report it. Use before any code edit, however small, when asked to implement, build, add, fix, refactor or speed something up, or to fix an issue.
---

# Implement

How to build it is your call. This covers when to ask, what to prove, how big the change is, and the report.

## Decide, don't interview

An issue number or URL is the request: read its body and comments with `gh issue view <n> --json title,body,comments` (outside a terminal, `--comments` prints the comments only).

Settle what the code, docs, research or a quick experiment can settle, and record each choice as a decision. Ask only what none of those answer and a wrong guess would be costly to undo: a data model or public API others build on, a direction the rest of the work depends on. An optional field or argument added to one counts: once others use its shape, changing it breaks them. A choice you could change in a line later (copy, values, placeholder data, what's left out of scope) is a decision, not a question. Ask once, before building, numbered, recommendation first, and keep working on the rest. Open each question with one plain sentence on what it's about and why it matters, naming things by what they do rather than only by an issue number or internal name, and put the questions at the top of the message.

## Prove it

Proof is what you observed yourself on the real thing: a repro that fails before and passes after, before and after screenshots, the same benchmark before and after, behavior pinned through a refactor. The before is gone once you edit, so capture it first. Run what CI runs too.

For a visible change, the before and after are screenshots of the states that show the change, four at most, at the same sizes, taken with the project's `verify-<app>` skill when it has one. Add a width or a theme only when the change looks different there. Check each after image against the request before you show it (empty space, overflow, alignment, contrast), fix what you find, and capture again. Every image you view stays in your context for the rest of the session, so view each one through [scripts/shrink](scripts/shrink), run by its absolute path: it prints a copy at most 1024px on its long edge, and the original stays for the evidence and the PR. Open the original only when text in the copy is too small to judge, and don't reopen an image you already viewed. A check you couldn't run is `INCONCLUSIVE`, not a pass.

Save the artifacts and an `evidence.md` (each claim, how you checked it, its artifact; each decision made for the user and how to reverse it; what's left out and why) in `.evidence/<change>/`, excluded from git through the file `git rev-parse --git-path info/exclude` prints. Done when `evidence.md` exists and every claim the report makes can be found in it.

## Scope

The smallest change that does what was asked, on the current branch. Fix what the change can't work correctly without, and say so. Other extras you notice become issue candidates, not part of the diff.

## Report

Write it for a tech lead who didn't watch the work: where it stands and what needs them, on one screen.

1. **Result**, one or two sentences: what works now that didn't, and whether it's ready (uncommitted, PR open, blocked). Say it's better than before only with the before and after. Name the checks that passed without counting them: "tests and lint pass", not "5 tests pass". For a visible change, one after image.
2. **Needs you:** each step only the user can take, before or after merging (a merge, a secret, a migration). When there is none, write `Nothing needs you.`
3. **Risks**, up to three: what's unproven, a check that failed or couldn't run, a real review finding left unfixed. Each says what could go wrong for a user.
4. One link: the PR, or `evidence.md`.

Test counts, which checks passed, file names, review findings you fixed or dismissed, issue candidates and decisions the user is unlikely to change go in `evidence.md`, and come out when the user asks. A decision they'd plausibly overturn (a default users see, a behavior others build on) goes under **Needs you** as a question.

Wrong: `Changed`, `Evidence`, `Decisions` and `Not done` sections, with "527 tests pass" and eight decisions, before the one step the user has to take.
Right: "The installer works on macOS and Linux and refuses Alpine. Not committed yet. **Needs you:** say ship it; after merge, run the curl command once on the live site. **Risks:** not tried on an Intel Mac. Details: `.evidence/curl-installer/evidence.md`"
