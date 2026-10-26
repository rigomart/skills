# Fix PR template

Write every section. Replace the guidance under each heading with the content.

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
