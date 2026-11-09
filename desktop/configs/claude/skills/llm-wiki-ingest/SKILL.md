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
- Determine which hub (`wiki/hubs/`) and topic directory (`wiki/<dir>/`) it belongs to per `schema.md`
- Decide: update an existing page, or create a new one?
- **Conflict sweep.** List the concrete entities the new material touches
  (hostnames, IPs, package or driver versions, paths, repo/branch names, service
  states) and grep the whole wiki for each:

  ```bash
  grep -rn -i '<entity>' ~/Documents/llm-wiki/wiki ~/Documents/llm-wiki/wiki/pending.md
  ```

  For every page that mentions one, decide: **update** it (new fact supersedes;
  move the old one to dated history), **leave** it (still true), or **flag** it
  in your report if you can't tell. Hub `## Now` paragraphs count.

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
- Give every page the frontmatter from `schema.md` (`hub`, `status`, `updated`); bump `updated` on a substantive edit
- Put current state first; add history as dated sections below
- When you verified a claim against the live system, write `(checked YYYY-MM-DD)` next to it
- Long one-shot research reports go verbatim to `sources/research/YYYY-MM-DD-<slug>.md`; the wiki page keeps the answer and links there
- Update `## Related` cross-references where applicable

**7. Update the hub and pending.md**

- Add or update the page's row in its hub's `## Pages` table; rewrite the hub's `## Now` paragraph if the state changed.
- New hub only when none fits: create it in `wiki/hubs/` and add it to the `index.md` hub table.
- If the material starts, advances, or completes an in-flight item, update `wiki/pending.md`. Every open item (in a hub `## Now` or a page status) needs a row there; `check.py` warns otherwise.
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
