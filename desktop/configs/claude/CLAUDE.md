# Secrets

Secrets/API keys live in `~/.env` (KEY=value per line). Never read this file
directly (Read/cat/grep are denied on it). When a command needs a secret from
it, source it inline in the same Bash call so the value only lives in that
subshell's env, never in your context:

```bash
set -a; source ~/.env; set +a; the-actual-command --using "$SOME_KEY"
```

Don't echo/print the sourced values back into your output.

# Git commits

Conventional Commits. Subject: `<type>[(scope)]: <description>`, `!` before
the colon for breaking changes.

Types: feat, fix, refactor, docs, style, test, perf, ci, build, chore.

- Description: imperative, lowercase first letter, no trailing punctuation, ≤65 chars total.
- Body only when it adds information the subject can't carry. Never restate the subject. Blank line before it, wrap at 72.
- Breaking change: `!` in the subject and/or a `BREAKING CHANGE:` footer.

# LLM Wiki

say I don't know if you don't know

Sometimes you may be asked to do a task. If there is ambiguity you should first evaluate doing the task and ask clarifying questions. 

Wiki at `~/Documents/llm-wiki/`. This is a Karpathy-pattern persistent knowledge base shared
with a bare git repo at `ubu-1:/srv/git/llm-wiki.git`.

**Before answering questions about Noah's context, projects, preferences, or past decisions:**
read `~/Documents/llm-wiki/index.md` first, then drill into relevant pages.

**Before any edit:**
```bash
git -C ~/Documents/llm-wiki pull --ff-only --quiet
```

**After any edit:**
```bash
git -C ~/Documents/llm-wiki add -A
git -C ~/Documents/llm-wiki commit -m "<concise summary>"
git -C ~/Documents/llm-wiki push --quiet
```

If pull fails (not fast-forwardable), surface the conflict rather than merging automatically.

Keep committing each edit yourself, with a real message — the hooks are a safety
net, not the way edits land. `hooks/wiki-sync.sh` pulls at session start and, at
session end, commits anything left over as `wiki: autosave` and pushes.

## Structure

- `index.md` — catalog of all pages (read first on any query)
- `log.md` — append-only record (`## [YYYY-MM-DD] operation | title`)
- `wiki/` — LLM-maintained pages
- `memory/inbox/` — auto memory writes here; `memory/archive/YYYY-MM/` holds
  promoted memories until they expire (6 months)
- `sources/` — raw immutable source material (never modify)

## Memory vs pages

Auto memory writes to the Inbox. Promotion happens when Noah runs the
`llm-wiki-lint` skill, never on its own:

- **feedback / user** memories → `wiki/personal/working-with-noah.md`, which is
  imported below, so it keeps loading every session. Keep it under ~60 lines.
- **project / reference** memories → the matching wiki page.
- **Rules that apply to one repo** belong in that repo's `CLAUDE.md`, not in a
  memory. The Inbox is global: everything in it loads in every project.

After promoting, move the raw memory to `memory/archive/<current YYYY-MM>/`.

@~/Documents/llm-wiki/wiki/personal/working-with-noah.md

## Ownership and Use

The wiki is **your (Claude's) primary workspace** for organizing knowledge across conversations. Write to it freely; don't ask permission for each addition.

- **Default action is to write.** Durable findings, decisions, ongoing project state, deferred work, and todos go in the wiki — without confirmation.
- **Keep it tidy.** Update existing pages over duplicating; refactor when a page sprawls; prune stale content; maintain `index.md` and `## Related` cross-links.
- **Track Noah's in-flight work.** Ongoing projects, deferred decisions ("not applying yet"), open questions, and follow-ups belong here so they survive into future sessions and Noah can see what's pending at a glance.
- **Discipline still applies.** Pull → edit → log → commit → push. Use the right topic directory. The autonomy is about not asking, not about skipping structure.
- **Ask first only if:** the topic is genuinely off-scope from anything in the wiki, OR you're considering deleting/relocating content Noah authored.
