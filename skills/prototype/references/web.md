# Web variants

## Wiring

- **On the real page.** Gate the variants with a `?variant=` search parameter on the route they change. Keep the page's data loading, params and auth above the switch; only the rendered part changes per variant. A variant with no page of its own (a new section, a new card) still mounts inside the page that would hold it.
- **In a lab or Storybook**, when the project has one: one entry per variant, fed by the same seeded scenario, with `current` built from the shipped component, not a copy of it.
- **A dev-only switcher**: a small fixed bar listing the variants, plus number keys or `[` and `]` to step through them. Keep it out of production builds.

## Checking

Start the dev server and open each variant with a browser tool (the `agent-browser` skill, if installed), at phone and desktop widths. Take a screenshot of each for the side-by-side, and keep the server running when you send.
