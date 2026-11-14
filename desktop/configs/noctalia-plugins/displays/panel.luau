--!nonstrict

-- Displays panel: one card per output (power, scale, brightness) plus night
-- light, built to be driven from the keyboard. Compositor-agnostic: outputs
-- go through wlr-output-management (wlr-randr, works on niri and umbriel),
-- brightness through noctalia's own ddcutil backend, night light through
-- noctalia.nightlight.
--
-- Keys: 1-9 jump to a monitor; Tab/Shift+Tab, Up/Down, j/k move between rows;
-- Left/Right, h/l adjust the focused row (Shift = fine brightness);
-- Enter/Space toggle; n toggles night light.

local SCALES = { 1.0, 1.25, 1.5, 1.75, 2.0 }
local SCALE_LABELS = { "1.0", "1.25", "1.5", "1.75", "2.0" }
local STEP, FINE = 5, 1
local CLEAR = "#00000000"

local isOpen = false
local outputs = {} -- { name, label, enabled, scale, mode }
local brightness = {} -- connector -> 0..100, absent when DDC can't read it
local night = { enabled = false }
local focusKey = nil -- "<connector>:power|scale|brightness" or "night"
local status = nil -- last error, shown under the cards

-- Brightness writes: at most one in flight per output, the latest value wins.
local wanted, sent, inflight = {}, {}, {}

local render -- forward declaration

-- Flat focus order, rebuilt from the current outputs on every use.
local function rows()
  local list = {}
  for _, o in ipairs(outputs) do
    table.insert(list, o.name .. ":power")
    if o.enabled then
      table.insert(list, o.name .. ":scale")
      if brightness[o.name] ~= nil then
        table.insert(list, o.name .. ":brightness")
      end
    end
  end
  table.insert(list, "night")
  return list
end

local function focusIndex(list)
  for i, key in ipairs(list) do
    if key == focusKey then
      return i
    end
  end
  return 1
end

local function findOutput(name)
  for _, o in ipairs(outputs) do
    if o.name == name then
      return o
    end
  end
  return nil
end

local function enabledCount()
  local n = 0
  for _, o in ipairs(outputs) do
    if o.enabled then
      n += 1
    end
  end
  return n
end

-- ---------------------------------------------------------------- reading

local function readBrightness()
  -- ponytail: ddcutil is read straight, noctalia exposes no brightness getter.
  if not noctalia.commandExists("ddcutil") then
    return
  end
  noctalia.runAsync({ "ddcutil", "--noconfig", "detect", "--terse" }, function(r)
    if r.exitCode ~= 0 then
      return
    end
    -- Each block lists "I2C bus: /dev/i2c-N" then "DRM connector: cardX-DP-1".
    for block in string.gmatch(r.stdout .. "\nDisplay", "(.-)\nDisplay") do
      local bus = string.match(block, "/dev/i2c%-(%d+)")
      local connector = string.match(block, "DRM[_ ]connector:%s*card%d+%-(%S+)")
      if bus and connector then
        noctalia.runAsync({ "ddcutil", "--noconfig", "--bus", bus, "getvcp", "10", "--terse" }, function(v)
          local cur, max = string.match(v.stdout or "", "VCP 10 C (%d+) (%d+)")
          if cur and tonumber(max) > 0 then
            brightness[connector] = math.floor(tonumber(cur) * 100 / tonumber(max) + 0.5)
            render()
          end
        end)
      end
    end
  end)
end

local function refresh()
  noctalia.runAsync({ "wlr-randr", "--json" }, function(r)
    if r.exitCode ~= 0 then
      status = "wlr-randr failed: " .. (r.stderr or "")
      render()
      return
    end
    local list = noctalia.json.decode(r.stdout) or {}
    outputs = {}
    for _, h in ipairs(list) do
      local mode = ""
      for _, m in ipairs(h.modes or {}) do
        if m.current then
          mode = string.format("%d×%d @ %d Hz", m.width, m.height, math.floor(m.refresh + 0.5))
        end
      end
      table.insert(outputs, {
        name = h.name,
        label = (h.model ~= nil and h.model ~= "") and h.model or h.name,
        enabled = h.enabled == true,
        scale = h.scale or 1,
        mode = mode,
      })
    end
    -- Stable order: left-to-right as the user numbers them.
    table.sort(outputs, function(a, b)
      return a.name < b.name
    end)
    if focusKey == nil and outputs[1] then
      focusKey = outputs[1].name .. ":power"
    end
    render()
  end)
