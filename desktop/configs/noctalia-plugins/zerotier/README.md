# ZeroTier

Bar widget showing whether the ZeroTier service is running, with click-to-toggle.

- Green network glyph while the service is up, muted while it is down.
- Optional count of joined networks beside the glyph.
- Left click starts or stops the service.

## Requirements

- `systemctl` and `ip` on `PATH`
- Passwordless `sudo` for starting and stopping the unit, e.g. in `sudoers`:

  ```
  yourname ALL=(ALL:ALL) NOPASSWD: /run/current-system/sw/bin/systemctl start zerotierone, \
                                   NOPASSWD: /run/current-system/sw/bin/systemctl stop zerotierone
  ```

  Adjust the binary path and unit name for your distro.

## Settings

| Setting | Default | Notes |
| --- | --- | --- |
| Systemd unit | `zerotierone` | NixOS uses `zerotierone`; most others use `zerotier-one` |
| Refresh interval | `10` | Seconds between state checks |
| Show network count | `true` | Widget-level setting |

## Why interface counting

The joined-network count comes from counting `zt*` interfaces, not from
`zerotier-cli listnetworks`. The CLI needs the root-only authtoken, while
`ip link` does not — so the widget stays useful without escalating just to read
state. Escalation happens only on an explicit toggle.
