# Web apps: agent-browser

Guidance for a web UI, driven directly with agent-browser. It comes from `verify-vita-os` (a Vite web app and an API with its own database, behind email sign-in), which went from saved agent-browser flows to Playwright specs and back to agent-browser driven fresh each time. The saved flows failed and the driving did not: fresh agents following the generated skill got all seven verdicts right across three changes, each on a fixed and an unfixed build, plus a re-verify from a feature file, in 3 to 13 minutes each. Two Playwright controls on the same unfixed builds also got them right, in 3 to 5 minutes; most of the extra time went to the tool traps below.

## Driver

- **agent-browser is the driver.** Check `agent-browser --version`. If it is missing, propose installing it; that is the user's call. Its usage guide ships with it: `agent-browser skills get core`. The generated skill points there and does not copy it.
- **One browser session per instance**: `--session <instance>` on every call, so two agents never share a browser, and `down` closes it.
- **An existing end-to-end suite** (Playwright, Cypress) belongs to the developer. Leave it alone and do not make verification depend on it. Its specs can show how a feature is reached. Write a test in it only when the developer asks for one.
- **A Playwright harness built only for an earlier `verify-*` skill**: propose removing it, with what it costs to keep, and leave the decision to the user.

## Users and test data

Each verification runs as a throwaway user created through the app's supported sign-up path, with a recognizable email (`verify-<stamp>@<app>.test`). If signing up needs something a local instance cannot complete (an emailed link, an invite, a payment step), add a `user` command to the stack CLI that creates one through the supported sign-up API and prints its email and password. The agent then signs in through the form. Creating the user that way arranges a precondition; a change to sign-up itself is proven through the form.

Use a unique stamp in everything a verification creates, so no check can match another run's rows. Other users share the instance's database: every query is scoped to the verification's user. To start signed out, use a new session or `cookies clear`.

## Driving

- **One action, then look.** After each action, take a fresh `snapshot -i` and act on what it shows. Use refs only from the latest snapshot; a guessed or stale ref hits another element. Do not send a long `batch` and rerun it from the top: when a step fails, fix and retry that step.
- **Check right after the action, not only at the end.** Focus, disabled state and a cleared field can be lost and restored before the final screen, and the end state then looks fine. Read the fact you need straight after the action that should cause it: `eval "document.activeElement.getAttribute('aria-label')"`, `is enabled @e5`, `get value @e5`.
- **Exact values.** `get text`, `get value`, `get count`, `is visible` and `eval` returning JSON, compared in full. `wait --text` is a substring match and case-sensitive: fine as a wait, never as proof.
- **Wait on conditions**: `wait @ref`, `wait --text`, `wait --url`, `wait --fn "<expression>"`, `wait <sel> --state hidden`. `wait <ms>` is never proof.
- **Locate by role and name** from the snapshot (`find role button click --name "Add"`) or by ref. Note in the generated skill whether the app has `data-testid` handles; use CSS only for such a stable hook.
- **Before waiting for something to go, confirm it was there.** A wait for absence passes on a page that has not rendered, on a selector that never matched, and on a page the browser reset to `about:blank`.
- **`find … click --name` acts on the first match** and may hit another control with the same name. Prefer a ref from the latest snapshot.

## Writes

When the app updates optimistically, the screen changes before the server answers. Prove a write in three steps: watch the request (`network requests --filter <path>`) and check that it succeeded, reload and check the screen, and query storage for what the screen cannot show. Writes delayed by an Undo offer or a debounce are not stored until that ends.

A local save can finish in a few milliseconds, so a change about what happens while a write is in flight is not exercised by acting quickly. Slow the network through the page's DevTools connection (`get cdp-url`, then `Network.emulateNetworkConditions` with a latency of a second or more) from a short script outside the repo, and turn it off before reloading, or the reload crawls.

## Evidence

Screenshots go to the instance's evidence directory, named for the step: one right after the action, one after the reload. When the sequence matters (focus, animation, keyboard flow), record it: `record start <path>` then `record stop`. The stack CLI's `env` prints the evidence path.

## Layouts

Find the widths where the app swaps components, not only styles: a side pane that becomes a drawer, a toolbar that moves to a bottom bar, columns that fold. Each one is a separate path to drive, at `set viewport <w> <h>`. The generated skill lists them with their widths, and how to tell from the snapshot which one is on screen (`complementary "<title>"` against `dialog "<title>"`).

## Tool traps

agent-browser behaviors seen in use. Several looked like app behavior at first. Carry the ones you reproduce in this app into the generated skill, and add the ones you hit:

- **`keyboard type` moves focus back into the last-used input** when focus is on the page body. That hides a bug where focus is lost: the typed text still lands, and the stored rows look right. Check `document.activeElement` before typing the next input.
- **`keyboard type` and `press <letter>` with focus on the page body can get stuck repeating** (tens of thousands of keydowns). `keyup` does not stop it; `reload` does. To type where focus may be lost, use `keyboard inserttext`.
- **`snapshot -s <selector>` can print a subtree several times** when the selector matches nested elements. Read order and counts from `eval` or storage instead.
- **`wait --url` without a glob is a prefix match**: `wait --url "http://host/"` passes on any page. Use a glob (`"**/sign-in"`).
- **`wait --text` sees visible text only**, not labels, placeholders or `aria-label`s. Wait on a ref or a selector for those.
- **The default viewport is 1280×577**, exactly on a breakpoint at 1280. `set viewport` right after the browser launches does not stick: set it after `open`, and confirm with `eval "innerWidth"`.
- **`mouse wheel` fires at (0,0)** whatever `mouse move` set (0.38.1), where an overlay or the page edge takes it, so nothing scrolls. `scroll` only sets `scrollTop`, which is not a user gesture. Scroll a container through `get cdp-url` with `Input.synthesizeScrollGesture` (touch) or `Input.dispatchMouseEvent` (wheel) at a point inside it.
- **`record start` leaves the page hidden** (`document.visibilityState === "hidden"`), even after `record stop`, and transitions stall: a pane never opens, a drawer never mounts. Do not record a step whose timing matters; after recording, check `visibilityState` or relaunch the session.
- **The session can reset to `about:blank` and lose its sign-in**, most often in a fast loop of actions or with many sessions on one machine. When a step surprises you, check `get url` first, then sign in again and redo the step.
- **`close` on a session that is not running starts one first**, and a closed session lingers in `session list` for a few seconds. Check the list again before reporting a leak.
- **Enter did not commit an edit**, and that once became a rule about the app ("never press Enter"). The app sent exactly one write. Before writing a rule about the app, reproduce the behavior a second way: another input method, or the stored rows.

## Looking around

Looking is how verification starts on web, so the generated skill needs no separate section for it. Unchecked impressions are not proof: only the checks with exact values are.

## Gotchas to look for

Check for each of these while proving the feature files, and record the ones the app has, with the fix:

- **Animations.** Content is on the page before a pane or drawer stops sliding, and a click during the slide lands elsewhere, sometimes outside the drawer, which closes it. Wait until it stops: `wait --fn "document.querySelector('<sel>')?.getAnimations().length === 0"`.
- **Overlays.** An open pane, dialog or toast covers the target and the click lands on it. Name the overlay and how to close it.
- **Lazy loading.** Editors and heavy widgets load after the page; wait for the control itself, not the page.
- **Toasts.** Transient, and an earlier one with the same text may still be up. Never the only proof of a write.
- **Origins.** CORS allowing exactly one origin (`localhost` versus `127.0.0.1`).
- **Auth.** Social sign-in buttons with no local credentials; do not click them.
- **Dates.** "Today" changes across midnight and month edges; pick dates relative to today.
