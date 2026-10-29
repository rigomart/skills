---
name: implement
description: Settle a change's decisions, prove it with before and after evidence, and report it. Use when asked to implement, build, fix, refactor or speed something up.
---

# Implement

How to build it is your call. This covers when to ask, what to prove, how big the change is, and the report.

## Decide, don't interview

An issue number or URL is the request: read it with its comments (`gh issue view <n> --comments`).

Settle what the code, docs, research or a quick experiment can settle, and record each choice as a decision. Ask only what none of those answer and a wrong guess would be costly to undo: a data model or public API others build on, a direction the rest of the work depends on. A choice you could change in a line later (copy, values, placeholder data, what's left out of scope) is a decision, not a question. Ask once, before building, numbered, recommendation first, and keep working on the rest.

## Prove it

Proof is what you observed yourself on the real thing: a repro that fails before and passes after, before and after screenshots, the same benchmark before and after, behavior pinned through a refactor. The before is gone once you edit, so capture it first. Run what CI runs too.

For a visible change, the before and after are screenshots of every screen and state the change touches, at the same sizes, taken with the project's `verify-<app>` skill when it has one. Check each after image against the request before you show it (empty space, overflow, alignment, contrast in each theme), fix what you find, and capture again. A check you couldn't run is `INCONCLUSIVE`, not a pass.

Save the artifacts and an `evidence.md` (each claim, how you checked it, its artifact) in `.evidence/<change>/`, excluded from git through the file `git rev-parse --git-path info/exclude` prints.

## Scope

The smallest change that does what was asked, on the current branch. Fix what the change can't work correctly without, and say so. Other extras you notice become issue candidates, not part of the diff.

## Report

Short and plain:

- **Changed:** what a user or caller now sees.
- **Evidence:** shown inline when the interface can (images, short output), otherwise the path and how to view or rerun it.
- **Decisions:** each choice made for the user, and how to reverse it.
- **Review:** rounds run, and each finding not fixed with why, or that none ran.
- **Not done:** what's unproven, and issue candidates.
