--!nonstrict

-- Bar widget: the glyph is green while the ZeroTier service is up and muted
-- while it is down. Left click asks the service to toggle it; the service owns
-- the privileged call so escalation lives in exactly one place.

local STATE_KEY = "zt_snapshot"
local COMMAND_KEY = "zt_command"

local COLOR_UP = "#73c936"
local COLOR_DOWN = "on_surface_variant"

local snapshot = noctalia.state.get(STATE_KEY) or {
  running = false,
  networks = 0,
  installed = true,
}

local requestId = 0

local function render()
  local running = snapshot.running == true
  local networks = tonumber(snapshot.networks) or 0

  local children = {
    ui.glyph({
      name = "network",
      size = 16,
      color = running and COLOR_UP or COLOR_DOWN,
    }),
  }

  if running and networks > 0 and noctalia.getConfig("show_count") ~= false then
    table.insert(children, ui.label({
      text = tostring(networks),
      fontWeight = "bold",
      color = "on_surface",
    }))
  end

  local container = barWidget.isVertical() and ui.column or ui.row
  barWidget.render(container({ gap = 4, align = "center" }, children))

  if snapshot.installed == false then
    barWidget.setTooltip(noctalia.tr("widget.tooltip_missing"))
  elseif running then
    barWidget.setTooltip(noctalia.tr("widget.tooltip_up", { networks = networks }))
  else
    barWidget.setTooltip(noctalia.tr("widget.tooltip_down"))
  end
end

noctalia.state.watch(STATE_KEY, function(value)
  if type(value) == "table" then
    snapshot = value
    render()
  end
end)

render()

function update()
  render()
end

function onClick()
  requestId += 1
  noctalia.state.set(COMMAND_KEY, { action = "toggle", requestId = requestId })
end

-- Refresh on hover: the moment the tooltip is about to be read or the widget
-- clicked is the only moment the displayed state has to be right.
function onHover()
  requestId += 1
  noctalia.state.set(COMMAND_KEY, { action = "refresh", requestId = requestId })
end