end

-- ---------------------------------------------------------------- actions

local function run(argv)
  status = nil
  noctalia.runAsync(argv, function(r)
    if r.exitCode ~= 0 then
      status = table.concat(argv, " ") .. ": " .. (r.stderr or "failed")
    end
    refresh()
  end)
end

local function setPower(o, on)
  if not on and o.enabled and enabledCount() <= 1 then
    status = "Can't turn off the last active monitor"
    render()
    return
  end
  run({ "wlr-randr", "--output", o.name, on and "--on" or "--off" })
end

local function setScale(o, value)
  run({ "wlr-randr", "--output", o.name, "--scale", tostring(value) })
end

local function pushBrightness(name)
  if inflight[name] or wanted[name] == sent[name] then
    return
  end
  local value = wanted[name]
  inflight[name] = true
  noctalia.runAsync({ "noctalia", "msg", "brightness-set", name, tostring(value) }, function()
    inflight[name] = false
    sent[name] = value
    pushBrightness(name)
  end)
end

local function setBrightness(name, value)
  value = math.clamp(math.floor(value + 0.5), 0, 100)
  brightness[name] = value
  wanted[name] = value
  pushBrightness(name)
  render()
end

local function stepScale(o, dir)
  -- Next listed scale past the current one, so odd values like 1.6 still step.
  if dir > 0 then
    for _, s in ipairs(SCALES) do
      if s > o.scale + 0.01 then
        return setScale(o, s)
      end
    end
  else
    for i = #SCALES, 1, -1 do
      if SCALES[i] < o.scale - 0.01 then
        return setScale(o, SCALES[i])
      end
    end
  end
end

-- Left/Right (dir = -1/1) or Enter (dir = 0) on the focused row.
local function adjust(dir, fine)
  if focusKey == "night" then
    noctalia.nightlight.toggle()
    return
  end
  local name, kind = string.match(focusKey or "", "^(.*):(%a+)$")
  local o = name and findOutput(name)
  if not o then
    return
  end
  if kind == "power" then
    setPower(o, dir == 0 and not o.enabled or dir > 0)
  elseif kind == "scale" and dir ~= 0 then
    stepScale(o, dir)
  elseif kind == "brightness" and dir ~= 0 then
    setBrightness(name, (brightness[name] or 50) + dir * (fine and FINE or STEP))
  end
end

local function move(delta)
  local list = rows()
  local i = focusIndex(list) + delta
  if i < 1 then
    i = #list
  elseif i > #list then
    i = 1
  end
  focusKey = list[i]
  render()
end

local KEYMAP = {
  Tab = function() move(1) end,
  Down = function() move(1) end,
  j = function() move(1) end,
  ["shift+ISO_Left_Tab"] = function() move(-1) end,
  Up = function() move(-1) end,
  k = function() move(-1) end,
  Left = function() adjust(-1, false) end,
  h = function() adjust(-1, false) end,
  Right = function() adjust(1, false) end,
  l = function() adjust(1, false) end,
  ["shift+Left"] = function() adjust(-1, true) end,
  ["shift+h"] = function() adjust(-1, true) end,
  ["shift+Right"] = function() adjust(1, true) end,
  ["shift+l"] = function() adjust(1, true) end,
  Return = function() adjust(0, false) end,
  space = function() adjust(0, false) end,
  n = function() noctalia.nightlight.toggle() end,
}

function onKey(chord, pressed)
  if not pressed then
    return
  end
  local digit = tonumber(chord)
  if digit then
    local o = outputs[digit]
    if o then
      focusKey = o.name .. ":power"
      render()
    end
    return
  end
  local action = KEYMAP[chord]
  if action then
    action()
  end
end

-- ---------------------------------------------------------------- view

local function focusRow(key, children)
  local focused = key == focusKey
  return ui.row({
    key = key,
    gap = 10,
    align = "center",
    paddingH = 10,
    paddingV = 6,
    radius = 10,
    fill = focused and "primary/0.14" or CLEAR,
    border = focused and "primary/0.7" or CLEAR,
    borderWidth = 1,
    onClick = function()
      focusKey = key
      render()
    end,
  }, children)
