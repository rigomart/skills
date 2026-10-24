# Feature files

`verify-<app>/features/` holds one file per user-facing feature, saying what to prove about it, and a `README.md` index. A feature file is behavior and checks, never driving steps. The agent finds the steps from the screen each time, so a moved button does not make the file wrong; the file changes only when the behavior does. Saved steps went stale twice in the project this comes from: as markdown recipes, and as scripts in a homemade format that grew XPath clicks, fixed sleeps and substring checks.

## A feature file

`features/<feature>.md`, named in kebab-case for what a user would call it:

```md
# Comment on a card

Typing a comment under a card and pressing Send adds it to the card's thread, newest last, and clears the box.

## Entry points and variants

- Card detail, side panel (1024px and wider) and full-screen sheet (narrower)
- Keyboard: Cmd+Enter sends

## Preconditions

- A board with one card, created through New board → Add card

## Checks

1. The comment shows under the card with the exact text, last in the list, right after Send.
2. The box is empty and still focused after Send (`document.activeElement`, read right after the press).
3. After a reload it is stored once:
   `SELECT body FROM comments WHERE card_id = '<card id>' AND author_id = '<user id>' ORDER BY created_at`

## Traps

- The Send button stays disabled for 300 ms after typing (debounce); wait for it to be enabled.
```

## Rules

- **The behavior** is one or two sentences of what the user sees, not how it is built.
- **Entry points and variants** list every way a user reaches the feature and every layout built from different components. A check is driven on each, or the report names the ones it skipped.
- **Preconditions** say what must exist first and the supported path that creates it.
- **Checks** are numbered, each one observable with an exact value: what the screen shows, a focus or state read right after an action, a stored row with its query. A check that can only be judged by eye says so and is reported as checked by hand.
- **Traps** are app or tool behaviors that misled a verification of this feature, each reproduced a second way before it was written down.
- Keep a file to about 20 to 40 lines. A file growing into steps is cut back to the behavior.
- No status lines, run history or evidence paths. Proof history belongs in the pull request, and evidence directories exist on one machine only.

## The index

```md
# Features

What to prove about each user-visible feature. Prove a change by driving its new behavior and rerunning the checks of every feature it touched.

| Feature | Behavior | Not covered |
| --- | --- | --- |
| [Comment on a card](comment-on-a-card.md) | Send adds a comment to the card's thread and clears the box. | Editing a comment |
| Share a board | Copies a public link to the board. | No checks yet |
```

**Not covered** names entry points, states and layouts no check reaches yet. A feature with no file gets a row with "No checks yet". An empty cell claims full coverage.

## Keeping it current

A change that alters a feature's behavior updates that feature's file in the same change: the checks, the entry points, the traps. A new feature gets a file and a row.
