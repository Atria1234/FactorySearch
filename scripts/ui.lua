local gui = require("__FactorySearch__.scripts.gui")
local open_location = require "scripts.open_location"

local function get_selection_boxes(group)
  selection_boxes = {}
  for i, entity in pairs(group.entities) do
    selection_boxes[i] = entity.selection_box
    --[[if entity.supports_direction then
      selection_boxes[i].orientation = entity.orientation
    end]]
  end
  return selection_boxes
end

local function build_surface_results(surface_name, surface_data)
  local gui_elements = {}
  for _, group in pairs(surface_data) do
    table.insert(gui_elements,
      {
        type = "sprite-button",
        sprite = "entity/" .. group.entity_name,
        mouse_button_filter = { "left" },
        tooltip = {  "", {"entity-name." .. group.entity_name}, "\n", {"gui-train.open-in-map"} },
        style = "slot_button",
        number = group.count,
        tags = {position = group.avg_position, surface = surface_name, selection_boxes = get_selection_boxes(group)},
        actions = { on_click = { gui = "search", action = "open_location_in_map" } },
      }
    )
  end
  return gui_elements
end

local function build_surface_name(include_surface_name, surface_name)
  if include_surface_name then
    if surface_name == "nauvis" then
      -- Space Exploration capitilises all other planet names, so do Nauvis for consistency
      surface_name = "Nauvis"
    end
    return  {
      type = "label",
      caption = surface_name,
      style = "bold_label",
      style_mods = { font = "default-large-bold" }
    }
  else
    return {}
  end

end

local function build_result_gui(data, frame, no_checkboxes)
  frame.clear()

  if no_checkboxes then
    gui.build(frame, {
      {
        type = "label",
        style_mods = { font_color = {1, 0, 0, 1} },
        caption = {"search-gui.incorrect-config"}
      }
    })
  end

  local include_surface_name = false
  local surface_count = 0
  for _, _ in pairs(data) do
    surface_count = surface_count + 1
  end

  if surface_count > 1 then
    include_surface_name = true
  end

  local total_groups = 0
  for surface_name, surface_data in pairs(data) do
    total_groups = total_groups + #surface_data
    gui.build(frame, {
      build_surface_name(include_surface_name, surface_name),
      {
        type = "frame",
        direction = "horizontal",
        style = "inside_deep_frame",
        children = {
          {
            type = "table",
            column_count = 8,
            style = "map_view_options_table",
            children = build_surface_results(surface_name, surface_data)
          }
        }
      }
    })
  end

  if total_groups == 0 then
    frame.clear()
    gui.build(frame, {
      {
        type = "label",
        style_mods = { font_color = {1, 0, 0, 1} },
        caption = {"search-gui.no-results"}
      }
    })
  end
end

local function build_gui(player)
  local refs = gui.build(player.gui.screen, {
    {
      type = "frame",
      name = "fs_frame",
      direction = "vertical",
      visible = true,
      ref = { "frame" },
      actions = {
        on_closed = { gui = "search", action = "close" },
        on_location_changed = { gui = "search", action = "update_dimmer_location" },
      },
      children = {
        {
          type = "flow",
          style = "fs_flib_titlebar_flow",
          ref = { "titlebar_flow" },
          actions = {
            on_click = { gui = "search", action = "recenter" },  -- TODO What is this?
          },
          children = {
            {
              type = "label",
              style = "frame_title",
              caption = { "mod-name.FactorySearch" },
              ignored_by_interaction = true,
            },
            { type = "empty-widget", style = "fs_flib_titlebar_drag_handle", ignored_by_interaction = true },
            {
              type = "sprite-button",
              style = "close_button",
              sprite = "utility/close_white",
              hovered_sprite = "utility/close_black",
              clicked_sprite = "utility/close_black",
              actions = {
                on_click = { gui = "search", action = "close" },
              },
            },
          },
        },
        {
          type = "frame",
          style = "inside_shallow_frame_with_padding",
          --style_mods = { horizontal_spacing = 8 },
          direction = "horizontal",
          children = {
            {
              type = "flow",
              direction = "horizontal",
              style_mods = { horizontal_spacing = 12 },
              children = {
                {
                  type = "flow",
                  direction = "vertical",
                  children = {
                    {
                      type = "choose-elem-button",
                      style = "slot_button_in_shallow_frame",
                      elem_type = "signal",
                      mouse_button_filter = {"left"},
                      ref = { "item_select" },
                      style_mods = {
                        minimal_width = 60,
                        minimal_height = 60,
                      },
                      actions = {
                        on_elem_changed = { gui = "search", action = "item_selected" }
                      }
                    },
                    {
                      type = "checkbox",
                      state = true,
                      caption = "Producers",
                      tooltip = {"search-gui.producers-tooltip", "[entity=assembling-machine-2][entity=chemical-plant][entity=steel-furnace][entity=electric-mining-drill]"},
                      ref = { "include_machines" },
                      actions = {
                        on_checked_state_changed = { gui = "search", action = "checkbox_toggled" }
                      }

                    },
                    {
                      type = "checkbox",
                      state = false,
                      caption = "Storage",
                      tooltip = {"search-gui.storage-tooltip", "[entity=steel-chest][entity=logistic-chest-storage][entity=storage-tank][entity=character-corpse][entity=car][entity=cargo-wagon][entity=spidertron]"},
                      ref = { "include_inventories" },
                      actions = {
                        on_checked_state_changed = { gui = "search", action = "checkbox_toggled" }
                      }

                    }
                    --[[{
                      type = "sprite-button",
                      style = "slot_sized_button",
                      sprite = "utility/search_icon",
                      mouse_button_filter = {"left"},
                      ref = { "search" },
                      actions = {
                        on_click = { gui = "search", action = "search" }
                      }
                    },]]
                  },
                },
                {
                  type = "flow",
                  ref = { "result_flow" },
                  direction = "vertical",
                  children = {
                    {
                      type = "label",
                      caption = {"search-gui.explanation"},
                    }
                  }
                }
              }
            }
          },
        },
      }
    }
  })

  local player_data = {}
  refs.titlebar_flow.drag_target = refs.frame
  refs.frame.force_auto_center()
  player_data.refs = refs
  global.players[player.index] = player_data
  return player_data
