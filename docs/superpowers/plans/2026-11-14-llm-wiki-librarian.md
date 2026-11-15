# llm-wiki librarian: implementation plan

Spec: `docs/superpowers/specs/2026-11-14-llm-wiki-librarian-design.md`
(approved 2026-11-14). Work on branch `librarian-spec` (worktree
`.claude/worktrees/librarian-spec`); one commit per task; `just check`
before each merge into `nixos`; rebuild with `rebuild.sh` from `claude-host`
(`PATH=/run/wrappers/bin:/run/current-system/sw/bin:$PATH ./rebuild.sh`).
The reference desk (tasks 1–3) ships and gets used before maintenance
(tasks 4–7) starts.

Verified 2026-11-14 against code.claude.com/docs/en/sub-agents: frontmatter
supports `tools`, `disallowedTools`, `model`, `skills` (full skill content
preloaded), `hooks` (incl. `PreToolUse`), `omitClaudeMd`, `maxTurns`;
omitting `Skill` from `tools` stops skill invocation; `claude --agent
<name>` runs the main thread as that agent. The two undocumented points
were settled by task 0 (results below it).

**Security rule for every task:** anything that runs on the host (timer,
score, facts, notify) lives in `~/nixos`, never in the wiki. The boxed
librarian can commit to the wiki, so wiki code run by the host would let it
out of the box. `check.py` is the existing exception, handled by the
draft-only rule.

## Task 0: spike the unknowns (throwaway, from `claude-host`)

1. Write a scratch `~/.claude/agents/librarian-spike.md` by hand (`tools:
   Read, Grep`, `skills: [llm-wiki-query]`, `model: haiku`, a `PreToolUse`
   hook that logs to a scratch file).
2. Check, each with one `claude --agent librarian-spike -p ...` call:
   - preloaded skill text is visible to the agent with `Skill` omitted;
   - `--model sonnet` overrides `model: haiku` (ask the agent its model;
     check `--output-format json`);
   - the frontmatter hook fires under `-p` for a **user-level** agent (the
     trust caveat in the docs is for project agents);
   - the boxed `claude` launcher runs from a `systemd-run --user` unit
     (no TTY), with an env var passed through, and returns `session_id`.
3. Delete the scratch agent. Record results in the wiki tracking page. If
   `--model` doesn't override, fall back to two agent files sharing one
   prompt file (`librarian` haiku, `librarian-maint` sonnet).

**Results (done 2026-11-14, Claude Code 2.1.325):**

| Check | Result |
|---|---|
| `skills:` preload, `Skill` omitted | **Works as a subagent** (Agent tool): skill text in context. **Not under `--agent`** (main thread), even with `Skill` listed. |
| `--model sonnet` over `model: haiku` | Overrides. One agent file is enough. |
| Frontmatter `PreToolUse` hook, `-p`, user-level agent | Fires; payload has `agent_type`. |
| Boxed `claude` from `systemd-run --user --wait --pipe` | Works: `CLAUDE_BOXED=1`, `-E` env passes, JSON has `session_id`. |
| `tools:` | Enforced (init listed only the allowed tools). |

Consequences for later tasks:
- Maintenance (`--agent`) does not get the preloaded skills: its prompt
  must `Read ~/.claude/skills/llm-wiki-lint/SKILL.md` (and ingest) first.
- User-level hooks still run inside the librarian: the TTS
  `UserPromptSubmit` hook appended a 🔊 line to every result, and
  would speak every background run. Skip the TTS hooks when
  `LIBRARIAN_MAINT` is set or the agent is `librarian` (task 6).
