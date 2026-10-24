# macOS apps: XCUITest

Guidance for a native macOS app (AppKit, SwiftUI, or both), proven with XCUITest and run through `xcodebuild`. No direct driver has been tried on macOS, so the agent proves each change with a throwaway test in `Scratch/`, copying from 1 to 3 committed example tests, and runs the checks of the feature files the same way.

**Where this comes from.** First followed on Aside (2026-10): an `LSUIElement` menu bar app with a non-activating `NSPanel` hosting SwiftUI, a Carbon global hotkey (KeyboardShortcuts), a URL scheme, an XcodeGen project, Xcode 27, macOS 26.6, two displays. A fresh agent then followed the generated skill cold and passed. Items marked *(seen)* were observed there; the rest carry over from the web guidance as it stood when it used Playwright. The few claims nobody has checked are under "Still unconfirmed" at the end.

## Framework

- **UI tests are XCTest.** Swift Testing has no UI testing. Unit tests may use either framework, but every UI example is an `XCTestCase` that drives an `XCUIApplication`.
- **The repo has a UI test target.** Reuse its scheme, test plan and helpers, and add what is missing below.
- **The repo drives the app another way** (Appium's Mac2 driver, AppleScript or System Events scripts). Stop and report it: running two driving stacks means learning two vocabularies.
- **The repo has none.** Propose a UI test target, `<App>UITests`. It ships with Xcode, so there is no package to vet. It needs full Xcode, not the Command Line Tools: set `DEVELOPER_DIR` to Xcode's `Contents/Developer` in the stack CLI rather than relying on `xcode-select`.
- **The project file.** Agents do not hand-edit `.pbxproj`. If the project is generated (XcodeGen `project.yml`, Tuist), add the target there and regenerate. If it is a plain Xcode project, its test directories must be synchronized folders (Xcode 16+), so a new file joins its target without a project edit. If neither holds, stop and propose one: that choice belongs to the user.
- **Swift 6** *(seen)*. An `XCTestCase` subclass does not compile under `SWIFT_DEFAULT_ACTOR_ISOLATION: MainActor` (its inherited initializers are nonisolated). Leave the UI test target nonisolated and mark test methods and helpers `@MainActor`. `XCUIApplication` is `Sendable`.

## Layout

```text
<App>UITests/                   # or UITests/ beside the app's sources
  Support/VerifyTestCase.swift  # base class: launch, stamp, shot, tree, failure evidence
  Support/AppActions.swift      # element accessors and actions shared by tests
  Stubs/                        # stand-ins for external processes and services, see Boundaries
  Tests/*Tests.swift            # committed worked examples
  Scratch/                      # throwaway tests: gitignored, still compiled into the target
scripts/verify                  # the stack CLI
.verify/<instance>/             # gitignored: DerivedData/, results/, evidence/, logs/, instance.json
```

`Scratch/` has to be part of the UI test target and still be gitignored. Include it through the generator's source glob or a synchronized folder, keep it present in a fresh checkout with a tracked placeholder (`Scratch/*` plus `!Scratch/.gitkeep` in `.gitignore`), and exclude the placeholder from the target (XcodeGen: `excludes: ["**/.gitkeep"]`). With a generated project, have `run` regenerate before every build, so a new scratch file needs no extra step.

Every run compiles all of `Scratch/`, so one agent's broken scratch file breaks every other agent's build. The generated skill tells agents to put each scratch test's source in their report and then delete the file *(seen)*.

## The instance

A desktop app has no server, but it does have state that collides: the developer's own copy of the app, which may be running while the agent verifies. The conditions in step 3 always hold, so build the stack CLI. An instance is a verification build plus its results and evidence:

- **A Verify build configuration** *(seen)*. Give verification builds their own `PRODUCT_BUNDLE_IDENTIFIER` (suffix `.verify`), display name and URL scheme through a build configuration (XcodeGen: `configs: {Verify: debug}` and per-config target settings; Info.plist values as `$(SETTING)`), and make it the UI test scheme's test configuration. Do not pass `PRODUCT_BUNDLE_IDENTIFIER=` on the `xcodebuild` command line: it applies to every target, test runner included. A separate URL scheme matters because LaunchServices may send the developer's `app://` links to the verification copy.
- **Global hotkeys** *(seen)*. Carbon `RegisterEventHotKey` without `kEventHotKeyExclusive` (as KeyboardShortcuts calls it) lets two processes register the same combination, and one press then fires both. Give the verification copy a different combination. With KeyboardShortcuts, pass it as a launch argument: `-KeyboardShortcuts_<name>` followed by `"{\"carbonModifiers\":…,\"carbonKeyCode\":…}"` *with the outer quotes*, or the argument domain parses it as a plist and drops it.
- **Signing.** Sign every verification build with the same identity, either an Apple Development certificate or a named self-signed one. Privacy grants (microphone, speech recognition, calendar, accessibility) follow the code signature, and an ad-hoc signature changes with each build.
- **Data.** If the app keeps state on disk, it reads its data directory from a launch environment variable and `launch()` points it into the instance. If the app keeps no state yet, don't add an unused seam: the generated skill says to add one with the first change that stores something.
- **Names** *(seen)*. Have agents start one instance per task (`--name <task>`) and purge it when done, rather than share a `default`: a cold agent found a `default` someone else had left up and could not tell whether to use it. Each instance's build also registers another copy of the app with LaunchServices, which purging removes.
- **One screen.** UI tests take the real pointer, keyboard and focus, so one run at a time per Mac user. Put the lock outside the checkout (`$TMPDIR/<app>-verify-ui.lock`), because worktrees and other checkouts share the screen. `run` refuses while a live process holds it; a dead holder's lock is taken over. Building is not locked.

Commands, in the JSON shape step 3 describes:

- `up`: regenerates the project, runs `xcodebuild build-for-testing` into the instance's `DerivedData/`, and records the branch and commit in `instance.json`.
- `run <Class[/testMethod]>`: takes the lock, regenerates and rebuilds (incremental; the agent has usually changed the app or added a scratch test since `up`), then `xcodebuild test-without-building -xctestrun <Products>/<Target>_*.xctestrun -only-testing:<Target>/<id>`. Prints each test's result and failures (message, file, line), the evidence folder, the screenshot paths, the result bundle and the log. A build failure comes back as `{"ok":false,"error":"Build failed."}` with the compiler errors. `run` only runs the framework and never drives the app.
- `doctor`: checks Xcode, the project generator, automation mode, the signing identity, the instance's branch and build, and the lock. The developer's own copy running is information, not a failure.
- `down [--purge] [--dry-run]` *(seen)*: stops processes whose command line contains the instance's directory (`pgrep -f "$DIR/"`): its xcodebuild, test runner and app. That never matches the developer's copy, so it does not need the lock. After a passing run it usually stops nothing, since each test's teardown quits what it launched; the skill says so. `--purge` deletes `DerivedData/` and `instance.json`. `results/`, `evidence/` and `logs/` survive both.

`up` and `run` refuse an instance built on another branch.

## Config

- `-destination 'platform=macOS'`, `-derivedDataPath .verify/<name>/DerivedData`, `-resultBundlePath .verify/<name>/results/<timestamp>.xcresult`. The bundle path must not already exist.
- `-test-timeouts-enabled YES -default-test-execution-time-allowance 120` for a per-test limit. macOS has no `timeout` command; wrap each `xcodebuild` in `perl -e 'alarm shift; exec @ARGV' <seconds> …` for a hard limit.
- UI tests get their own scheme or test plan, so the unit test command stays fast and never takes over the screen.
- In the base class, set `continueAfterFailure = false` and create the `XCUIApplication` inside each test or in `setUp`, not as a stored property set up once. A hang has been reported in Xcode 26 when a stored app object meets a failure.
- Launch with `-ApplePersistenceIgnoreState YES`, so windows from an earlier run are not restored.

## Fixtures

Put these in `VerifyTestCase`, named for the app:

- **`launch()`**: launches the verification app with its hotkey and data arguments, plus any launch arguments the test passes to arrange a precondition, and terminates it in a teardown block.
- **`stamp`**: text unique to each test, for everything a test types or creates.
- **`shot(label, of: element)` and `shot(label, region:)`** *(seen)*: `element.screenshot()` failed for a non-activating `NSPanel` and its children ("Failed to create screenshot. Image creation failed"), and `app.screenshot()` returned the whole main display. Crop instead: find the `NSScreen` containing the frame (element frames have a top-left origin at the main display, `NSScreen` frames a bottom-left one), take `XCUIScreen.screens[index].screenshot()` (same order as `NSScreen.screens`; assert the aspect ratio matches), crop to the frame plus a margin, attach as PNG with `lifetime = .keepAlways`. Cropping keeps the rest of the developer's screen (their browser, their files) out of the evidence. The `region:` form proves something closed: keep the frame while it is open, shoot the region after.
- **`shotScreens(label)`**: every display, only for changes about where the app sits relative to other apps.
- **`tree(app)`**: attaches `app.debugDescription`.
- **`record(_:)` override** *(seen)*: Xcode attaches the app's hierarchy to a failure only when an element query fails, not when an assertion does. Attach a screenshot of every display and the tree of every app the test launched. Read both inside one `MainActor.assumeIsolated` that does not capture `self` (copy the app list to a local first).

`AppActions.swift` holds element accessors (`app.panel`, `app.askField`) and actions more than one test needs. Each action returns the element the next step works in, once it has keyboard focus. Make the building blocks (send any URL, wait for the window with focus) public, not private: a cold agent testing a new entry point had to copy a private wait *(seen)*. Agents copy the surrounding code, so the shared actions set the style.

## Boundaries

- **External processes and services** (a CLI the app spawns, a network API). Substitute only at a seam a user could also configure, such as an executable path setting or a base URL. The stand-in in `Stubs/` replays recorded output. Keep at least one example against the real service. When its credentials or network are missing, it calls `XCTSkip` and is reported `INCONCLUSIVE`, never as a pass.
- **System permission prompts.** Grant each one once by hand to the verification bundle ID and list them in the generated skill. A test that runs into a prompt fails, and the report names the prompt.
- **Raw events** *(seen)*. The UI test runner is not Accessibility-trusted. A `CGEvent.post` from a test does nothing and makes macOS ask the user to give `<Target>-Runner` Accessibility access. Drive keys with `typeKey`/`typeText` only, and tell the user to decline that prompt.
- **Microphone input.** A test cannot speak. Substitute at the device boundary: an audio file the app reads instead of the microphone, selected by a launch environment variable. The report still names the live microphone as not driven.

## Driving

- Query by what the user sees: `app.buttons["Send"]`, `app.staticTexts[...]`, `app.textFields["<placeholder>"]` (a text field matches its placeholder), `app.windows`, `app.dialogs`, and `app.statusItems["<accessibility description>"]` then `app.menuItems["<title>"]` for a menu bar extra *(seen)*.
- **Panels** *(seen)*. A borderless non-activating `NSPanel` is listed under `app.dialogs`, without activating the app; `app.state` stays `.runningBackground`. Setting the window's `identifier` (`NSUserInterfaceItemIdentifier`) makes it `app.dialogs["<id>"]`.
- Use `accessibilityIdentifier` for an element with no stable label, such as a streamed answer or a status line. The generated skill lists the identifiers the app has.
- Narrow by chaining from a container: `panel.buttons["Send"]`, `.matching(identifier:)`, `.containing(...)`. Match by `NSPredicate` (`value BEGINSWITH %@`) only for text that is dynamic by design, and assert exact text everywhere else.
- Wait on conditions: `waitForExistence(timeout:)`, `waitForNonExistence(timeout:)` *(seen)*, and `XCTNSPredicateExpectation` with `XCTWaiter` for a value, `hasKeyboardFocus`, a count, `isHittable`, or another app's `state`. `sleep` is never proof.
- Type with `typeText`, and send shortcuts with `typeKey(_:modifierFlags:)`.
- **Global hotkeys** *(seen)*. `frontApp.typeKey(key, modifierFlags:)` reaches a Carbon global hotkey while another app is in front. Each such call takes about 10 s, because XCUITest waits for the front app to receive a key the hotkey took.
- **Other apps** *(seen)*. `XCUIApplication(bundleIdentifier:).launch()` quits a running instance first, so never use an app that may hold the user's unsaved work (TextEdit, Notes). Calculator works: it keeps nothing worth losing, and its display (`scrollViews["StandardInputView"].staticTexts`, value prefixed with U+200E) shows whether typed digits reached it. Check `state == .runningForeground` to prove "the app I was in stays in front".
- **URLs** *(seen)*. `XCUIApplication.open(_:)` quits and relaunches the app, dropping its launch arguments. Open a URL in the running app with `NSWorkspace.shared.open([url], withApplicationAt:configuration:)`, where the app sits next to the runner: `Bundle.main.bundleURL.deletingLastPathComponent()`. That proves how the app handles the URL, not how LaunchServices routes it; the skill says so.
- **Entry points.** Opening the app through a URL scheme or launch arguments is arranging. A change to how a user summons the app (a global shortcut, the menu bar item, the Dock, a URL the user opens) is proven through that entry point, or it is reported as not driven.
- **Appearance** *(seen)*. `-NSRequiresAquaSystemAppearance YES` forces light. `-AppleInterfaceStyle Light` does nothing (the key only knows `Dark`).

## Failures

`run` prints the failing assertion with its file and line from `xcrun xcresulttool get test-results tests --path <bundle>` (walk the nodes with `nodeType == "Test Case"`; their `"Failure Message"` children carry `sourceLocation`; a skip shows as `"result":"Skipped"`). Export attachments with `xcrun xcresulttool export attachments --path <bundle> --output-path <dir>`. Files come out with UUID names; `manifest.json` maps each to its `testIdentifier` and `suggestedHumanReadableName` (`<name>_<n>_<UUID>.<ext>`), so file them per test under the name the test gave. *(seen, Xcode 27)*

Xcode 27 also attaches, unasked: a screen recording of the main display (kept for failed tests only), UI snapshot archives (binary plists, Xcode-only), and the app hierarchy on a failed query. An interrupted run leaves a bundle `xcresulttool` cannot read; report that as interrupted, not as "no tests matched".

The app's logs can explain a failure, and their timestamps pinpoint focus changes. Write the command as `/usr/bin/log show --info --last 5m --predicate 'subsystem == "<subsystem>"'`: zsh has a `log` builtin that shadows it, and `--info` is needed for `.info` messages *(seen)*. Check what each log line really means before a gotcha leans on it: Aside's "lost focus" line, which looked like a sign of interference, is written on every close *(seen)*. Logs never prove a change.

## Variants

- **Tests can reach:** light and dark appearance, window sizes, a menu-bar-only app against one with a Dock icon, and another app in front.
- **Tests cannot reach, as far as anyone knows:** another app in full screen on its own Space, a second display chosen on purpose (a panel that follows the pointer opens wherever the user's pointer is), Mission Control, Stage Manager, and a locked screen.

The generated skill lists each path with how a test reaches it, or with exact manual steps when nothing can. Every path the change touched that no test drove is named in the report.

## Sound, speech and notifications

None of these show up in the accessibility tree. Prove what the user sees about them: a listening indicator, a live transcript, or a speaking indicator whose accessibility value changes. Audio output itself is checked by ear and reported as not driven. Notification banners belong to Notification Center, which is a separate app.

## Looking around

`up` the instance, then `open -n <instance app> --args <the launch arguments launch() uses>`, and stop it with `down`. Looking is not proof. When a look and a test disagree, trust the test.

## Gotchas to look for

Check for each of these while building the examples, and record the ones the app has, along with the fix:

- **Automation mode.** Without it a run stops at a password prompt. `automationmodetool` with no arguments prints whether the device "DOES NOT REQUIRE user authentication"; `doctor` greps for that. The one-time fix is done by a person: `sudo automationmodetool enable-automationmode-without-authentication`.
- **The developer's own copy.** Same hotkey: both fire. Same URL scheme: links may go to the wrong copy. See The instance.
- **Non-activating panels and menu bar apps.** The app under test is not frontmost by design. `app.activate()` changes the very behavior being proven, so query the panel without activating the app.
- **Keys after a non-activating panel closes** *(seen)*. After Aside's panel closed with Esc, XCUITest's next `typeText` to the previously active app never arrived, yet with a real keyboard typing went back to that app. It is an XCUITest limitation: focus return after a non-activating panel is a manual check. The agent first reported it to the user as a likely app bug, reasoning that XCUITest keys reach global hotkeys and so behave like real ones; the user's manual check disproved it. A test-tool symptom is not an app bug until a real input reproduces it.
- **Animations.** An element can exist before it stops moving. Wait for `isHittable` or keyboard focus before typing into something that just appeared.
- **A person at the keyboard** *(seen)*. A click during a run takes key status from the panel and the test fails. Rerun once, then report `INCONCLUSIVE`.
- **Restored state.** Without `-ApplePersistenceIgnoreState YES`, windows from the previous run reopen.
- **Privacy grants lost.** A prompt that keeps returning after every build means the signing identity changed.

## Still unconfirmed

- Whether system permission prompts (microphone, speech) can be seen or answered from a test.
- Whether `-AppleInterfaceStyle Dark` switches an app to dark on a Mac set to light.
- Whether `XCUIApplication(bundleIdentifier: "com.apple.notificationcenterui")` can see a banner.
