---
name: llm-wiki-lint
description: Use when health-checking the llm-wiki for orphaned pages, phantom index entries, internal contradictions, or stale content
---

# llm-wiki-lint

## Overview

Audit the wiki for structural and content issues, then fix with user confirmation.

## Workflow

**1. Pull latest wiki**

```bash
git -C ~/Documents/llm-wiki pull --ff-only --quiet
```

**2. Read schema and index**

Read `~/Documents/llm-wiki/schema.md` and `~/Documents/llm-wiki/index.md`.

**3. Structural check**

Compare files on disk against entries in `index.md`:

- **Orphans:** files present in `wiki/` but not listed in `index.md`

  ```bash
  find ~/Documents/llm-wiki/wiki -name "*.md" | sort
  ```

  Cross-reference with all links in `index.md`.

- **Phantoms:** entries in `index.md` whose linked files do not exist on disk
- **Broken links:** relative `](...)` links in any wiki page that resolve to a missing file
- **Naming violations:** files in `wiki/` not matching lowercase-hyphen `.md` naming
- **Unswept inbox:** files in a root-level `Clippings/` directory (should be swept to `sources/clippings/` and ingested per `schema.md`)

`memory/` is not part of the page catalog: never flag files under
`memory/inbox/` or `memory/archive/` as orphans, and never add them to
`index.md`.

**4. Content check**

Read all wiki pages and flag:

- **Contradictions:** statements across pages that are mutually inconsistent
- **Stale references:** mentions of paths, hostnames, repo names, or configurations that appear to have changed based on other pages
- **Stale pending entries:** rows in `wiki/pending.md` whose linked page says the item is done or has changed state
- **Log violations:** entries in `log.md` out of chronological order or using operations outside the schema list; any per-section `log.md` under `wiki/` (only the root log is allowed)

**4b. Memory promotion**

Read every file in `~/Documents/llm-wiki/memory/inbox/` except `MEMORY.md`.
For each one, propose a destination from its `type`:

- `feedback` / `user` → `wiki/personal/working-with-noah.md`. That page is
  imported by the global `CLAUDE.md` and loads every session, so keep it under
  ~60 lines: merge with an existing entry where you can, and tighten the wording
  rather than appending verbatim.
- `project` / `reference` → the matching wiki page (create one only if no page
  fits).
- Anything that only applies to one repo → that repo's `CLAUDE.md`, not the
  wiki. Say which repo.
- Stale or superseded → drop it, and say why.

Promotion is never automatic. Propose a destination per memory, get
confirmation, then:

```bash
month=$(date +%Y-%m)
mkdir -p ~/Documents/llm-wiki/memory/archive/$month
git -C ~/Documents/llm-wiki mv memory/inbox/<file>.md memory/archive/$month/
```

Drop the memory's line from `memory/inbox/MEMORY.md` in the same pass. Report
the Inbox index's line count — over ~150 it's close to the 200-line load limit.

**5. Report findings**

Present a summary before making any changes:

```
Structural issues:
  Orphans: N  (list files)
  Phantoms: N  (list index entries)
  Broken links: N  (list page + target)
  Naming violations: N  (list files)
  Unswept clippings: N  (list files)

Content issues:
  Contradictions: N  (list page pairs + description)
  Stale references: N  (list page + what's stale)
  Stale pending entries: N  (list rows)
  Log violations: N  (list entries)

Memory inbox:
  Memories: N  (index is M lines)
  Proposed promotions: N  (list memory -> destination)
```

If zero issues: report "Wiki is clean." and stop.

**6. Fix with confirmation**

For each issue, propose the specific fix and ask for confirmation before applying.
Never batch-apply all fixes without per-issue confirmation.

**7. Commit and push** (only if fixes were applied)

```bash
git -C ~/Documents/llm-wiki add -A
git -C ~/Documents/llm-wiki commit -m "lint: <summary of fixes>"
git -C ~/Documents/llm-wiki push --quiet
```
