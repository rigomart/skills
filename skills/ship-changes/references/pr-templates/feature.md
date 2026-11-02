# Feature PR template

Write every section. Replace the guidance under each heading with the content; the length it gives is a ceiling.

```md
## Why
One to three sentences: the problem, and the approach.

## What changed
Up to five bullets, in terms of what a user or a caller can now do or see. End with what was deliberately left out, when something was.

## Decisions
Up to three bullets: choices you made without the developer, each with its reason. "None." when every choice was theirs.

## Blast radius
One or two sentences: what could break, and how it would show up.

## Verification
Up to three bullets: how the change was driven, and what it showed.

## Screenshots
| Before | After |
| --- | --- |
| ![Inbox badge shows 3 after archiving one of 3](./.verify/main/evidence/inbox-badge-before.png) | ![Inbox badge shows 2 after archiving one of 3](./.verify/main/evidence/inbox-badge-after.png) |
```

Screenshots: required when the change is visible, absent otherwise.
