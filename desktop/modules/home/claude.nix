# Claude Code setup: portable, live-lane only. See docs/adr/0002.
# Every file is a symlink into the repo checkout, so Claude's own runtime
# writes (/model, /effort, plugin toggles) land in configs/claude as git
# diffs instead of drifting. Needs ~/nixos and ~/Documents/llm-wiki cloned
# first; the claude binary comes from the native installer, not nix.
{config, ...}: let
  # ponytail: hardcoded like dotfiles.nix — builtins.toString resolves to the store
  dir = "${config.home.homeDirectory}/nixos/desktop/configs/claude";
  link = name: {source = config.lib.file.mkOutOfStoreSymlink "${dir}/${name}";};
in {
  home.file = {
    ".claude/settings.json" = link "settings.json";
    ".claude/CLAUDE.md" = link "CLAUDE.md";
    ".claude/statusline-command.sh" = link "statusline-command.sh";
    # whole dir; Claude's claude.ai skill cache (synced/) is gitignored there
    ".claude/skills" = link "skills";
    ".claude/commands" = link "commands";
    ".claude/output-styles" = link "output-styles";
    # per-file: hooks/ also holds the TTS venv and herdr's self-managed script
    ".claude/hooks/wiki-sync.sh" = link "hooks/wiki-sync.sh";
  };
}
