# Screenshots

- **Take them from the verification run** at the PR's head. When the project's verification skill names the images meant for the PR, use those. When it names none, or there is no such skill, take them while driving the change: one per changed state and per variant (width, theme), cropped to the change. When the change alters an existing screen, add a before image of the same state: revert the change's files in the working tree (`git checkout origin/<base> -- <files>`), take it, restore them (`git checkout HEAD -- <files>`), and confirm `git status` is clean. A recording replaces stills when the sequence is the change (focus moving, an animation).
- **Look at each image before attaching it.** Attaching publishes it. It shows the app with throwaway data only, nothing from the developer's own account or the rest of their screen.
- **Alt text says what the image proves**, not what it is: `Inbox badge shows 2 after archiving one of 3`, not `screenshot`.
- **Attach with `gh`.** `gh pr create`, `gh pr edit` and `gh pr comment` take `--attach <file>`, up to 50 per command. Run the command from the repo root, and reference each file in the body by exactly the path you pass to `--attach` (`./.verify/…`); the body file itself can live anywhere. `gh` uploads each file and rewrites the reference to the hosted asset. An attached file the body does not reference is appended to the end.

  ```bash
  gh pr create --title "..." --body-file body.md \
    --attach ./.verify/main/evidence/inbox-badge-before.png \
    --attach ./.verify/main/evidence/inbox-badge-after.png
  ```

  If some uploads fail, `gh` still creates the PR with the rest and exits non-zero; reattach the missing ones with `gh pr edit <pr> --attach`.
- **Keep them current.** When a later push changes what the screen shows, retake the images and replace the body with `gh pr edit <pr> --body-file body.md --attach …`, so the PR never shows a stale state.
- **No `--attach`** in `gh <cmd> --help` means an older `gh`. Propose upgrading it; that is the user's call. Until then, open the PR without the section and tell the user which images to drag into it.
