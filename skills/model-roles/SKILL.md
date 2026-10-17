---
name: model-roles
description: Pick a subagent's model by its role (Scout, Checker, Implementer, Engineer, Investigator, Reviewer), decided from criteria checked before the spawn, and set it on the spawn, on Claude or OpenAI models. Use when spawning a subagent or delegating work, or when a skill names one of these roles.
---

# Model roles

Every subagent gets a role before it is spawned, and the role alone sets its model. Decide the role from what the work is, look up the role's model, and set it. When work turns out harder than its role, it was another role all along: move it there.

## Roles

| Role | Use when |
| --- | --- |
| Scout | It finds, lists, counts, extracts, or runs a known command and reports what came back. A wrong answer is obvious at a glance. |
| Checker | It applies a closed list of rules to given work, and you verify each finding by reading it. |
| Implementer | It edits, and all of these hold: the spec is complete, an existing pattern shows the way, it stays inside known files, and a test or typecheck shows whether it worked. |
| Engineer | It edits, and any Implementer condition fails: the spec has gaps or needs nuance, the change crosses modules or touches a contract, schema, auth or stored data, or a mistake is expensive to unwind. |
| Investigator | The answer is not known yet: a root cause, design options, architecture, open research, how an unfamiliar part of the system works. |
| Reviewer | It gives a verdict you will rely on without redoing the work: open-ended code review, adversarial or security review, comparing options, breaking a tie. |

## Pick the role

1. **It edits files:** Implementer when every Implementer condition holds, otherwise Engineer. A condition you cannot confirm from the brief or the code counts as failing.
2. **It only reports:** Scout, Checker, Investigator or Reviewer, by the table.
3. **It fits two roles:** take the one with the larger model.
4. **It spans two roles** (an unsettled design, then building it): make it two subagents, an Investigator first, then an Implementer or Engineer with the settled result.

Name each subagent's role in your plan or its prompt before you spawn it.

## Models

| Role | Claude | OpenAI |
| --- | --- | --- |
| Scout | Haiku | Luna |
| Checker, Implementer | Sonnet | Sol |
| Engineer, Investigator, Reviewer | Opus | Sol |

- **Latest version of the family.** The table names families. Use the newest version of each that the spawn tool offers: the highest version number among its models of that family.
- **Your session's provider.** Subagents run on the provider your session runs on, except the Reviewer.
- **The Reviewer crosses over.** It runs on the other provider from the one that did the work, so its verdict is independent. When the environment cannot spawn on the other provider, it runs on the same one, and you say so.
- **Only these families.** Fable and Astra, the frontier families, run a subagent only when the user asks for one on that work. Reach the other provider only through a tool built for subagents on it, never by shelling out to a CLI (`codex exec`, `claude -p`).
- **Effort is high** on every spawn where the tool takes one, whatever the role.
- **Never above your session.** When your session runs on a mid-size model (Sonnet), roles that call for a larger one run at mid size, in either column, and the plan says so. A small session (Haiku, Luna) runs everything at small size.
- **Missing model.** When a role's family is not offered, use the next larger one in the same column. When the spawn tool cannot set a model at all, spawn anyway and say so.
- **A failed run is reclassified.** When a run fails your check, sharpen the prompt first. When a sound prompt fails twice, the work met another role's criteria: rerun it under that role. A retry never moves to a smaller model.
- **Agent types that pick their own model.** Leave the model unset for an agent type whose definition sets `model:` (`.claude/agents/*.md`, `~/.claude/agents/*.md`, a plugin's agents) or one the user configured. Set it for every other spawn: unset usually means your session's model, which skips the role.
