{
  pkgs,
  pkgs-unstable,
  ...
}: {
  boot.kernel.sysctl."vm.max_map_count" = 2147483642;

  services.ananicy = {
    enable = true;
    # ponytail: unstable's 1.2.0 fails to compile (missing <cstdint>); stable
    # is the same version and cached.
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs-unstable.ananicy-rules-cachyos;
  };

  # Without this, systemd-oomd runs but monitors zero cgroups. Sets
  # ManagedOOMMemoryPressure=kill at 80% on the user slices, so a leaking game
  # gets shot while the desktop is still responsive — three lockups in 2026-08
  # were PlateUp! reaching ~19.5 GB RSS and thrashing zram to a standstill.
  systemd.oomd.enableUserSlices = true;

  # oomd is PSI-based and needs 30s over 80% pressure — a game ballooning fast
  # enough (Schedule 1, 2026-08-17) froze the box before it ever fired. earlyoom
  # is mlocked and kills on absolute free mem/swap, so it still runs when the
  # machine doesn't. ponytail: stock thresholds (5% mem / 10% swap).
  services.earlyoom.enable = true;

  # sched-ext userspace scheduler; scx_lavd is provided by rustscheds.
  # ponytail: disabled 2026-08-27 — lavd 1.1.3 is ABI-skewed against kernel 7.2
  # ("Writing directly to p->scx.slice/dsq_vtime is deprecated"), causing 21s RCU
  # stalls every ~30s: kernel disables the scheduler, systemd restarts it, repeat.
  # Re-enable once scx ships a release matching the kernel.
  services.scx = {
    enable = false;
    package = pkgs-unstable.scx.full;
    scheduler = "scx_lavd";
  };
}
