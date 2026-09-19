---
name: llm-wiki-query
description: Use when searching the llm-wiki for information about Noah's context, projects, preferences, past decisions, or any topic covered by the wiki
---

# llm-wiki-query

## Overview

Search the wiki, synthesize an answer, and optionally file novel results back as a new page.

## Workflow

**1. Pull latest wiki**

```bash
git -C ~/Documents/llm-wiki pull --ff-only --quiet
```

**2. Read index**

Read `~/Documents/llm-wiki/index.md` to identify which pages are relevant to the query.
If unsure which section to look in, read `schema.md` first.

**3. Read relevant pages**

Read each relevant page in full. Do not stop at the first — read all candidates before synthesizing.

**4. Synthesize and answer**

Combine the relevant content into a direct answer to the query.

**5. Offer to file back**

If the synthesized answer is novel (not already captured in any page) and likely to be useful again, ask:
> "This answer isn't directly in the wiki yet. Want me to ingest it as a new page?"

If yes, follow the llm-wiki-ingest workflow (pull → synthesize → create page → update index → log → commit/push).
