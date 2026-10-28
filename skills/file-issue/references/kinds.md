# Issue kinds

When the repo has its own template or a body shape per label, use it and fill it with what the kind below asks for.

## Bug

- **What happens:** one or two sentences: what is broken, for whom, and the impact.
- **Steps:** numbered, from a state anyone can reach.
- **Expected** and **Actual.**
- **Since:** the release, commit or closed issue where it last worked, when known.

## Task

One buildable change, landable in one pull request.

- **What changes** for the user, and why.
- **Decisions** already settled that bind it, if any.
- **Depends on:** issues that must land first.
- **Out of scope.**
- **You see:** the action, then the screen state or output that follows.

## Idea

A problem worth solving that is not ready to build.

- **Problem:** the situation and what fails, in the user's words.
- **Angles:** the directions considered, a line each.
- **Open questions:** what has to be decided before it can be specified.
- **Would unpark it:** the evidence that would justify building it.

## Spec with slices

The parent issue for work too big for one pull request. The slices are its sub-issues, so the spec does not list them.

- **Problem**, and the cases that shaped the solution.
- **Shape:** the solution in a few sentences, with a small text mockup of the screen or output it changes.
- **Prototype**, when one was built: the variant to open and the commit that keeps every variant.
- **Decisions:** what was settled, including what the user reversed.
- **Out of scope**, and **Rejected shapes** with why.

Leave implementation choices to the implementing agent unless one was settled.

Each slice is a task (above) that also names the prototype variant it must match, if any.

## Update comment

A comment on an existing issue, for a duplicate or for new context.

- **What is new**: the finding, the decision or the changed scope, in a few lines.
- **What it changes** for the issue: the scope, the plan, or nothing.
