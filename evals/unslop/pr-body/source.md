## Symptom

Running `tasks done 7` when there is no task 7 doesn't just fail — it dumps a 14-line Node stack trace instead of a short, user-friendly error. This is a crucial usability issue that significantly undermines trust in the CLI.

## Root Cause

`completeTask` in `src/tasks.mjs` throws `no task with id 7`, but `src/cli.mjs` never catches it. Additionally, the process exits with code 1, which is indistinguishable from a crash.

## Fix

- **Error handling:** `src/cli.mjs` now wraps the `done` branch in a `try`/`catch` and prints `tasks: no task with id 7` to stderr.
- **Exit code:** A missing id now exits with code 3, so scripts can tell it apart from a usage error (code 2).
- **Robustness:** The id is checked with `Number.isInteger` before the lookup — `tasks done abc` gets the same message.

## Blast Radius

Only the `done` command is affected. Scripts that check for exit code 1 after a missing id will need to check for 3 instead. It's worth noting that this may break the shell completion in [#12](https://github.com/acme/tasks/issues/12), but only if it parses the old stack trace.

## Verification

In order to verify the fix, I added two tests to `test/tasks.test.mjs` and ran `npm test` — all 4 tests pass. I hope this helps reviewers! 🚀
