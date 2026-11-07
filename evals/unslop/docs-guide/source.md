# Getting Started With Tasks

Welcome to `tasks`! This guide will walk you through everything you need to know in order to get up and running with the CLI — from adding your very first task to syncing your list across every machine you own. Whether you are a seasoned terminal user or just starting out, `tasks` is designed to seamlessly fit into your existing workflow.

## Installing The CLI

`tasks` needs Node.js 24 or later. It's worth noting that older versions of Node are not supported, because the CLI relies on the built-in test runner and on ES modules. To install it, clone the repository and run `npm link` from its root. This puts a `tasks` command on your `PATH`, so you can call it from any directory without typing the full path to `src/cli.mjs`.

There is nothing else to configure. `tasks` has no dependencies, no config file and no background service, which makes it a robust choice for machines where you cannot install much.

## Adding Your First Task

To add a task, run `tasks add` followed by its title. The title is everything after `add`, so you don't need to quote it unless it contains characters your shell treats specially, such as `&` or `#`. Each new task gets the next free id, starting at 1, and the CLI prints it back to you — for example `added #1 Write the release notes`.

Ids are never reused. If you complete task 3 and then add a new task, the new one gets id 4 or higher, not 3. This is a crucial guarantee for scripts, because an id you saved earlier will always point at the same task.

## Listing What Is Left

`tasks list` prints every task that is not done yet, one per line, in the order you added them. Each line starts with the id, so you can copy it straight into the next command. Completed tasks are hidden from the list, but they are not deleted: they stay in the file with their `done` flag set to `true`.

Additionally, the output is plain text with no colors or padding, which means you can pipe it into `grep`, `wc -l` or any other tool you already use. For example, `tasks list | wc -l` tells you how many tasks are still open.

## Completing A Task

When you finish something, run `tasks done` with its id. The CLI marks the task as done, saves the file and prints `done #` followed by the id. If you pass an id that does not exist, the command fails with the message `no task with id` and the id, and nothing in the file changes.

Note that `tasks done` takes exactly one id. To complete several tasks, run the command once for each of them, or loop over the ids in your shell.

## Where Your Tasks Live

By default, every task is stored in a single JSON file at `~/.tasks.json`. The file holds one object with a `tasks` array, and each task in it has an `id`, a `title` and a `done` flag. The file is created the first time you add a task, so a fresh install has no file at all until then.

Because the format is plain JSON, you can open the file in any editor, back it up with the rest of your home directory, or read it from your own scripts. Be careful when you edit it by hand, though: a syntax error in the file makes every command fail until you fix it.

## Working With Several Lists

The `TASKS_FILE` environment variable points the CLI at a different file. The variable is read on every command, so you can keep one list per project and switch between them without restarting anything. A common pattern is to set `TASKS_FILE` in each project's `.envrc`, so the right list is picked up when you enter the directory.

If `TASKS_FILE` points at a file that does not exist yet, the CLI treats it as an empty list and creates the file on the first `add`.

## Using Tasks In Scripts

Every command exits with code 0 when it succeeds. An unknown command prints the usage line and exits with code 2, so a script can tell a typo apart from a real failure. A missing id currently exits with code 1, the same code Node uses for a crash, and this may change in a future release.

Because ids are stable and the output is plain text, `tasks` plays a key role in many small automations: a shell prompt that shows how many tasks are open, a cron job that mails you the list every morning, or a git hook that refuses to push while a task tagged `release` is still open.

## Syncing Across Machines

You can sync the file with any tool that copies files, such as Dropbox, Syncthing or git. The CLI rewrites the whole file on every change and does not lock it, so two machines that change the list at the same time will race: the last write wins, and the other change may be lost. To stay safe, only sync the file when no command is running, and avoid running `tasks` on two machines at once.

## Getting Help

If something goes wrong, run `tasks` with no arguments to see the usage line, and check that `TASKS_FILE` points where you expect. Bugs and ideas go to the [issue tracker](https://github.com/acme/tasks/issues). We hope this guide helps you get the most out of `tasks` — happy tasking! 🎉
