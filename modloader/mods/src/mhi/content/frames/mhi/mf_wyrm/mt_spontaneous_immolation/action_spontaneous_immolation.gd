extends ActionReaction

var unit_had_prev_turn = &""

func get_required_triggering_context() -> Array[Context.PROP]:
    return []

func triggers_on_event(unit: Unit, gear: GearCore, triggering_event: EventCore) -> bool:
    var context: Context = triggering_event.context
    
    if not context.is_property_present(Context.PROP.unit):
        unit_had_prev_turn = &""
        return false
    
    if(context.unit == unit):
        #print("Wyrm's turn")
        unit_had_prev_turn = unit.core.persistent_id
        return false
    
    if (unit_had_prev_turn != unit.core.persistent_id): return false
    
    #print("Next Turn")
    
    unit_had_prev_turn = &""
    
    if(unit.state.spaces_moved_this_turn >= 3): return false
    
    if(unit.has_status(Lancer.STATUS.SHUTDOWN)): return false

    return true

func activate(context: Context, activation: EventCore) -> void :
    activation.queue_event(&"event_unit_damage", {
        unit = context.unit, 
        number = 6, 
        category = Lancer.DAMAGE_TYPE.BURN, 
        flags = [Lancer.DAMAGE_FLAG.SELF_INFLICTED], 
        target_unit = context.unit
    })
