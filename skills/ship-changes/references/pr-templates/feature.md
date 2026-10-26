# Feature PR template

Write every section. Replace the guidance under each heading with the content.

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
