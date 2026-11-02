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

Run the checker first; it covers everything in this step except unswept clippings:

```bash
python3 ~/Documents/llm-wiki/scripts/check.py
```

Errors are what the pre-commit hook blocks on; warnings (pages over ~300 lines)
are split candidates. What it checks, for reference:

- **Orphans:** files in `wiki/` (except `pending.md` and hubs) with no hub-table row, or no `hub:` frontmatter, or a `hub:` that disagrees with the table they're in

  ```bash
  find ~/Documents/llm-wiki/wiki -name "*.md" | sort
  ```

  Cross-reference with all links in the hub tables. Also check every hub is in the `index.md` hub table.

- **Phantoms:** hub-table or `index.md` rows whose linked files do not exist on disk
- **Frontmatter:** pages missing `hub`/`status`/`updated`, or with a status outside current|historical|archived
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
- **Cold pages:** pages never read in recent sessions *and* with an old `updated:`
  are candidates to archive or merge. Read counts come from Claude Code
  transcripts (Read/Edit calls only; misses shell `cat` and Obsidian, and
  transcripts expire):

  ```bash
  grep -ohE '"file_path":"[^"]*llm-wiki/wiki/[^"]+\.md"' -r --include='*.jsonl' ~/.claude/projects \
    | sed -E 's/.*llm-wiki\/wiki\///;s/"$//' | sort | uniq -c | sort -rn
  ```

  Pages absent from the output have zero reads. Treat it as a hint, not a verdict.

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

Promotion only runs inside this skill. Pick a destination per memory and do it,
then report where each went:

```bash
month=$(date +%Y-%m)
mkdir -p ~/Documents/llm-wiki/memory/archive/$month
git -C ~/Documents/llm-wiki mv memory/inbox/<file>.md memory/archive/$month/
```

Drop the memory's line from `memory/inbox/MEMORY.md` in the same pass. Report
the Inbox index's line count — over ~150 it's close to the 200-line load limit.

**5. Report findings**

Summarize the findings (and, after step 6, what was fixed):

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

**6. Fix**

Apply the fixes yourself without asking: this is Claude's wiki as much as
Noah's (his words, 2026-11-02). Ask first only before deleting or relocating
content Noah authored, or when a fix needs a fact you don't know (say so).
Report what you changed afterwards.

**7. Commit and push** (only if fixes were applied)

```bash
git -C ~/Documents/llm-wiki add -A
git -C ~/Documents/llm-wiki commit -m "lint: <summary of fixes>"
git -C ~/Documents/llm-wiki push --quiet
```
