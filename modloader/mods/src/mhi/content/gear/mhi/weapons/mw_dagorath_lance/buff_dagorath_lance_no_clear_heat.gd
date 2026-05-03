extends Buff

func triggers_on_event(core: BuffCore, unit: Unit, triggering_event: EventCore) -> bool:
    
    if (triggering_event.context.unit != unit): return false
    
    if(unit.core.current.heat > unit.get_heat_max()): return false
    
    return true

func activate(core: BuffCore, activation: EventCore) -> void:
    activation.context.event.set_aborted()
