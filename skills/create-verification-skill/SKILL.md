---
name: create-verification-skill
description: Generate a project-local verify-<app> skill that lets any agent prove a user-visible change in the real app with a throwaway end-to-end test against an isolated local instance. Web apps (Playwright) and macOS apps (XCUITest, tried on one app) for now; other surfaces get their own guidance later. Proves with tests, not hand-driven recipes. Use for /create-verification-skill, or when a repo has no scripted way to prove a change in the real app.
disable-model-invocation: true
---

# Create a verification skill

Generate `verify-<app>`, a project-local skill that tells an agent how to prove a user-visible change in the real app. You write it for the next agent, not for a human: it will be read cold, mid-task, by an agent that has never seen the app.

**Proof is a test that drives the change.** For each change, the agent writes a short throwaway test in the project's end-to-end framework that does what a user does and asserts what the user would see, runs it against an isolated local instance, and reports what it showed. The committed tests are worked examples to copy from, not a suite to keep green. Looking at the app by hand helps decide what to test; it never counts as proof.

Why tests and not an agent driving the app step by step: agents driving by hand end up batching steps and rerunning them from the top after every failure, which is a script in a weaker language. A test framework adds what that loop lacks: waiting on conditions instead of sleeps, exact assertions instead of substring matches, scoped locators, and a snapshot of the page at the moment of failure.

## 1. Pick the surface guidance

Find the surface a user actually touches: a web UI, a CLI or TUI, a desktop app, an API, a mobile app, a library. Then load its guidance:

| Surface | Guidance |
| --- | --- |
| Web app | [references/web.md](references/web.md) |
| macOS app (AppKit, SwiftUI) | [references/macos.md](references/macos.md) (tried once; three items unconfirmed) |

If the primary surface has no row, stop. Report the surface you found and that this skill has no guidance for it yet. Do not improvise one from general knowledge; guidance gets added here after it has been tried on a real project. Guidance marked draft has not been tried yet: follow it, settle each item under its "Confirm on first use" while you build, and before you hand over, correct the guidance file with what you found and drop the draft mark once nothing is left to confirm. A repo with several surfaces gets the one that has guidance, and the generated skill names the others as not covered.

If the repo already has a `verify-*` skill, you are rewriting it: read it and its git history first, and keep what its history shows was learned.

## 2. Interview the repo, not the user

Answer these from the code and only ask the user what you cannot observe:

- **Run.** How the app starts locally: package scripts, Makefile, README. Ports, environment variables, services, seed data.
- **Data.** Where it stores state, how migrations run, whether a fresh data directory works.
- **Users.** How a user signs up and signs in, and whether a throwaway user can be created through a supported path.
- **Existing harness.** End-to-end tests, fixtures, browser tooling already in the repo. Reuse what exists before adding anything.
- **Isolation.** Whether two instances can run side by side (ports, data directories, users). If not, the generated skill says so and refuses to drive a shared instance.
- **Conventions.** Where project skills live (`.claude/skills/`, a symlink into `.agents/skills/`), what `AGENTS.md` or `CLAUDE.md` says about verification.

If the checkout does not build or start as it is, fix that first or report it precisely. A skill written against a broken base teaches wrong steps.

## 3. Decide how the instance starts

Use the framework's own way to start the app (in Playwright, `webServer` with `reuseExistingServer`) unless the app needs more than its normal dev command. It needs more when any of these is true:

- It keeps state that needs a private copy per instance: a database, migrations, a data directory.
- More than one agent may verify in the same checkout at once, so ports and data must not collide.
- It runs several processes that must all be ready before a test can start.

Then build a small **stack CLI** and nothing more. It manages the instance; it never drives the app.

- Commands: `up`, `down [--purge] [--dry-run]`, `doctor`, `env`, and a read-only query against the instance's data when the app has a database.
- Every command prints one JSON object: `{"ok":true,...}` or `{"ok":false,"error":"...","hint":"<what to do next>"}`. `--help` lists the commands.
- Instances have names. Each gets its own ports, data, logs and test output, under one gitignored directory, on ports away from the developer's dev server.
- `up` reaches a usable state from an empty data directory, migrations and seed data included. Ready means usable, not that a process answers: wait for the thing a test needs. A healthy instance is reused, and its pending migrations are applied.
- `up` refuses an instance started on another branch, whose migrations may differ, and says how to recreate it.
- `doctor` is read-only and fails only on what really makes the instance unusable. A commit since `up` is not one of those; a branch switch is.
- `down` stops only processes the instance started (track their process groups), never by name. `--purge` deletes the instance's data. Evidence and logs survive both.
- The skill never drives the developer's own dev server or account.