end

local function rowLabel(text)
  return ui.label({ text = text, color = "on_surface_variant", width = 84 })
end

local function card(index, o)
  local children = {
    focusRow(o.name .. ":power", {
      ui.row({ fill = o.enabled and "primary" or "outline_variant", radius = 6, paddingH = 7, paddingV = 1 }, {
        ui.label({ text = tostring(index), fontWeight = "bold", color = o.enabled and "on_primary" or "on_surface" }),
      }),
      ui.column({ flexGrow = 1, gap = 0 }, {
        ui.label({ text = o.label, fontWeight = "bold" }),
        ui.label({
          text = o.enabled and `{o.name} · {o.mode}` or `{o.name} · off`,
          fontSize = 11,
          color = "on_surface_variant",
        }),
      }),
      ui.toggle({
        checked = o.enabled,
        onChange = function(v)
          setPower(o, v == "true")
        end,
      }),
    }),
  }

  if o.enabled then
    local buttons = { rowLabel("Scale") }
    for i, s in ipairs(SCALES) do
      local current = math.abs(o.scale - s) < 0.01
      table.insert(buttons, ui.button({
        key = `{o.name}-scale-{i}`,
        text = SCALE_LABELS[i],
        controlSize = "sm",
        variant = current and "primary" or "ghost",
        selected = current,
        flexGrow = 1,
        onClick = function()
          setScale(o, s)
        end,
      }))
    end
    table.insert(children, focusRow(o.name .. ":scale", buttons))

    local b = brightness[o.name]
    if b ~= nil then
      table.insert(children, focusRow(o.name .. ":brightness", {
        rowLabel("Brightness"),
        ui.slider({
          min = 0,
          max = 100,
          step = 1,
          value = b,
          controlSize = "sm",
          flexGrow = 1,
          onChange = function(v)
            setBrightness(o.name, tonumber(v) or b)
          end,
        }),
        ui.label({ text = `{b}%`, width = 40, textAlign = "end" }),
      }))
    end
  end

  return ui.column({
    key = "card-" .. o.name,
    gap = 2,
    padding = 6,
    radius = 14,
    fill = "surface_container",
    opacity = o.enabled and 1 or 0.7,
  }, children)
end

render = function()
  if not isOpen then
    return
  end
  local body = {
    ui.row({ align = "center", gap = 8 }, {
      ui.glyph({ name = "device-desktop", size = 18, color = "primary" }),
      ui.label({ text = "Displays", fontSize = 16, fontWeight = "bold", flexGrow = 1 }),
    }),
  }
  for i, o in ipairs(outputs) do
    table.insert(body, card(i, o))
  end

  local nightText = night.enabled and "On" or "Off"
  if night.enabled and (night.currentTemperature or -1) > 0 then
    nightText = `On · {night.currentTemperature}K`
  end
  table.insert(body, ui.column({ padding = 6, radius = 14, fill = "surface_container" }, {
    focusRow("night", {
      ui.glyph({ name = "moon", size = 16, color = night.enabled and "primary" or "on_surface_variant" }),
      ui.label({ text = "Night light", fontWeight = "bold", flexGrow = 1 }),
      ui.label({ text = nightText, fontSize = 11, color = "on_surface_variant" }),
      ui.toggle({
        checked = night.enabled,
        onChange = function(v)
          noctalia.nightlight.setEnabled(v == "true")
        end,
      }),
    }),
  }))

  if status then
    table.insert(body, ui.label({ text = status, color = "error", fontSize = 11, maxLines = 3 }))
  end
  table.insert(body, ui.label({
    text = "1–9 monitor · ↑↓ Tab j k move · ←→ h l adjust · ⇧ fine · ⏎ toggle · n night light",
    fontSize = 10,
    color = "on_surface_variant",
    textAlign = "center",
  }))

  panel.render(ui.column({ gap = 10 }, body))
end

noctalia.nightlight.watch(function(state)
  night = state
  render()
end)

function onOpen(_context)
  isOpen = true
  status = nil
  render()
  refresh()
  readBrightness()
end

function onClose()
  isOpen = false
end
