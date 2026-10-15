# Feature map

`verify-<app>/features/README.md` lists the app's user-facing features and the committed examples that show how to drive each one. It is an index of examples, not a set of recipes: the tests carry the steps, so the map never repeats them and has little to go stale.

## Shape

```md
# Feature map

Each user-visible feature, the committed examples that drive it, and what no example drives yet. Copy from them when you write the test that proves your change. An example's test names say what it drives; read the test for how.

| Feature | Behavior | Examples | Not covered |
| --- | --- | --- | --- |
| Sign in | Email and password sign-in lands on the dashboard; signed out, every product route goes to `/sign-in`. | [sign-in](<path>/tests/sign-in.spec.ts) | Wrong-password error |
| Create a project | The New project dialog creates a project and opens it. | Every project example, through `createProject` in [src/app.ts](<path>/src/app.ts) | Keyboard shortcut; phone layout |
| Share a link | … | None | All of it |

## Features without an example

**Share a link.** How a test would reach and prove it, and what stays manual.

## Keeping it current

A row changes when an example is added, moved into `tests/`, or deleted, or when a feature appears or goes away.
```

## Rules

- **Feature** is the name a user would use. **Behavior** is one or two sentences of what the user sees, not how it is built.
- **Examples** link the committed tests that drive it, or the shared action that every test reaches it through.
- **Not covered** names entry points, states and layouts no example drives: a shortcut, an error, a phone layout, an empty state. Honest gaps are the point; an empty cell claims full coverage.
- A feature with no example gets **None** and a short paragraph under "Features without an example": how a test would reach it, the proof it needs, and what can only be checked by hand.
- No status lines, run history or evidence paths. Proof history belongs in the pull request that made it, and evidence directories exist on one machine only.
- Links are relative to the map, so they work on GitHub.