When the CLI starts gaining verbs that click, wait or assert, stop: that is the test framework's job. A driving language grown one verb at a time becomes a weaker test framework.

## 4. Build the harness

Follow the surface guidance to add or adapt the end-to-end setup: fixtures, shared actions, a gitignored scratch directory for throwaway tests, and 1 to 3 committed example tests for the features a user reaches first. Each example must pass.

Adding a dependency is the user's call. Propose it with the reason and follow any dependency-vetting rule the user or the project has (such as running `depfit`).

## 5. Write the skill

Write `verify-<app>/SKILL.md` where the project keeps skills, with frontmatter (`name: verify-<app>` and a `description` naming the app, the surface, and when to reach for it; without frontmatter the skill never registers). Every command, selector and path in it comes from this repo and has been run. No placeholders. Sections, in order:

- **What proof is.** One paragraph: a throwaway test that drives the change, examples to copy from, the two or three commands.
- **Isolation.** Instance names, what each owns, never driving an instance the skill did not start.
- **Users and test data.** Which user each test runs as, what tests may and may not assume about data, how to start signed out.
- **Prove a change.** The loop: find the closest example, write the throwaway test, run it, read the failure output, fix, rerun, report. Include one short example test that passes when copied out as written.
- **Driving.** How to locate, wait and assert in this app, from the surface guidance.
- **Proof standards.** Below, adapted to the app.
- **Look around** (optional). How to see the app by hand on the instance, and that it does not count as proof.
- **Doctor and cleanup.** The health check, teardown, and where evidence and logs survive.
- **Gotchas.** Traps you hit while building it: timing, overlays, lazy loading, origins, auth buttons with no local credentials.

### Proof standards

Carry these into the generated skill, in the app's own terms:

- Drive the real user path. Never call internal setters, test-only endpoints, or the API in place of the user, and never write to storage to fake a state. Arranging a precondition through a supported path is fine; producing the behavior under test that way is not.
- Capture the action and the result, not only the final screen.
- When the app updates optimistically, prove a write by waiting for the server's response to it, then reload and assert what the server stored.
- Query storage only for what the screen cannot show: no duplicates, an exact stored value, a real deletion, an entry no screen lists. Scope each query to the test's own user and assert exact typed rows, never a substring. Do not restate in a query what the reloaded screen shows; storage changes more often than the screen.
- Drive every path the change touched: each entry point, and each layout or variant built from different components. Name any path changed but not driven.
- A throwaway test is not in the diff, so the report carries it: each test's title, the entry points and variants it drove, its pass line, and its screenshots.
- An entry point that cannot be reached is reported with the attempted step and the unmet precondition, never as verified through a different path.
- A check that could not run is `INCONCLUSIVE`, never a pass.
- If the same step fails twice, stop that item, report it `INCONCLUSIVE` with the failing step and its output, and move on.
- When two ways of observing the app disagree, trust the one with exact assertions and find out why before writing a rule about the app. A tool's bug is not app behavior.

## 6. Seed the feature map

Write `verify-<app>/features/README.md` in the shape in [references/feature-map.md](references/feature-map.md): one table of the user-facing features, what each does, the committed examples that drive it, and what nothing drives yet. Fill "Not covered" honestly; it is the list a later upkeep pass works from.

## 7. Prove the skill cold

A generated skill that was never followed is a draft. Hand it to a fresh agent with no context beyond the repo and a small real verification task ("prove that X shows Y after Z"), and watch where it stumbles: a missing step, a wrong handle, an unclear rule. Fix the skill, not the agent's run. If you cannot spawn an agent, follow the skill yourself from a new shell, exactly as written, and say so.

The run must cover: start the instance, check its health, write and pass a throwaway test from the skill's own example, capture evidence, tear down, and confirm the evidence still exists afterwards. Run the cleanup after every failed attempt too, so broken runs do not strand processes and ports. If you proved it in a stand-in for the real target, list every setup step the stand-in did that the target will not.

## 8. Wire it in and hand over

- Gitignore the instance directory, the evidence, and the scratch tests.
- Point the project's agent instructions (`AGENTS.md`, `CLAUDE.md`) at the skill in one line: a user-visible change is proven in the real app per `verify-<app>`; lint and unit tests do not substitute for it.
- Do not add the end-to-end tests to CI. That is the user's decision; name its cost (time, runner setup).
- Report what you generated, the cold run and what it changed, the features not covered, and the decisions left to the user.
