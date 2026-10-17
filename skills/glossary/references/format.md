# Glossary format

## GLOSSARY.md

```md
# {Context name}

{One or two sentences: what this context is and who uses it.}

## Language

### {Cluster, when terms group naturally}

**Project**:
A body of work a team plans and tracks together. Holds Tasks and has Members.
_Avoid_: workspace, space, board
_Code_: `Workspace`

**Task**:
One piece of work inside a Project, with at most one Assignee.
_Avoid_: ticket, issue, card

**Member**:
A person with access to a Project. A User becomes a Member when invited.
_Avoid_: collaborator, participant

## Relationships

- A **Project** holds many **Tasks** and many **Members**
- A **Task** has at most one **Assignee**, who is a **Member** of its **Project**

## Flagged ambiguities

- "Owner" is used both for the Member who created a Project and for the Assignee of a Task. Open: the creator keeps "Owner"; what to call the Assignee everywhere else.
```

## Rules

- **Entry.** The bold term, a colon, then one or two sentences that say what it is. Capitalize terms where they appear in other entries, so a reader sees which words are defined.
- **`_Avoid_`.** The other names the concept has had, lowercase, comma-separated. Omit the line when there are none.
- **`_Code_`.** Only when the code names the concept differently from the term. Delete it once the code is renamed.
- **Clusters.** Group terms under `###` headings when clear clusters emerge; a flat list is fine for a small glossary.
- **Relationships.** Short bullets that name how terms connect, with cardinality where it matters. Omit the section until there is something to say.
- **Flagged ambiguities.** Each open question: the word, its competing meanings, and what is decided so far. When one is settled, move the result into the entries, and keep a one-line "Resolved:" bullet only if the old usage is still common enough to confuse people.

## GLOSSARY-MAP.md

For a repo with several contexts. Each context keeps its own `GLOSSARY.md` beside its code.

```md
# Glossary map

## Contexts

- [Planning](./src/planning/GLOSSARY.md): projects, tasks and who works on them
- [Billing](./src/billing/GLOSSARY.md): plans, invoices and payment

## Relationships

- **Planning → Billing**: a Project's Members count toward the Organization's seats
- **Shared**: `OrganizationId` names the same Organization in both contexts
```

When a topic touches several contexts, read each one it touches. When it is unclear which context a term belongs to, ask.
