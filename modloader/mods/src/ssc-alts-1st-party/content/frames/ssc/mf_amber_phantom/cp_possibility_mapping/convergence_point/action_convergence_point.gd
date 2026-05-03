extends ActionSystem

static  var phase_bus: PhaseControllerBus = load("res://engine/gamemaster/phase_controller/phase_controller_bus.tres")

@export var end_turn_reaction: ActionReaction

func activate(context: Context, activation: EventCore) -> void:
    var specific: = SpecificAction.create(context.unit, context.gear, context.action)
    
    spend_actions(activation)
    run_system_fxgs(context.unit)
    
    var units: Array[Unit] = []
    var unit_tiles: Array[Vector2i] = []
    for unit in UnitRelation.get_units_within(context.unit, context.unit.get_sensor_range(), false):
        if unit.is_character() and UnitRelation.are_allies(unit, context.unit):
            units.append(unit)
            unit_tiles.append(unit.state.tile)
    
    if(len(units) == 0): return
    
    await camera_bus.show_all_tiles(unit_tiles)
    
    var target_unit: Unit = await choice_bus.choose_unit(units, true, specific)
    if(target_unit != null):
        var choices = [
            tr("gear.cp_possibility_mapping.now"),
            tr("gear.cp_possibility_mapping.later")
        ]
        var choice: int = await choice_bus.choose_from_multiple_choice(
            choices, 
            tr("gear.cp_possibility_mapping.action_convergence_point.name"), 
            tr("gear.cp_possibility_mapping.action_convergence_point.effect"), 
            "", 
            false
        )
        if(choice == 0):
            end_turn_reaction.after_cache[target_unit.core.persistent_id] = {
                "unit": target_unit,
                "next_unit": context.unit,
                "do_event": false,
            }
            
            context.unit.map.game_core.active_unit_id = target_unit.core.persistent_id
            context.unit.state.is_taking_turn = false
            #await X.execute_event(&"event_turn_start", {unit = target_unit})
            await activation.execute_event(&"event_turn_start", {
                unit = target_unit
            })
            phase_bus.next_phase.emit()
            
            #print(context.unit.core.current.activations, " ", target_unit.core.current.activations)
            
        else:
            end_turn_reaction.after_cache[context.unit.core.persistent_id] = {
                "unit": context.unit,
                "next_unit": target_unit,
                "do_event": true,
            }
