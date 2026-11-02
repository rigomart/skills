# Refactor PR template

Write every section. Replace the guidance under each heading with the content; the length it gives is a ceiling.

```md
## Why
One or two sentences: what this makes possible or easier.

## What changed
Up to three bullets: the new shape, which parts exist now and what each one owns. Name a module only where a reader would go looking for it; never list files.

## Behavior unchanged
Up to three bullets: how that was proven (the tests that cover it, the app driven, the public API compared).

## Blast radius
One sentence: the callers affected, and how a slip would show up.
```
