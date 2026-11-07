# Fix PR template

Write every section. Replace the guidance under each heading with the content; the length it gives is a ceiling.

```md
## Symptom
One or two sentences: what the user or the system saw, and when.

## Root cause
One or two sentences: what was wrong, and where.

## Fix
Up to three bullets: the change, and any choice you made without the developer, with its reason.

## Blast radius
One sentence: what else depends on the changed behavior, and how a regression would show up.

## Verification
Up to three bullets: the repro failing on the base and passing on this head, and the regression test when one was added.

## Screenshots
| Before | After |
| --- | --- |
| ![The bug, shown](./.verify/...) | ![The same state, fixed](./.verify/...) |
```

Screenshots: images only, and only when the symptom shows on a screen; CLI output goes in Verification as a text block. Before is the bug, after is the same state fixed.
