# Two-commit rebuild protocol

`rebuild.sh` commits work *before* building, then records the result in a
second, empty `rebuild: gen N` commit. Together with
`system.configurationRevision`, this makes every NixOS generation traceable
to the exact commit it was built from, in both directions — while still
letting you make manual commits and run a bare `./rebuild.sh` to record the
generation they produced.

## Why

The old script built from a dirty tree and committed afterwards, which meant:

- `nixos-rebuild list-generations` showed `Configuration Revision: Unknown` —
  nothing on the running system said which tree built it.
- Running the script after committing manually hit "No changes detected,
  exiting"; `--force` rebuilt but discarded the nvd diff entirely, so those
  generations left no trace in history at all.

Committing first is what makes the revision honest: Nix reads `self.rev` at
evaluation time, so the tree must already be clean for the generation to
carry a real commit hash rather than `<parent>-dirty`.

## Considered options

- **Amend the nvd diff into the work commit after switching.** Rejected:
  amending rewrites the commit, so the rev baked into the generation
  immediately becomes a dead hash.
- **Build first, commit after (the old order), accepting `-dirty`.** Rejected
  by preference for exact revs, at the cost of two commits per rebuild.
- **`git notes` or per-generation tags instead of an empty commit.** Rejected:
  notes don't push or clone by default; tags accumulate ~one global ref per
  rebuild and are redundant once `configurationRevision` provides the
  generation → commit direction.
- **Storing a full `git diff` in the rebuild commit body.** Rejected in favour
  of `git log --oneline` over the range: git regenerates the diff on demand,
  and the shortlog is the part that makes `git log --grep='^rebuild: gen '`
  readable as a generation changelog.

## Consequences

- The dirty-file guard covers **all tracked files**, not just `*.nix`/`*.lock`,
  because Nix computes dirtiness over the whole repo tree — a stray edit to
  `.gitignore` is enough to lose the exact rev. Side effect: editing
  `rebuild.sh` alone triggers a (cached, seconds-long) rebuild.
- If the build fails after the work commit, the script runs
  `git reset --soft HEAD~1`. A failed *switch* leaves the commit in place —
  it built, so it belongs on the branch.
- `--force` rebuilds without touching git at all: a forced rebuild of an
  unchanged tree is not a history event.
- Bare runs on a dirty tree produce `wip: <timestamp>` work commits, expected
  to be rewritten with real messages later.
