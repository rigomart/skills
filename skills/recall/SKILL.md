---
name: recall
description: Rebuild where work stands from live state, the repo's record and past chats, and brief a user who has forgotten the details. Use when asked for status, what's pending or next, where things were left, or to be caught up.
---

# Recall

You find out where the work stands now and brief a user who may remember none of it. You change nothing while you recall: the brief ends on a next move, and the user picks it.

## Scope

The scope is what the question names (a feature, an issue, a goal such as a release), or the work in front of you when it names nothing. Running work keeps running while you answer.

The window defaults to the last 7 days for chat history, and the workspace to this repo, every worktree of it. Read another project's chats only when the user asks. "All" stays all: never turn it into the last few without saying so.

## Sources

Take them in this order and stop when the scope is answered.

1. **Live state.** What runs now: background commands, subagents, delegated tasks and their threads. Then the work in progress: `git status`, branches ahead of the default branch, open PRs with `gh pr list` and their checks with `gh pr checks <n>`, and any notes under `.evidence/` (a fleet ledger, research notes, evidence files). A fleet ledger is the record for its items: start from it.
2. **The repo's record.** Open issues and milestones (`gh issue list`), recently merged and closed PRs, `git log` since the last release tag, release and deploy config, and the latest deploy and release workflow runs (`gh run list`). A feature with a long bug tail keeps most of its story here: the fixes that were reverted and the symptoms that keep coming back.
3. **Past chats.** Run [scripts/sessions.sh](scripts/sessions.sh) from inside the repo: `bash <this folder>/scripts/sessions.sh [--days N] [<term>...]`. It lists Claude Code and Codex sessions from every worktree, newest first, with each one's first and last prompt; terms keep the sessions whose prompts match. Skip the current chat (usually the newest row). For one or two sessions, read them yourself. For more, give slices to Scouts (`subagents` skill), each told to read only the sessions matching the topic and return one block per session: the user's goal, decisions made, what was left open, corrections the user made, and the PRs, issues and branches it touched, each citing the session's path. Their transcripts stay with them; you get the blocks.

For each blocked thread, look in the past chats for the same block and how it was cleared last time, and put that on its line.

Check every claim from a chat against live state before it goes in the brief. A chat that says a PR is open was true when it was written: `gh pr view <n> --json state,mergedAt` says what it is now.

Done when every thread in scope has a status you checked today, or is marked unchecked with what would check it.

## The brief

Write it for someone who stepped away and forgot the details. Plain terms: say what a thing does, not only its issue number or internal name ("the fix for the empty export, #12", not "#12"), and no shorthand coined during the work.

1. **Where it stands,** in one or two sentences: what is running right now, if anything, and the overall state. "Nothing is running. I'm waiting on your call on two failing tests."
2. **What this is,** in up to three bullets: the goal and how far along it is.
3. **Threads,** one line each, starting with one of `[merged #N]`, `[open PR #N, checks <state>]`, `[in flight <branch>]`, `[uncommitted]`, `[reverted #N]`, `[blocked: <on what>]` or `[not started]`.
4. **Needs you,** split into decisions (each with your recommendation) and the things only the user can do: listen, test on a device, set a secret, approve a release.
5. **What I can do,** the work you could take next without them.
6. **Next move,** the single most useful action, concrete.

Put anything with a deadline at the top of its section, with the date. A problem that keeps coming back or a fix that was reverted goes on its thread's line, so the next attempt starts where the last one failed. Leave out adjacent work unless it blocks this. Leave out a section with nothing in it. When the brief outgrows a screen, cut detail before you cut threads.

Write the brief through the `unslop` skill if it is installed, and keep private details out of anything that leaves the machine.
