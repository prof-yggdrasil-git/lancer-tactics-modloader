extends ActionReaction

static  var phase_bus: PhaseControllerBus = load("res://engine/gamemaster/phase_controller/phase_controller_bus.tres")

@export var after_cache: Dictionary = {}

func triggers_on_event(unit: Unit, gear: GearCore, triggering_event: EventCore) -> bool:
    #print(after_cache)
    #print(triggering_event.context.unit.core.persistent_id)
    if not Unit.is_valid(triggering_event.context.unit): return false
    if not after_cache.has(triggering_event.context.unit.core.persistent_id): return false
    return true

func activate(context: Context, activation: EventCore) -> void:
    var unit: Unit = activation.context.event.context.unit
    if not is_instance_valid(after_cache[unit.core.persistent_id]["next_unit"]): return
    var target_unit: Unit = after_cache[unit.core.persistent_id]["next_unit"]
    var do_event: bool = after_cache[unit.core.persistent_id]["do_event"]
    after_cache.erase(unit.core.persistent_id)
    
    #print(unit.core.frame.compcon_id, " ", target_unit.core.frame.compcon_id)
    #print(unit.core.persistent_id, " ", target_unit.core.persistent_id)
    
    context.unit.map.game_core.active_unit_id = target_unit.core.persistent_id
    unit.state.is_taking_turn = false

    if do_event:
        await activation.execute_event(&"event_turn_start", {
            unit = target_unit
        })
    else:
        target_unit.state.is_taking_turn = true
    
    phase_bus.next_phase.emit()
