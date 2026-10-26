# Performance PR template

Write every section. Replace the guidance under each heading with the content.

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
