# Gen tags instead of gen commits

Supersedes the second half of [0001](0001-two-commit-rebuild-protocol.md).
`rebuild.sh` still commits work before building, but records the generation
as an annotated tag `gen-N` on the built commit instead of an empty
`rebuild: gen N` commit. The tag message keeps what the commit body held:
the shortlog since the previous gen and the nvd diff. `just gens [n]`
prints them; `git log --decorate` shows the names.

## Why

0001 rejected tags because they add a global ref per rebuild and
`configurationRevision` already covers generation → commit. In practice the
empty commits cost more:

- They interleave with work commits, so squashing or rewording a run of
  `wip:` commits means rebasing around them.
- HEAD moved on every rebuild, so an agent's `git commit --amend` landed in
  a gen commit (gen 172).
- Rewriting history detached the gen commit from what it described. A tag
  pins the exact built commit, so it stays reachable (and won't be GC'd)
  after a squash; the generation's baked-in rev still resolves.

## Consequences

- "Nothing to rebuild" compares HEAD to the newest `gen-*` tag by number,
  not one reachable from HEAD, since a squashed branch no longer contains
  the running commit.
- After rewriting history, older tags point at commits off the branch.
  That's intended: they record what was built, not what was kept.
- Tags don't push by default: `git push --follow-tags`.
- The 98 existing gen commits (gens 95–202) were backfilled as tags on their
  parents, with the commit body as the message and the commit's date. The
  commits stay in history; removing them would rewrite every rev since.
