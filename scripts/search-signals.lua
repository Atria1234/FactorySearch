local function signal_eq(sig1, sig2)
  return sig1.type == sig2.type and sig1.name == sig2.name
end

local function search_signals(target_signal, force, surface, surface_data)
  local entities = surface.find_entities_filtered{
    type = { "roboport", "train-stop", "arithmetic-combinator", "decider-combinator", "constant-combinator", "accumulator", "rail-signal", "rail-chain-signal", "wall" },
    force = force,
  }
  for _, entity in pairs(entities) do
    local control_behavior = entity.get_control_behavior()
    if control_behavior then
      local entity_type = entity.type
      if entity_type == "constant-combinator" then
        -- If prototype's `item_slot_count = 0` then .parameters will be nil
        for _, parameter in pairs(control_behavior.parameters or {}) do
          if signal_eq(parameter.signal, target_signal) then
            add_entity(entity, surface_data.signals)
            break
          end
        end
      elseif entity_type == "arithmetic-combinator" or entity_type == "decider-combinator" then
        if control_behavior.get_signal_last_tick(target_signal) ~= nil then
          add_entity(entity, surface_data.signals)
        end
      elseif entity_type == "roboport" then
        for _, signal in pairs({ control_behavior.available_logistic_output_signal, control_behavior.total_logistic_output_signal, control_behavior.available_construction_output_signal, control_behavior.total_construction_output_signal }) do
          if signal_eq(signal, target_signal) then
            add_entity(entity, surface_data.signals)
            break
          end
        end
      elseif entity_type == "train-stop" then
        if signal_eq(control_behavior.stopped_train_signal, target_signal) or signal_eq(control_behavior.trains_count_signal, target_signal) then
          add_entity(entity, surface_data.signals)
        end
      elseif entity_type == "accumulator" or entity_type == "wall" then
        if signal_eq(control_behavior.output_signal, target_signal) then
          add_entity(entity, surface_data.signals)
        end
      elseif entity_type == "rail-signal" then
        for _, signal in pairs({ control_behavior.red_signal, control_behavior.orange_signal, control_behavior.green_signal }) do
          if signal_eq(signal, target_signal) then
            add_entity(entity, surface_data.signals)
            break
          end
        end
      elseif entity_type == "rail-chain-signal" then
        for _, signal in pairs({ control_behavior.red_signal, control_behavior.orange_signal, control_behavior.green_signal, control_behavior.blue_signal }) do
          if signal_eq(signal, target_signal) then
            add_entity(entity, surface_data.signals)
            break
          end
        end
      end
    end
  end

end

return search_signals