# Performance PR template

Write every section. Replace the guidance under each heading with the content; the length it gives is a ceiling.

```md
## Why
One or two sentences: what was slow, and who it hit.

## Measurements
| | Before | After |
| --- | --- | --- |
| p95 list load | 840 ms | 210 ms |

One line: the workload, the machine and the command, the same for both.

## What changed
Up to three bullets: what the code now does differently, never a list of files.

## Blast radius
One sentence: what correctness the optimization could break, and how it would show up.
```
