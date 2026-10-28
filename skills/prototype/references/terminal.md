# Terminal variants

## Wiring

- **Each variant is a real renderer** on the app's own model and keys, not a mockup. Put shared pieces (key hints, footer, confirm bar) in one prototype module and register the variants in one place.
- **A live runner** starts any variant: `<runner> <variant>`. It runs on the seeded scenario by default, and on real data with a `--real` flag that only reads. Simulate every destructive action (delete, remove, push) in both modes.
- **A gallery** prints each variant's screen for each scene as a text dump, so the user can compare them side by side without running anything.
- A CLI with no interactive screen needs only the gallery: the proposed output per variant, for each scene.

## Checking

Drive each variant in a pseudo-terminal: the keys, the selection, the confirm flow, the exit. Render the gallery at 120, 80 and 60 columns and check that alignment and wrapping hold. Send the gallery inline, and the runner command per variant.
