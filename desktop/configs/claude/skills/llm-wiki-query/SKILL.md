---
name: llm-wiki-query
description: Use when searching the llm-wiki for information about Noah's context, projects, preferences, past decisions, or any topic covered by the wiki
---

# llm-wiki-query

Don't read the wiki yourself. Ask the `librarian` subagent (Agent tool,
`subagent_type: "librarian"`) with the question in plain words, e.g. "What did
Noah decide about the Alacritty terminal, and is it still pending?". It reads
`index.md`, the hubs and pages in its own context and returns a short answer
citing page paths, flagging anything that looks stale.

Read a cited page yourself only when you need its full text, e.g. to edit it.
If the librarian says the wiki doesn't cover something, say "I don't know".
