extends Buff

func triggers_on_event(core: BuffCore, unit: Unit, triggering_event: EventCore) -> bool:
    
    if(triggering_event.context.unit != unit): return false
    
    return true

func activate(core: BuffCore, activation: EventCore) -> void:
    var specific = SpecificAction.from_context(activation.context.event.context)
    
    if(UnitAction.is_ordnance(specific)):
        UnitCondition.clear_buff(activation, activation.context.unit, core)
    else:
        activation.context.unit.state.is_firing_ordnance = true
