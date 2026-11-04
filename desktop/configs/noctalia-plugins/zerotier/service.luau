--!nonstrict

-- Owns the ZeroTier unit's state and the privileged toggle.
--
-- No periodic polling: the widget is the only thing that changes this service's
-- state, so we re-read on load, on hover, and after a toggle. Anything else
-- changing the unit out of band (a crash, a terminal `systemctl stop`) leaves
-- the glyph stale until the next hover, which is a cosmetic problem only --
-- the toggle re-checks the unit in-shell and never trusts the cached value.
--
-- Joined-network count comes from counting zt* interfaces rather than
-- `zerotier-cli listnetworks`, because the CLI needs the root-only authtoken
-- while `ip link` does not.

local STATE_KEY = "zt_snapshot"
local COMMAND_KEY = "zt_command"

local REFRESH_DEBOUNCE_MS = 1500

local snapshot = { running = false, networks = 0, installed = true, state = "" }
local busy = false
local lastRequest = nil
local lastRefreshMs = 0

local function unitName()
  local name = noctalia.getConfig("service_name")
  if type(name) ~= "string" or name == "" then
    return "zerotierone"
  end
  return name
end

local function publish()
  noctalia.state.set(STATE_KEY, snapshot)
end

local function refresh(force)
  local now = noctalia.nowMs()
  if not force and (now - lastRefreshMs) < REFRESH_DEBOUNCE_MS then
    return
  end
  lastRefreshMs = now

  local cmd = "systemctl is-active " .. unitName()
    .. " 2>/dev/null; ip -o link show 2>/dev/null | grep -c ': zt'"

  noctalia.runAsync(cmd, function(result)
    local out = (result and result.stdout) or ""
    local state = string.match(out, "^%s*(%a[%w-]*)") or ""
    local count = string.match(out, "\n%s*(%d+)") or "0"

    snapshot = {
      running = state == "active" or state == "activating",
      networks = tonumber(count) or 0,
      installed = snapshot.installed,
      state = state,
    }
    publish()
  end, 5000)
end

local function toggle()
  if busy then
    return
  end
  busy = true

  -- The unit is re-checked inside the shell so a stale snapshot cannot invert
  -- the action. ponytail: sudo hardcoded; pkexec/run0 become a setting when
  -- someone actually needs them.
  local unit = unitName()
  local cmd = "if systemctl is-active --quiet " .. unit .. "; then"
    .. " sudo systemctl stop " .. unit .. " && echo stopped;"
    .. " else sudo systemctl start " .. unit .. " && echo started; fi"

  noctalia.runAsync(cmd, function(result)
    busy = false

    local out = (result and result.stdout) or ""
    local verb = string.match(out, "(start?ed)") or string.match(out, "(stopped)")

    if result and result.exitCode ~= 0 then
      local err = result.stderr
      if err == nil or err == "" then
        err = out
      end
      noctalia.notifyError(
        noctalia.tr("title"),
        noctalia.tr("notify.failed", { error = tostring(err or "") })
      )
    elseif verb == "stopped" then
      noctalia.notify(noctalia.tr("title"), noctalia.tr("notify.stopped"))
    else
      noctalia.notify(noctalia.tr("title"), noctalia.tr("notify.started"))
    end

    refresh(true)
  end, 20000)
end

noctalia.state.watch(COMMAND_KEY, function(value)
  if type(value) ~= "table" then
    return
  end
  -- state.watch replays the last value on load; ignore one we already ran.
  if value.requestId == lastRequest then
    return
  end
  lastRequest = value.requestId

  if value.action == "toggle" then
    toggle()
  elseif value.action == "refresh" then
    refresh(false)
  end
end)

snapshot.installed = noctalia.commandExists("zerotier-cli")
refresh(true)
