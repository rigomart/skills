---
name: prototype
description: Build switchable variants of a screen or behavior next to the current one, so the user picks a direction by using them. Use when asked to redesign something, explore or prototype directions, or what something could look like.
---

# Prototype

The user decides faster by using variants than by reading proposals. Build them first, in the product's own components and data, and let the user steer. A prototype ends when the user picks a direction.

## 1. Frame

Read the code and screens involved, the decisions that bind them (ADRs, the glossary), and earlier prototype commits for the same surface (`git log` on the prototype folder). Then write down, in a line or two:

- **What the screen or output must get across** to its user. Variants built without it drift apart on different goals.
- **What stays fixed and what is open.** Only the open parts vary.
- **The user's own proposal**, restated in their words, if they brought one. It becomes one of the variants, built as they described it, not as you would improve it.

Done when the frame is written and every open part maps to at least one variant.

## 2. Seed a scenario

Pick the data that makes the question visible: the long text, the many items, the late and repeating dates, the empty state, whatever the open part struggles with. Load it through the product's own commands, fixtures or seed scripts, not hand-written markup. Keep it to the cases that matter: a scenario full of noise hides the difference between variants. Sample data stays generic, with no names, paths or details from the user's own life or machine, since prototypes get committed.

Done when `current` shows the problem under the scenario.

## 3. Build variants

- **`current` first**, as it ships today, then 2 to 4 directions that differ in whole shape (layout, hierarchy, the main affordance), not in a detail of one shape. Include one you would not recommend. More than 5 stops being different and starts being noise.
- **Where the project keeps prototypes**: a design lab, Storybook, a playground, a dev-only route. With none, mount the variants on the real page or command they change, so they sit inside the real app. Use the product's components, styling and data, with no tests and no polish.
- **Each variant reachable on its own**: a `?variant=` parameter, a story, a key, a flag.

How to wire and check variants depends on the surface. Open the reference for it:

- A web page or web app: [references/web.md](references/web.md)
- A CLI or TUI: [references/terminal.md](references/terminal.md)

Done when every variant opens from its own link or command.

## 4. Check each one yourself

Open every variant under the scenario and drive it: every control, the empty, filled and cleared states, anything that saves or deletes. Fix what breaks. A bug in a prototype reads to the user as a flaw in the direction.

Done when every variant has been seen under the scenario at each size its reference names.

## 5. Send

Leave the prototype running so the user can open it. Reply with one link or command per variant, a side-by-side image or text dump, and a table: variant, what changes, where it struggles. End with your recommendation.

Commit the round on a branch for the prototype before you send it. The commit keeps the variants that lose, and the user often comes back to one.

## 6. Converge

Expect a few rounds. The user's reaction ("too busy", "this but with the styling of the first") is the signal: find what it reacts to, and reshape only that rather than defend. A complaint about one state or part reopens that part; a remark about one variant rules out that variant's problem, not everything near it.

- **A combination keeps its base.** When the user names a variant as the base and asks for a part of another, start from the named variant exactly as it is and bring over only the named part.
- **Fix what is settled, vary what is open.** Once some choices are decided, build one prototype with them in place and make only the open questions switchable.
- **Drop what the user drops** and build new directions in its place, without leaning on the one they called a reference.
- **Commit each round.**
