---
name: implement
description: Take a feature, bug fix, refactor or perf change from an idea, file or issue to done, with evidence it works. Use when asked to implement, build, fix, refactor or speed something up.
---

# Implement

How to build it is your call. This covers when to ask and what to prove.

## Read the request

"What do you think", "analyze" or "how should we" asks for an answer, not a build. An issue number or URL: read it with its comments (`gh issue view <n> --comments`) and state its title before starting.

## Decide, don't interview

Settle what the code, docs, research or a quick experiment can settle, and record each choice as a decision. Ask only what none of those answer and a wrong guess would be costly to undo: a data model or public API others build on, a direction the rest of the work depends on. A choice you could change in a line later (copy, values, placeholder data, what's left out of scope) is a decision, not a question. Ask once, before building, numbered, recommendation first, and keep working on the rest.

When a request leaves several plausible directions for how something looks or behaves, or the user is still unhappy after a second try, settle it with the `prototype` skill before building.

## Prove it

Proof is what you observed yourself on the real thing: a repro that fails before and passes after, before and after screenshots, the same benchmark before and after, behavior pinned through a refactor. The before is gone once you edit, so capture it first. Run what CI runs too. A check you couldn't run is `INCONCLUSIVE`, not a pass.

Save the artifacts and an `evidence.md` (each claim, how you checked it, its artifact) in `.evidence/<change>/`, excluded from git through the file `git rev-parse --git-path info/exclude` prints.

## Scope

The smallest change that does what was asked, on the current branch. Big or complex work (several subsystems, heavy research, a design worth an adversarial review) runs through the `orchestrate` skill. Fix what the change can't work correctly without, and say so. Other extras you notice become issue candidates, not part of the diff.

## Report

Short and plain:

- **Changed:** what a user or caller now sees.
- **Evidence:** shown inline when the interface can (images, short output), otherwise the path and how to view or rerun it.
- **Decisions:** each choice made for the user, and how to reverse it.
- **Not done:** what's unproven, and issue candidates.

Then stop. Ship only when the request asked for it, with the `ship-changes` skill. File issue candidates the user picks with the `file-issue` skill.
