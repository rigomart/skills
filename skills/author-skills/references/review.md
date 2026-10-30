# Review a skill or playbook

A skill's text says what it intends; past sessions show what it does. Review both, including the sessions that did the skill's work without it: a skill that never fires, or that the developer routes around because it fails, breaks nothing you can see. Judge each section by whether it earns its place: keep it, generalize it, move it to another skill, or cut it. A playbook is reviewed as part of the `do` skill, with terms for its requests.

## 1. Pin the skill

- **Every copy.** List where the skill is installed, following symlinks: `ls -l ~/.claude/skills/<name> ~/.agents/skills/<name> ~/.codex/skills/<name> ~/.cursor/skills*/<name> ~/.claude/plugins/cache/*/*/*/skills/<name> .claude/skills/<name> .agents/skills/<name> 2>/dev/null`. Find the source it is installed from (a skills repo, a plugin): that is the copy you review and the one a fix edits.
- **Drift.** Diff each installed copy against the source. A copy behind the source means sessions ran an older text. A copy with the same name but different content is a different skill competing for the name.
- **History.** `git log --format='%h %cs %s' -- <skill-dir>` in the source repo. Each session ran the version current on its date. A skill that moved between repos has history in both: follow it back.

Done when you have the source path, each installed copy and whether it matches, and the dated commits.

## 2. Review the text

Judge the skill by the design rules and the standard in `SKILL.md`, and validate it as `SKILL.md` says. Then check what reading cannot:

- Run each command, and open each path, script and skill name the skill gives, from where it says to run them.
- Write down what only sessions can settle ("is step 3 followed?", "does anyone ask for this as a redesign?") and take those questions into step 5.

Done when each finding cites a line of `SKILL.md` or a reference file.

## 3. Check overlap

Read the name and description of every installed skill, and the body of each one whose work sounds close. For each, look for:

- **Triggers:** a request that would fire both.
- **Rules:** the same rule, or its opposite, written in both (**One owner**).
- **Handoffs:** one skill doing or reaching into work another owns (**Reference the whole**, **Process in playbooks, judgment in skills**).

The `other-skills` column from step 4 adds evidence: skills that keep loading in the same sessions, or that pick up where this one stops. Give each overlap a verdict: **merge**, **sharpen the boundary** (descriptions that split the requests), **hand off by name**, or **fine**.

Done when every installed skill whose work is close has a verdict.

## 4. Find the sessions

Run [../scripts/sessions.sh](../scripts/sessions.sh) `find` with the skill's name and terms for its work. It searches the Claude Code, Codex and Cursor transcripts on this machine, in every project, since a skill travels with the user:

```bash
bash <author-skills-dir>/scripts/sessions.sh find ship-changes --since 2026-07-01 'open (a )?pr' 'gh pr create' 'push (it|this)'
```

- **Terms** are case-insensitive extended regexes matched against user prompts. Take them from the words people type for this work (the description's triggers, the first prompts of `used` rows) and from the commands it runs. Leave out words that appear in any session (`fix`, `test`, `change`).
- **`--since`** defaults to 90 days ago; reach back to the skill's first commit when it is younger or rarely used.
- **Groups:** `used`, `edited` (the session changed the skill's files), `named` and `similar`. The script's header explains every column.

Pick the sample:

- `used`: the 12 newest since the last substantive commit, plus up to 4 from before it to see whether that commit fixed what it meant to.
- `named`: all of them.
- `similar`: read the first prompts and keep up to 12 that are this skill's work, most hits first.
- Leave out `edited` sessions, sessions that only read the skill to write or compare skills, the session you are running in, and a `/subagents/` transcript whose parent is in the sample.

No `used` rows makes it a trigger review: the `similar` sessions are the evidence. Few `similar` rows: widen the terms once, then go with what you have.

Done when the sample is listed with each session's group and why you kept it.

## 5. Read the sessions

Transcripts run to thousands of lines, so readers do the reading. Split the sample into batches of up to 4 sessions and spawn one read-only Checker subagent per batch, in parallel, each with its model set by the `model-roles` skill (your session's model if it is not installed). Each prompt is [session-reader.md](session-reader.md), verbatim, followed by the skill's source folder, the absolute path to `sessions.sh`, the dated commits, the questions from step 2, and the batch: path, group and date per session.

Without a subagent tool, apply `session-reader.md` yourself, one session at a time, and say in the report that no independent reader ran.

## 6. Verify and weigh

- **Verify each finding** with `sessions.sh show <path> <line - 5> <line + 20>`. Drop it when the quote is not there or does not say what the finding claims.
- **Check it against the current text.** A finding from a session that ran an older version is closed when a later commit fixed it.
- **Count sessions, not findings,** as **A repeat before a rule** says.
- **`ignored` in two or more sessions is a text problem:** the rule is buried, phrased as a prohibition, or contradicted elsewhere, or it needs a check (**Encode in structure**). Once is execution: drop it.
- **Patched before?** When the history shows an earlier fix in the same area, find the premise both share before proposing another (**Subtract before you add**).
- **Give each section of the skill a verdict**: keep, generalize (the rule applies beyond this skill), move, or cut. A section no session reached is a cut unless the text review shows it guards something rare and costly.
- **Move goes where the work goes.** When sessions use a section for work beyond this skill, it moves to the skill that owns that work, or to a new skill when none does. When only this skill uses it, and rarely, it moves to one of its reference files.

## 7. Report

Write the evidence to `.skill-reviews/<name>.md` in the source repo, excluded from git through the file `git rev-parse --git-path info/exclude` prints: every verified finding with its `path:line` and quote, the section verdicts with the sessions that reached each section, the overlap evidence, the `similar` sessions' first prompts, and coverage (rows per group and agent, sessions read, the date range, installed copies that drift, whether independent readers ran).

The reply stays short, with no transcript paths or line numbers:

- **Verdict**, in a sentence: whether the skill fires when it should, and whether it earns its place when it does.
- **Changes**, at most five, most sessions first: the change in one line, then the session count and one short quote.
- **Overlap**: a table of skill, where they overlap, verdict. Leave it out when nothing overlaps.
- **Coverage**, in one line, ending with the evidence file's path.

Keep secrets and personal details out of both: the evidence may land in a PR, and the fixes in a published skill.

Ask which changes to make. Make them as [write.md](write.md) says, starting from the evidence file.
