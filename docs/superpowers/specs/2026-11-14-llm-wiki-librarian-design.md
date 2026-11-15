# llm-wiki librarian: design

Date: 2026-11-14. Status: approved by Noah 2026-11-14.
Wiki tracking page: `~/Documents/llm-wiki/wiki/linux/llm-wiki-librarian.md`.

## Intent

Noah is handing upkeep of the llm-wiki (`~/Documents/llm-wiki`, bare repo
`ubu-1:/srv/git/llm-wiki.git`) to a dedicated agent. Today lint only happens
when he runs the `llm-wiki-lint` skill (last: 2026-11-09; 18 inbox memories
waiting at the time of writing), and every agent that needs wiki context
reads pages into its own context.

**Success after a month (Noah's words):** fewer mistakes from stale
information, and less context pollution from research tasks.

## Goals

1. **Reference desk.** A custom subagent type, `librarian`, that any agent
   can ask ("what did Noah decide about X?", "is there a page on Y?"). It
   reads the wiki in its own context and returns a short answer citing
   pages. If it notices the answering page is stale, it **answers now and
   queues the fix** for maintenance; it does not edit pages on this path.
2. **Maintenance.** The same agent, run headless in the background, does
   what `llm-wiki-lint` does today (promote inbox memories, sync hubs/index/
   pending, find contradictions and stale claims) and works the queue.
3. **Check owner.** It maintains and grows `scripts/check.py` (the wiki's
   pre-commit check) over time: findings that keep recurring become
   deterministic rules, so the free hook catches them and paid runs don't
   have to. Goal: reliability, quality and usability of the wiki.
4. **Not wasteful.** It wakes on a metric, not on every commit.

## Non-goals (v1)

- **Discord and email escalation.** Deferred. Jerry (the old Discord bot)
  was decommissioned for lack of use and maintenance; a selectively enabled
  Discord skill/MCP is a separate pending item in the wiki.
- Running on `ubu-1` or any machine other than the desktop.
- Replacing the session hooks (`wiki-sync.sh`, `memory-checkpoint.sh`).

## Anti-goals

- A librarian that costs more than it saves: frequent wakeups that find
  nothing, or a reference desk that returns page dumps instead of answers.
- Silent changes to rules every agent must obey (`check.py`, `CLAUDE.md`,
  `working-with-noah.md`) without Noah seeing them.
- A new check rule that blocks Noah's commits because it was wrong.
- Moving or deleting content Noah authored without asking (existing wiki
  rule).

## Decided by Noah

- Two roles from one agent definition (reference + maintenance), plus
  ownership of the pre-commit checks.
- Wake on a metric, not per commit.
- Stale page seen while answering: answer now, queue the fix.
- Disable every skill not relevant to the librarian.
- Escalation = desktop notification with a button, like `claude-outbox`;
  clicking it opens a Claude session to resolve the issue.
- **Live facts via a host-side step.** Before a maintenance run, a small
  read-only host-side script gathers the live facts that pending items and
  hub `## Now` sections claim (e.g. `~/nixos` git refs, unit states) into a
  file the boxed run reads. The box itself stays as is.
- **Rewrite the global `CLAUDE.md` "LLM Wiki" section** (in
  `desktop/configs/claude/CLAUDE.md`) so agents ask the `librarian`
  subagent for wiki *reads* instead of reading `index.md` and pages
  themselves. Writes and ingest stay as today. This is in scope.
- **Promotion split.** The librarian promotes **project** and **reference**
  memories to topic pages on its own. **Feedback**, **user** and repo-rule
  memories (which go to `working-with-noah.md` or a repo's `CLAUDE.md`) are
  escalated. The global `CLAUDE.md` line "Promotion ... never on its own"
  is updated to match.

## Claude's calls (Noah to confirm)

Data behind the wake metric: 2026-10-15..11-14 the wiki averaged ~13
commits/day, bursty (1 to 44 a day), so per-commit runs are ruled out.

- **Debt score.** Computed by the timer at check time from git history
  since the librarian's last `lint:` commit (no commit hook, so commits
  pulled from other machines count too, and nothing is stored): new files
  in `memory/inbox/` + wiki pages changed + lines in the queue file +
  `check.py` warnings. Cheap shell/Python, no LLM.
- **Wake rule.** A systemd user timer (every ~15 min) starts a maintenance
  run only when score ≥ threshold **and** the last wiki commit is ≥30 min
  old **and** no Claude session is running. (The boxed launcher runs
  `git add -A` on exit, so a run during an open session could commit
  Noah's half-finished wiki edits.) Threshold starts at a value tuned so it
  wakes roughly once a day at the current commit rate; the librarian may
  propose changes to it like any other rule.
- **Measure of its own value.** Each run logs score, findings and fixes
  (in its commit message); runs per week falling over time means the checks
  are absorbing the work.
- **Queue.** `memory/librarian-queue.md`, one line per item: page, what
  looks wrong, evidence, date. The reference desk's only write, enforced by
  a `PreToolUse` hook in the agent definition that blocks Edit/Write
  outside the queue file unless the run is a maintenance run (e.g. an env
  var the timer sets). Queue lines are left for the normal session-end
  wiki autosave rather than committed by the reference desk.
- **Definition.** `desktop/configs/claude/agents/librarian.md` in `~/nixos`,
  linked to `~/.claude/agents` by `desktop/modules/home/claude.nix` (new
  `".claude/agents" = link "agents";`). The box already exposes
  `~/.claude/agents` read-only (`claude-box.nix:96`).
- **Skills off.** Its `tools:` list omits `Skill`, so no other skill loads;
  the rules of `llm-wiki-lint` / `llm-wiki-ingest` are preloaded via the
  frontmatter `skills:` field. Builder must verify both fields against
  current Claude Code docs before relying on them.
- **Tools.** Read, Grep, Glob, Edit, Write, and Bash limited to `git` and
  `python3 scripts/check.py`. Writes confined to the wiki.
- **Models.** Haiku for the reference desk, Sonnet for maintenance (needs
  judgement). One agent file can carry one `model:`; the timer can override
  with `--model`. Builder decides the mechanism.
- **Runs boxed.** Maintenance runs inside the boxed `claude` launcher
  (wiki writable, nothing else). Headless: `claude --agent librarian -p
  ...` from the wiki dir (verify the flag).
- **Escalation.** For anything uncertain (contradictions, stale pending
  items, moving Noah's content, feedback/user/repo-rule promotions, any
  change to `check.py`, `CLAUDE.md` or `working-with-noah.md`), the run
  stops short of the change. **One notification per run**, listing all its
  items, sent host-side after the run (`notify-send -a Librarian` with an
  action button). The button opens a terminal running
  `claude --resume <session id>` in the wiki dir, so Noah lands in the
  session that holds the evidence; items needing `~/nixos` edits resume in
  `claude-host` instead. Unhandled items stay in the queue file; later
  runs notify only for new items.
- **Rule lifecycle.** The librarian **drafts** `check.py` changes and never
  commits them: `check.py` runs as the pre-commit hook in Noah's unboxed
  sessions, so a boxed agent committing to it would get around the box.
  Noah applies them from the escalation session. New rules start as
  warnings, each with a comment naming the finding that motivated it;
  making a rule an error is another drafted change.
- **Commits.** `lint: <summary>`, then push, same discipline as the wiki
  `CLAUDE.md`. If pull is not fast-forward, escalate instead of merging.
- **`llm-wiki-query` skill** becomes a pointer to the librarian subagent
  (or is removed) once the reference desk works.
- **Other machines.** Only this desktop runs the librarian; commits from
  elsewhere are covered because the score is read from git history.

## Constraints

- Wiki sync: pull `--ff-only` before edits, commit + push after; boxed
  sessions skip pull/push because the launcher syncs.
- `~/nixos` rules: worktree, `just check` before merging to `nixos`, never
  `git add -A` there, rebuild via `rebuild.sh`. Noah pushes `~/nixos`.
- The timer and notifications are host-side (systemd user unit, D-Bus);
  the box has no session D-Bus, so `notify-send` must be called outside it
  (e.g. the launcher or a wrapper script after the run, as `claude-outbox`
  does).
- `working-with-noah.md` stays under ~60 lines.

## Left to the builder

- Exact score weights and threshold.
- Which live facts the host-side step collects, as long as it is read-only.
- How "no Claude session is running" is detected.
- Queue file format details.
- Timer unit layout and the button wrapper script.
- Prompt wording of the agent definition.
- Order of work, as long as the reference desk can ship before maintenance.