end

local function open_gui(player, player_data)
  if not player_data then
    player_data = build_gui(player)
  end
  local refs = player_data.refs
  player.opened = refs.frame
  refs.frame.visible = true
  player.set_shortcut_toggled("search-factory", true)
end

local function destroy_gui(player, player_data)
  local main_frame = player_data.refs.frame
  if main_frame then
    main_frame.destroy()
  end
  player.set_shortcut_toggled("search-factory", false)
  global.players[player.index] = nil
end

local function close_gui(player, player_data)
  local refs = player_data.refs
  refs.frame.visible = false
  player.set_shortcut_toggled("search-factory", false)
  if player.opened == refs.frame then
    player.opened = nil
  end
end

local function toggle_gui(player, player_data)
  if player_data and player_data.refs.frame.visible then
    close_gui(player, player_data)
  else
    open_gui(player, player_data)
  end
end

local function start_search(player, player_data)
  local refs = player_data.refs
  local elem_button = refs.item_select
  local item = elem_button.elem_value
  if item then
    local force = player.force
    local data = find_machines(item, force.name, refs.include_machines.state, refs.include_inventories.state)
    player_data.refs.result_flow.clear()
    build_result_gui(data, refs.result_flow, not (refs.include_machines.state or refs.include_inventories.state))
  end
end

event.on_gui_elem_changed(
  function(event)
    local player = game.get_player(event.player_index)
    local player_data = global.players[event.player_index]
    local action = gui.read_action(event)
    if action then
      local msg = action.action
      if msg == "item_selected" then
        start_search(player, player_data)
      end
    end
  end
)

event.on_gui_checked_state_changed(
  function(event)
    local player = game.get_player(event.player_index)
    local player_data = global.players[event.player_index]
    local action = gui.read_action(event)
    if action then
      local msg = action.action
      if msg == "checkbox_toggled" then
        start_search(player, player_data)
      end
    end
  end
)


event.on_gui_click(
  function(event)
    local player = game.get_player(event.player_index)
    local player_data = global.players[event.player_index]

    local action = gui.read_action(event)
    if action then
      local msg = action.action
      if msg == "close" then
        close_gui(player, player_data)
      elseif msg == "open_location_in_map" then
        local tags = event.element.tags.FactorySearch
        open_location(player, tags)
      elseif msg == "checkbox_toggled" then
        start_search(player, player_data)
      end
    end
  end
)

event.on_gui_closed(
  function(event)
    if event.element and event.element.name == "fs_frame" then
      local player = game.get_player(event.player_index)
      close_gui(player, global.players[event.player_index])
    end
  end
)


local function on_shortcut_pressed(event)
  local player = game.get_player(event.player_index)

  local player_data = global.players[event.player_index]
  toggle_gui(player, player_data)
end
event.on_lua_shortcut(
  function(event)
    if event.prototype_name == "search-factory" then
      on_shortcut_pressed(event)
    end
  end
)
script.on_event("search-factory", on_shortcut_pressed)

return {destroy_gui = destroy_gui}