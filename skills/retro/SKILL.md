---
name: retro
description: Review a coding session for what slowed or misled the agent, and propose fixes to its environment (checks, steering files, skills, tools, access), most costly first. Type /retro, or /retro <session> for a past one.
disable-model-invocation: true
---

# Retro

You review a session and propose changes to the agent's environment so the next run goes better: the checks, steering files, skills, tools and access the agent works with. The session's code is out of scope. You propose; the user picks which fixes to make.

## 1. Pin the session

Default to the current one; when the user names another, find its transcript. The session includes the agents it delegated to: read their transcripts too, since their friction never reaches the parent's. When the current session was compacted, read its transcript for the part the summary replaced.

Transcripts run to thousands of lines. When the `author-skills` skill is installed, its `scripts/sessions.sh show <path>` prints one line per event, numbered by transcript line. Hand a long transcript to a read-only subagent (`subagents` skill, Checker role) with the friction list below as its brief, and verify each moment it returns against the transcript.

Done when you know which transcript, or which part of this conversation, you are reviewing.

## 2. List the friction

Go through the session in order and write down each moment that cost something, with the turn or transcript line and a short quote:

- the user corrected the agent or repeated an instruction;
- a tool call failed, or was retried with a small change;
- the agent searched long for something a pointer would have found;
- a mistake reached the user or a reviewer that a check could have caught;
- a tool call returned far more output than the agent used;
- the agent guessed at something it could not see: logs, a service's state, a page;
- a skill fired and led the agent wrong, or did not fire when its work came up;
- an instruction from a steering file was ignored, or followed and wrong.

Done when every moment has evidence you could point the user to.

## 3. Read the environment

For each moment, read what was already there (steering files, the repo's checks, skills) before proposing anything new. A check that exists but is unwired or broken is the finding, not a new check. A repo with no guardrail, where neither a hook nor CI runs its lint, typecheck or tests, is a finding on its own.

## 4. Pick the fix

Give each moment the strongest fix that works, in this order:

| Fix | Use when | Where it goes |
| --- | --- | --- |
| Check | The mistake is mechanical: a banned API, an import shape, a file location, a missing step a script can detect. | The repo's linter, a hook or a CI job, whichever its tooling makes cheapest. |
| Tool or access | The agent lacked information (logs, a read-only service, a dev server's output) or paid too much for it (a noisy command, a token-heavy tool). | A script, a flag, an MCP server, a config change. |
| Pointer | The agent searched for something it could not have known where to find. | One line in the repo's `AGENTS.md` naming the file or doc. |
| Review rule | A judgment call a reviewer should catch: consistency across files, matching the surrounding style. | Where the reviewer reads it (its brief, a standards file the review loads), not in `AGENTS.md`, which every implementing agent pays for. |
| Skill change | A skill misled, missed a case, or did not fire. | That skill's source, changed with the `author-skills` skill. |
| Steering cut | A steering line changed nothing, contradicted another, or belongs in one of the rows above. | Delete or move it. |

Scope each fix to where the problem lives: one project's code, conventions or tools go in that project; the user's habits across projects go in their global files; a shared skill changes only for what holds beyond this project.

Wrong: the agent ran `npm test` when the repo uses `pnpm test:unit`, so `AGENTS.md` gains "use pnpm test:unit".
Right: the `test` script in `package.json` runs `test:unit`, so the obvious command works.

## 5. Weigh

Count sessions before you decide. For every finding, search other recent transcripts for the same moment:

- Search where the fix would apply: this project's transcripts for a project fix, every project's for a global file or a shared skill, since those travel with the user.
- Look for the same cause, whatever words it came in: several phrasings of what the user typed when it happened, and the command that failed. With the `author-skills` skill installed, its `scripts/sessions.sh find <skill> <terms>` searches prompts across Claude Code, Codex and Cursor.
- A fix already made closes a moment only when no session after that fix shows it again.

Then sort each finding by its count:

| Seen | Cost | Verdict |
| --- | --- | --- |
| 2 or more sessions | any | Propose. |
| once | costly: the user lost more than a few minutes, or a wrong result shipped | Propose only a check or a tool. A prose fix goes under dropped, with its cost. |
| once | cheap: a retry or a round trip fixed it | Drop. |

Also drop what the agent did wrong despite clear text, when it happened once: that is execution, not environment. Among fixes for one finding, one that deletes or moves a line beats one that adds a line.

## 6. Report

Reply short, most costly first, with at most seven proposals. Each gives the fix in one line and the file it changes, then the evidence: what happened, how often (sessions, not moments) and where you searched, and one short quote.

Then a line for each thing you dropped: why, and for "once", where you searched, since it claims no other session shows it. Ask which fixes to make. Make the picked ones: skill changes through the `author-skills` skill, the rest directly, each proved the way its kind is proved (a check fails on the original mistake, a pointer resolves, a tool returns what was missing). Ship them apart from the session's own work, with the `ship-changes` skill if it is installed.

Keep secrets and personal details out of the report and the fixes: steering files and skills get shared.
