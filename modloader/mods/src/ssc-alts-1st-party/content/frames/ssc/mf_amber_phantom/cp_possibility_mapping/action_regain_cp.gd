extends ActionReactionSelf

func activate(context: Context, activation: EventCore) -> void :
    context.unit.core.has_core_power = true
    