- Headless calls need `< /dev/null` (else a 3 s stdin wait), and
  `systemd-run` needs absolute paths (`%h` isn't expanded on the CLI).
- `systemd-run`/`claude` aren't on `claude-host`'s tool PATH: call
  `/run/current-system/sw/bin/systemd-run` and
  `/etc/profiles/per-user/noah/bin/claude` (units get their own PATH).

## Task 1: agent definition and link

- `desktop/configs/claude/agents/librarian.md`: frontmatter `name`,
  `description` (short: "Ask about Noah's context, projects, past decisions
  or wiki pages; returns a cited answer"), `tools: Read, Grep, Glob, Edit,
  Write, Bash`, `model: haiku`, `skills: [llm-wiki-lint, llm-wiki-ingest]`,
  `omitClaudeMd: true` (its rules come from the preloaded skills plus the
  prompt; drops the global CLAUDE.md tokens), `hooks.PreToolUse` → the
  guard in task 2.
- Prompt body: two modes. Reference (default): read `index.md` → hub →
  pages, answer in ≤ ~10 lines with page paths; on noticing staleness,
  append one line to `memory/librarian-queue.md` and say so in the answer.
  Maintenance (`LIBRARIAN_MAINT=1`, read via `echo $LIBRARIAN_MAINT`):
  task 5's checklist.
- `desktop/modules/home/claude.nix`: `".claude/agents" = link "agents";`.
- Verify: `just check`; rebuild; from another repo, a session asks the
  librarian a question with a known answer (e.g. "which driver did wake-
  from-sleep roll back to?") and gets a cited answer.

## Task 2: write guard hook

- `desktop/configs/claude/hooks/librarian-guard.sh`, linked per-file in
  `claude.nix` like `wiki-sync.sh`. Reads the hook JSON on stdin; for
  Edit/Write, allows only `…/llm-wiki/memory/librarian-queue.md` unless
  `LIBRARIAN_MAINT=1`, and in maintenance blocks `scripts/check.py` and
  anything outside the wiki. For Bash, allows only `git …` and
  `python3 scripts/check.py`; in reference mode no `git commit`/`push`.
- Verify by failing first: a reference-mode request to edit a wiki page
  is blocked; a queue append is allowed; a maintenance-mode edit to
  `check.py` is blocked.

## Task 3: route agents to the librarian

- `desktop/configs/claude/CLAUDE.md` "LLM Wiki": replace "read
  `index.md` first, then drill in" with "ask the `librarian` subagent";
  keep the write/ingest discipline as is. Change the promotion line from
  "never on its own" to the split (project/reference automatic; feedback,
  user, repo-rule escalated).
- `llm-wiki-query` skill: reduce to a pointer to the librarian.
- `llm-wiki-lint` skill: note the promotion split and the queue file.
- Verify: fresh session asked "what did Noah decide about X?" delegates
  to the librarian instead of reading pages itself.
- **Checkpoint:** use the reference desk for a few days before task 4.

## Task 4: debt score

- `desktop/pkgs/librarian/score.py` (or a `writeShellApplication`;
  builder's choice), packaged in a new
  `desktop/modules/home/librarian.nix`. Output: one integer on stdout.
  Since the last commit whose subject starts `lint:`: new files in
  `memory/inbox/`, distinct `wiki/` pages changed, lines in
  `memory/librarian-queue.md`, warnings from `python3 scripts/check.py`
  (run read-only; it's the one wiki script the host already runs as the
  pre-commit hook).
- Start weights at 1 each; threshold so it trips ~once/day at the current
  rate (back-test against the last 30 days of `git log`, note the number).
- Verify: run on the current wiki; the number matches a hand count.

## Task 5: live facts + maintenance run

- `librarian-facts` (host, read-only): writes
  `~/Documents/llm-wiki/.librarian/facts.md` (add `.librarian/` to the
  wiki's `.gitignore`). v1 contents: `~/nixos` `git log -5`, branches,
  worktrees; current NixOS generation; failed user + system units; for
  each `pending.md` row, nothing more yet. Extend later as the librarian
  asks for facts it lacked (it notes these in its run summary).
- Maintenance checklist (agent prompt): read `facts.md`; work the queue;
  run `llm-wiki-lint` steps with the promotion split; never commit
  `check.py` (draft changes as a patch under `.librarian/drafts/`);
  commit `lint: <summary>` and push (if pull isn't fast-forward, stop and
  escalate); end with a fenced `escalations` block, one line per item,
  and append those items to the queue marked `[escalated YYYY-MM-DD]`.
- Verify: one manual run on the real wiki from `claude-host`; review the
  diff before it pushes (first run only).

## Task 6: runner, timer, notification

- `librarian-run` (host): gates, in order; exit 0 quietly on any miss:
  1. no Claude session running (`pgrep` for the claude binary; builder
     confirms the process name for both launchers);
  2. last wiki commit ≥ 30 min old;
  3. `score ≥ threshold`.
  Then `librarian-facts`; run boxed `claude --agent librarian --model
  sonnet -p "<maintenance prompt>" --output-format json` in the wiki dir
  with `LIBRARIAN_MAINT=1` (shape per task 0); parse `session_id` and the
  `escalations` block.
- Notification: one per run, only for escalation lines not seen in an
  earlier run. `notify-send -a Librarian -A resume=Resolve "…" "<items>"`,
  copying `outboxRebuildPrompt` in `claude-box.nix`; on click, ghostty
  (`--class=claude.rebuild` for the existing float rule, or a new class
  added to both compositors) runs the boxed `claude --resume <id>` in the
  wiki dir, or `claude-host --resume <id>` when an item names `~/nixos`.
- `systemd.user.timers.librarian` every 15 min +
  `systemd.user.services.librarian` (oneshot, `librarian-run`).
- Verify: force each gate to fail once and see a quiet exit; force a run
  with a planted contradiction and click the button into the session.

## Task 7: docs and wiki

- Wiki: tracking page → status of the build, threshold, how to tune;
  `pending.md` row updated; `claude-setup` hub `## Now`.
- `~/nixos/CLAUDE.md`: one line pointing to `librarian.nix` under "Claude
  Code's own tools and box".
- After a week: compare runs/week and escalation count; retune threshold.

## Out of scope

Discord/email (pending item), other machines running the librarian.

## As built (2026-11-14, gen 185)

Differences from the tasks above, all builder calls:
- **No `skills:` preload.** Reference mode carries its own short
  instructions in the agent body (preloading lint + ingest would add ~250
  lines to every question); maintenance reads the two SKILL.md files.
- **"No Claude session running" = wiki tree clean.** Process detection
  can't tell live sessions from the daemon's idle `bg-spare` processes,
  and the real risk is sweeping uncommitted wiki edits.
- **Score resets on the HEAD recorded after each run** (`~/.local/state/
  librarian/last-head`), not only on `lint:` commits, so a run with
  nothing to fix doesn't re-trigger every 15 min. `check.py` warnings are
  left out of the score: the 3 standing size warnings need Noah, and would
  keep the score permanently up.
- **Box hardening:** the box now also denies writes to the wiki's
  `githooks/` and `scripts/`, which ran on the host at the launcher's
  commit (a hole for every boxed session, not just the librarian).
- **TTS + memory-checkpoint hooks** skip when `LIBRARIAN_MAINT` is set;
  the boxed launcher's "changed the wiki" notification too, unless the
  push failed.
- Timer uses `acceptEdits` plus Bash allow-patterns that mirror the guard.
