util = require "__core__.lualib.util"
event = require "scripts.event"
search = require "scripts.search"
local gui = require "scripts.gui"

function filtered_surfaces(override_surface, player_surface)
  if override_surface then
    return {player_surface}
  end

  -- Skip certain modded surfaces that won't have assemblers/chests placed on them
  local surfaces = {}
  for _, surface in pairs(game.surfaces) do
    local surface_name = surface.name
    if string.sub(surface_name, -12) ~= "-transformer"  -- Power Overload
        and string.sub(surface_name, 0, 8) ~= "starmap-"  -- Space Exploration
        and surface_name ~= "aai-signals"  -- AAI Signals
      then
      table.insert(surfaces, surface)
    end
  end
  return surfaces
end

local function update_surface_count()
  -- Hides 'All surfaces' button
  local multiple_surfaces = #filtered_surfaces() > 1

  if multiple_surfaces ~= global.multiple_surfaces then
    for player_index, player_data in pairs(global.players) do
      local all_surfaces = player_data.refs.all_surfaces
      all_surfaces.visible = multiple_surfaces
    end
  end

  global.multiple_surfaces = multiple_surfaces
end

script.on_event({defines.events.on_surface_created, defines.events.on_surface_deleted}, update_surface_count)

script.on_init(
  function()
    global.players = {}
    global.multiple_surfaces = false
    update_surface_count()
  end
)

script.on_configuration_changed(
  function()
    -- Destroy all GUIs
    for player_index, player_data in pairs(global.players) do
      local player = game.get_player(player_index)
      if player then
        gui.destroy_gui(player, player_data)
      else
        global.players[player_index] = nil
      end
    end
    global.multiple_surfaces = false
    update_surface_count()
  end
)