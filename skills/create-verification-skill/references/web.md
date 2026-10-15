# Web apps: Playwright

Guidance for a web UI, proven with Playwright Test. It comes from building `verify-vita-os` (a Vite web app and an API with its own database, behind email sign-in), where agent-browser flows were replaced by Playwright specs.

## Framework

- **The repo has Playwright Test.** Reuse its config and fixtures. Add what is missing below rather than starting a parallel setup.
- **The repo has another end-to-end framework** (Cypress, WebdriverIO, Selenium). Stop and report it: this guidance is written for Playwright, and running two browser stacks means two vocabularies.
- **The repo has none.** Propose adding `@playwright/test` in its own workspace or directory (`apps/e2e/` in a monorepo, `e2e/` otherwise), with the reason. Use a browser the machine already has (`channel: "chrome"`) or install one (`playwright install chromium`).

## Layout

```text
e2e/
  playwright.config.ts
  src/fixtures.ts      # test, expect, and the fixtures below
  src/app.ts           # actions specs share: sign-in, create a record, open a dialog
  src/global-setup.ts  # starts or reuses the instance, when there is a stack CLI
  tests/*.spec.ts      # committed worked examples
  scratch/             # throwaway specs that prove a change: gitignored, excluded from typecheck
```

Add a root script that runs the specs from the workspace (`test:e2e`), so the binary resolves under any package manager's linker. Specs and the generated skill write paths relative to the workspace: `tests/…`, `scratch/…`.

## Config

- `testMatch` covers `tests/` and `scratch/`.
- Without a stack CLI: `webServer` runs the dev command with `reuseExistingServer`, on a port that is not the developer's usual one. With one: `globalSetup` calls `up`, which starts or reuses the instance, and the instance stays up after the run for fast reruns.
- `outputDir` and the HTML report go under the instance's directory, so instances do not overwrite each other.
- `screenshot: "only-on-failure"`, `trace: "retain-on-failure"`, a default desktop `viewport`, and an `actionTimeout` well under the test timeout.
- `workers: 1` when the data layer cannot take concurrent access from one instance; parallelism then comes from separate instances.

## Fixtures

Give specs these, named for the app:

- **`account`**: a throwaway user per spec file and per `--repeat-each` repeat, created through the app's supported sign-up path. Creating it through the API is arranging a precondition; the sign-in spec proves the form itself.
- **`page`**, signed in as that user through `storageState`, with `baseURL` set to the instance. To start signed out: `test.use({ storageState: { cookies: [], origins: [] } })`.
- **`stamp`**: text unique per test, for everything a test creates, so no check can match another test's rows.
- **`shot(label)`**: saves `<label>.png` to the instance's evidence directory, attaches it to the report, returns the path.
- **A read-only query** against the instance's database, when the app has one. It accepts only reads and returns typed rows.
- **`sent(page, path, action)`**, when the app updates optimistically: runs the action, waits for the response to the write it sends to `path`, and asserts it succeeded. A reload comes only after it.
- **`settled(locator)`**, when panes, drawers or dialogs animate: waits until the element has no running animations (`el.getAnimations().length === 0`).

`src/app.ts` holds the actions more than one spec needs, each returning the locator the next step works in (create a record, then return its pane once its write is confirmed and it stopped moving). Agents copy the surrounding code, so the shared actions set the style.

## Users and test data

Each spec file runs as one user, and its tests run in order, so a later test sees what earlier tests created. When a test fails, Playwright restarts the worker and the rest of the file runs as a new user. So a test does not rely on data an earlier test created, nor on an empty state unless it is the file's first test. Other users share the instance's database: every query is scoped to the test's user.

## Driving

- Locate by role and accessible name, label, or visible text: `getByRole("button", { name: "Add", exact: true })`. Use `exact: true` whenever another control's name contains this one.
- Narrow by chaining from a container (`pane.getByRole(…)`, `getByRole("listitem").filter({ has: … })`), not with XPath. Use CSS only for a stable hook no role reaches, such as a `data-*` attribute. Note in the generated skill whether the app has `data-testid` handles.
- Wait with web-first assertions: `toBeVisible`, `toBeHidden`, `toHaveCount`, `toHaveValue`, `toHaveURL`. For a fact no locator holds (an order, a URL query, a computed style, focus, a date computed from today), use `expect.poll`. `waitForTimeout` is never proof.
- After a reload, assert something visible before asserting something hidden, so `toBeHidden` cannot pass on a page that has not rendered.
- To see what a surface offers, print its accessibility tree: `console.log(await locator.ariaSnapshot())`.

## Failures

A failing assertion prints the line, the locator it waited for, and `error-context.md`: the page's accessibility snapshot at that moment, with the roles and names actually on screen. The generated skill tells the agent to read it before changing anything, and where the screenshot, trace and report land.

## Layouts

Find the widths where the app swaps components, not only styles: a side pane that becomes a drawer, a toolbar that moves to a bottom bar, columns that fold. Each one is a separate path to drive. The generated skill lists them with their widths, which changes get a test at each, and how to tell from the accessibility tree which one is on screen (`complementary "<title>"` against `dialog "<title>"`).

## Looking around

When a browser tool is available (agent-browser, the platform's own), the generated skill can describe a quick look: start the instance, open its web URL, sign up a throwaway user, look. Looking is not proof, and when a look and a spec disagree about the app, trust the spec. Under a hand-driving tool, a tool bug once looked like an app bug and became a rule about the app.

## Gotchas to look for

Check for each of these while building the examples, and record the ones the app has, with the fix:

- **Animations.** Content is on the page before a pane or drawer stops sliding, and a click during the slide lands elsewhere, sometimes outside the drawer, which closes it. `settled` before clicking inside one that just opened.
- **Overlays.** "… intercepts pointer events": an open pane, dialog or toast covers the target, and the click retries until it times out. Name the overlay and how to close it.
- **Lazy loading.** Editors and heavy widgets load after the page; wait for the control itself, not the page.
- **Delayed writes.** An Undo offer or debounce delays a write; wait for it to end before a reload or a query.
- **Toasts.** Transient, and an earlier one with the same text may still be up. Never the only proof of a write.
- **Origins.** CORS allowing exactly one origin (`localhost` versus `127.0.0.1`).
- **Auth.** Social sign-in buttons with no local credentials; do not click them.
- **Dates.** Tests computing "today" can fail across midnight or at month edges; pick dates relative to today.
