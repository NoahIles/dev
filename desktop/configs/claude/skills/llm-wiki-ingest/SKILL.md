---
name: llm-wiki-ingest
description: Use when adding new information, sources, notes, articles, or decisions to the llm-wiki knowledge base for persistence across conversations
---

# llm-wiki-ingest

## Overview

Process new sources into the wiki — extract key facts, update or create pages, and commit.

## Workflow

**1. Pull latest wiki**

```bash
git -C ~/Documents/llm-wiki pull --ff-only --quiet
```

If pull fails (not fast-forwardable), stop and surface the conflict — do not merge automatically.

**2. Read schema and index**

Read `~/Documents/llm-wiki/schema.md` and `~/Documents/llm-wiki/index.md`.

**3. Accept source**

If the user has not provided a source, ask:
> "What would you like to ingest? Provide a file path, URL, or paste the content directly."

**4. Extract and synthesize**

- Identify key facts, decisions, preferences, and context worth persisting
- Determine which topic area (`wiki/<dir>/`) this belongs to per `schema.md`
- Decide: update an existing page, or create a new one?

**5. Archive plan sources**

If the ingested material is, or is derived from, a plan (e.g. a plan-mode plan, an implementation plan, a migration plan), copy the plan verbatim into `sources/plans/` before synthesizing:

```
sources/plans/YYYY-MM-DD-<slug>-plan.md
```

- Use today's date and a short kebab-case slug
- `sources/` is immutable — never edit the file after adding it
- Every wiki page created or updated from the plan must link to it under `## Related` (e.g. `[plan source](../../sources/plans/2026-06-10-foo-plan.md)`)

**6. Update or create pages**

- Edit relevant existing pages or create new ones under the correct `wiki/` subdirectory
- Follow the page structure template in `schema.md`
- Update `## Related` cross-references where applicable

**7. Update root index.md and pending.md**

- Add or update the catalog entry for any new or renamed pages.
- If the material starts, advances, or completes an in-flight item, update `wiki/pending.md`.
- If a root-level `Clippings/` inbox exists, sweep it: move files to `sources/clippings/` (kebab-case rename) and ingest them per `schema.md`.

**8. Append to log.md**

```
## [YYYY-MM-DD] ingest | <title>
```

**9. Commit and push**

```bash
git -C ~/Documents/llm-wiki add -A
git -C ~/Documents/llm-wiki commit -m "ingest: <concise summary>"
git -C ~/Documents/llm-wiki push --quiet
```

## When to Create vs Update

- **Update** an existing page when the new info is closely related to content already there
- **Create** a new page when the topic is distinct, or adding to an existing page would push it past ~300 lines
