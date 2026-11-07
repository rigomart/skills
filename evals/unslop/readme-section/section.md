## Storage And Sync

Tasks are stored in a seamless, human-readable JSON file — by default `~/.tasks.json`. This isn't just a cache; it's the single source of truth for your entire task landscape.

- **Location:** Set `TASKS_FILE` to point the CLI at a different file, for example one per project. The variable is read on every command, so you can switch lists without restarting anything.
- **Format:** The file holds one object with a `tasks` array. Each task has an `id`, a `title` and a `done` flag, and a file of 500 tasks is about 40 KB.
- **Safety:** `save` rewrites the whole file on every change. If two commands run at the same time, the last write wins and the other change may be lost.

Additionally, you can sync the file across machines with any tool that copies files — Dropbox, Syncthing, git, and more. Note that `tasks` does not lock the file, so only sync it when no command is running.

For more details, see the [Node.js `fs` docs](https://nodejs.org/api/fs.html). Happy tasking! 🎉
