# macOS apps: XCUITest

Guidance for a native macOS app (AppKit, SwiftUI, or both), proven with XCUITest and run through `xcodebuild`.

**Draft.** This was written before any project followed it. It comes from the rules in [web.md](web.md) carried over to Apple's tooling, not from a verify skill that was built and run. The first project to follow it checks each item under "Confirm on first use", corrects this file, and replaces this note with where the guidance came from.

## Framework

- **UI tests are XCTest.** Swift Testing has no UI testing. Unit tests may use either framework, but every UI example is an `XCTestCase` that drives an `XCUIApplication`.
- **The repo has a UI test target.** Reuse its scheme, test plan and helpers, and add what is missing below.
- **The repo drives the app another way** (Appium's Mac2 driver, AppleScript or System Events scripts). Stop and report it: running two driving stacks means learning two vocabularies.
- **The repo has none.** Propose a UI test target, `<App>UITests`. It ships with Xcode, so there is no package to vet. It needs full Xcode, not the Command Line Tools: `xcode-select -p` must point inside `Xcode.app`.
- **The project file.** Agents do not hand-edit `.pbxproj`. If the project is generated (XcodeGen `project.yml`, Tuist), add the target there and regenerate. If it is a plain Xcode project, its test directories must be synchronized folders (Xcode 16+), so a new file joins its target without a project edit. If neither holds, stop and propose one: that choice belongs to the user.

## Layout

```text
<App>UITests/
  Support/VerifyTestCase.swift  # base class: launch, stamp, shot, tree, instance paths
  Support/AppActions.swift      # actions shared by tests: open the panel, send a message
  Stubs/                        # stand-ins for external processes and services, see Boundaries
  Tests/*Tests.swift            # committed worked examples
  Scratch/                      # throwaway tests: gitignored, still compiled into the target
scripts/verify                  # the stack CLI
.verify/<instance>/             # gitignored: DerivedData/, data/, results/, evidence/, logs/
```

`Scratch/` has to be part of the UI test target and still be gitignored. Include it through the generator's source glob or a synchronized folder. Keep it present in a fresh checkout with a tracked placeholder (`Scratch/*` plus `!Scratch/.gitkeep` in `.gitignore`). A generated project needs a regenerate after a scratch file is added, and the skill says so.

## The instance

A desktop app has no server, but it does have state that collides: the developer's own copy of the app, which may be running while the agent verifies. The conditions in step 3 always hold, so build the stack CLI. An instance is a verification build plus a private data directory:

- **Bundle ID.** A build setting gives verification builds their own `PRODUCT_BUNDLE_IDENTIFIER` (suffix `.verify`) and display name. That separates the defaults domain, keychain items, privacy grants and login items from the developer's copy, and lets both run at once.
- **Signing.** Sign every verification build with the same identity, either an Apple Development certificate or a named self-signed one. Privacy grants (microphone, speech recognition, calendar, accessibility) follow the code signature, and an ad-hoc signature changes with each build, so the system prompts again every time.
- **Data.** The app reads its data directory from a launch environment variable and falls back to Application Support. If the app has no such seam, add it: it is configuration, and it only arranges where state lives.
- **One screen.** UI tests take the real pointer, keyboard and focus, so only one UI test run can happen on a Mac at a time, and a run collides with a person using the machine. `run` takes a lock under `.verify/` and refuses while another live run holds it. Building is not locked, so instances can build in parallel.

Commands, in the JSON shape step 3 describes:

- `up`: runs `xcodebuild build-for-testing` into the instance's `DerivedData/`, creates `data/`, and records the branch. A build already made for the current commit is reused.
- `run <Target/Class/test>`: runs `xcodebuild test-without-building -only-testing:<id>` against the instance, with a timeout and a new result bundle under `results/`. It exports attachments into `evidence/` and prints pass or fail, the failure message with its file and line, and the paths of the bundle and the evidence. `run` only runs the framework and never drives the app. It exists so the long command and the instance paths live in one place.
- `doctor`: checks that Xcode is selected, that automation mode runs without a password, that the signing identity is present, that a build exists for this branch, that the lock is free, and that nothing else holds the app's global shortcuts.
- `down [--purge]`: quits processes with the verification bundle ID, but only while this instance holds the lock, so it can only touch what its own run launched. `--purge` deletes `data/` and `DerivedData/`. `results/`, `evidence/` and `logs/` survive both.

Pass instance paths from `run` to the tests through `TEST_RUNNER_`-prefixed environment variables. `xcodebuild` strips the prefix before the test process sees them.

## Config

- `-destination 'platform=macOS'`, `-derivedDataPath .verify/<name>/DerivedData`, and `-resultBundlePath .verify/<name>/results/<timestamp>.xcresult`. The bundle path must not already exist.
- UI tests get their own scheme or test plan, so the unit test command stays fast and never takes over the screen.
- In the base class, set `continueAfterFailure = false` and create the `XCUIApplication` inside each test or in `setUp`, not as a stored property set up once. A hang has been reported in Xcode 26 when a stored app object meets a failure.
- Launch with `-ApplePersistenceIgnoreState YES`, so windows from an earlier run are not restored.

## Fixtures

Put these in `VerifyTestCase`, named for the app:

- **`launch()`**: launches the verification app with a fresh data directory per test class under the instance's `data/`, plus any launch arguments the test passes to arrange a precondition.
- **`stamp`**: text unique to each test, for everything a test creates.
- **`shot(label)`**: attaches a screenshot named `label` with `lifetime = .keepAlways`, so `run` exports it. Use `app.screenshot()` for the app alone and `XCUIScreen.main.screenshot()` when the change is about where the app sits relative to other apps.
- **`tree()`**: attaches `app.debugDescription`, the accessibility hierarchy with roles, labels, identifiers and values. Override `record(_:)` so every failure attaches the tree as well as the automatic screenshot.

`AppActions.swift` holds actions more than one test needs. Each returns the element the next step works in (open the panel, then return the panel once it is hittable). Agents copy the surrounding code, so the shared actions set the style.

## Boundaries

- **External processes and services** (a CLI the app spawns, a network API). Substitute only at a seam a user could also configure, such as an executable path setting or a base URL. The stand-in in `Stubs/` replays recorded output. Keep at least one example against the real service. When its credentials or network are missing, it calls `XCTSkip` and is reported `INCONCLUSIVE`, never as a pass.
- **System permission prompts.** These belong to other processes, so tests cannot reliably answer them. Grant each one once by hand to the verification bundle ID and list them in the generated skill. A test that runs into a prompt fails, and the report names the prompt.
- **Microphone input.** A test cannot speak. Substitute at the device boundary: an audio file the app reads instead of the microphone, selected by a launch environment variable. That arranges the input. The report still names the live microphone as not driven.

## Driving

- Query by what the user sees: `app.buttons["Send"]`, `app.staticTexts[...]`, `app.textFields`, `app.windows`, `app.dialogs`, `app.menuBars`, and `app.statusItems` for a menu bar extra. In SwiftUI, the accessibility label is the visible text unless the code overrides it.
- Use `accessibilityIdentifier` for an element with no stable label, such as a streamed answer or a panel container. The generated skill lists the identifiers the app has.
- Narrow by chaining from a container: `panel.buttons["Send"]`, `.matching(identifier:)`, `.containing(...)`. Match by `NSPredicate` (`label BEGINSWITH %@`) only for text that is dynamic by design, and assert exact text everywhere else.
- Wait on conditions: `waitForExistence(timeout:)`, `waitForNonExistence(timeout:)` (Xcode 16+), and `XCTNSPredicateExpectation` with `XCTWaiter` for a value, a count, `isHittable`, or another app's `state`. `sleep` and `Thread.sleep` are never proof.
- Type with `typeText`, and send shortcuts with `typeKey(_:modifierFlags:)`.
- **Other apps.** `XCUIApplication(bundleIdentifier:)` launches and drives another app, and its `state` shows whether it is `runningForeground`. Use one, such as TextEdit, to prove focus behavior ("the app I was typing in keeps focus") and "it shows over the app I'm in".
- **Entry points.** Opening the app through a URL scheme or launch arguments is arranging. A change to how a user summons the app (a global shortcut, the menu bar item, the Dock, a URL the user opens) is proven through that entry point, or it is reported as not driven.
- To see what a surface offers, call `tree()` or `print(app.debugDescription)`.

## Failures

`run` prints the failing assertion with its file and line. The result bundle holds the automatic failure screenshot and the tree that `record(_:)` attached. The generated skill tells the agent to read the tree before changing anything: it shows the roles, labels and identifiers that were actually on screen. Read a bundle with `xcrun xcresulttool get test-results tests --path <bundle>`, and export its attachments with `xcrun xcresulttool export attachments`.

The app's own logs (`log show --predicate 'subsystem == "<bundle id>"' --last 5m`, or a log file under the instance's `data/`) can explain a failure. They never prove a change.

