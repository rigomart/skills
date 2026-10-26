# PR templates

One template per PR type. Write every section; the only conditional one is Screenshots, and its rule is stated in place. Replace the guidance under each heading with the content.

## Feature (`feat`)

```md
## Why
One or two short paragraphs: the problem and the approach.

## Scope
- Real symbols and paths that carry the change
- What is deliberately left out

## Tradeoffs
Alternatives a reviewer would ask about, and why not. If none were considered, say so in one line.

## Blast radius
One to three sentences: what this touches, what could go wrong, and how it would show up.

## Verification
- The CI commands you ran locally
- How the change was driven in the real app, and what it showed

## Screenshots
| Before | After |
| --- | --- |
| ![Inbox badge shows 3 after archiving one of 3](./.verify/main/evidence/inbox-badge-before.png) | ![Inbox badge shows 2 after archiving one of 3](./.verify/main/evidence/inbox-badge-after.png) |
```

Screenshots: required when the change is visible, absent otherwise.

## Fix (`fix`)

```md
## Symptom
What the user or the system saw, and when.

## Root cause
What was wrong, and where.

## Fix
The change, and why it sits at the cause rather than the symptom. Alternatives a reviewer would ask about, and why not.

## Blast radius
What else depends on the changed code, and how a regression would show up.

## Verification
- The repro: fails on the base, passes on this head
- The regression test, when one was added
- The CI commands you ran locally

## Screenshots
| Before | After |
| --- | --- |
| ![The bug, shown](./.verify/...) | ![The same state, fixed](./.verify/...) |
```

Screenshots: only when the symptom shows on screen. Before is the bug, after is the same state fixed.

## Refactor (`refactor`)

```md
## Why
What this makes possible or easier.

## Scope
Real symbols and paths moved or reshaped.

## Behavior unchanged
How that was proven: the tests that cover it, the app driven, the public API compared.

## Blast radius
Callers affected, and how a slip would show up.
```

## Performance (`perf`)

```md
## Why
What was slow, and who it hit.

## Measurements
| | Before | After |
| --- | --- | --- |
| p95 list load | 840 ms | 210 ms |

Same workload and machine for both; the command that produced them.

## Scope
Real symbols and paths changed.

## Blast radius
What correctness the optimization could break, and how it would show up.
```

## Docs (`docs`)

```md
## Why
What was missing, wrong, or unclear.

## Scope
The pages or sections changed.
```

## Maintenance (`chore`, `ci`, `build`, `test`, `style`)

```md
## Why
What this fixes or unblocks.

## Scope
What changed: dependencies and versions, workflows, config, tests added.

## Verification
The CI run, local commands, or the test that failed before and passes now.
```

## Revert (`revert`)

```md
## Why
What broke, with a link to the evidence.

## Reverts
#<pr>, and anything else that goes out with it.

## Follow-up
What must happen before it relands.
```