## Variants

Find the paths that use different components or system behavior:

- **Tests can reach:** light and dark appearance, window sizes, a menu-bar-only app against one with a Dock icon, and another app in front.
- **Tests cannot reach, as far as anyone knows:** another app in full screen on its own Space, a second display, Mission Control, Stage Manager, and a locked screen.

The generated skill lists each path with how a test reaches it, or with exact manual steps when nothing can. Every path the change touched that no test drove is named in the report.

## Sound, speech and notifications

None of these show up in the accessibility tree. Prove what the user sees about them: a listening indicator, a live transcript, or a speaking indicator whose accessibility value changes. Audio output itself is checked by ear and reported as not driven. Notification banners belong to Notification Center, which is a separate app.

## Looking around

To look by hand, `up` the instance, open the built app from `DerivedData/Build/Products/` with `open --env` pointing at the instance's data, and take a screenshot with `screencapture -x`. Looking is not proof. When a look and a test disagree, trust the test.

## Gotchas to look for

Check for each of these while building the examples, and record the ones the app has, along with the fix:

- **Automation mode.** The first UI test run asks for an administrator password to enable UI automation, so a run started by an agent hangs. The one-time fix is done by a person: `sudo automationmodetool enable-automationmode-without-authentication`.
- **The developer's own copy.** Two copies registering the same global shortcut makes one registration fail, often silently. The verification build defaults to a different shortcut, or `doctor` reports the clash.
- **Non-activating panels and menu bar apps.** The app under test is not frontmost by design. `app.activate()` changes the very behavior being proven, so query the panel without activating the app.
- **Animations.** An element can exist before it stops moving. Wait for `isHittable` before clicking into something that just appeared.
- **A person at the keyboard.** A click or keystroke during a run moves focus and fails the test. Rerun once, then report `INCONCLUSIVE`.
- **Restored state.** Without `-ApplePersistenceIgnoreState YES`, windows from the previous run reopen.
- **Privacy grants lost.** A prompt that keeps returning after every build means the signing identity changed.

## Confirm on first use

Unchecked claims, in order of risk. Confirm or correct each one in this file, then delete this section.

- Whether a key sent with `typeKey` reaches a global shortcut (Carbon `RegisterEventHotKey` or the KeyboardShortcuts package) while another app is frontmost. If not, global shortcuts are an entry point no test reaches.
- Whether a non-activating `NSPanel` appears in `app.windows` without activating the app.
- Whether system permission prompts can be seen or answered from a test.
- The exact label on `waitForNonExistence` (`timeout:` or `withTimeout:`).
- The `xcresulttool` subcommands and flags on the installed Xcode (`--help`).
- How to check automation mode's status from `doctor` without changing it.
- Whether `-AppleInterfaceStyle Dark` as a launch argument switches the app's appearance.
- Whether `XCUIApplication(bundleIdentifier: "com.apple.notificationcenterui")` can see a banner.
