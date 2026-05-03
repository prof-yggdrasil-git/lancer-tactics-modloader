extends ActionReaction

func get_required_triggering_context() -> Array[Context.PROP]:
    return []

func triggers_on_event(unit: Unit, gear: GearCore, triggering_event: EventCore) -> bool:
    return true

func activate(context: Context, activation: EventCore) -> void :
    var counter: = context.gear.get_die_counter_passive()
    
    await camera_bus.focus_on_unit_close(context.unit)
    
    var turns: = context.unit.core.current.activations
    for ally in context.unit.get_allied_units():
        turns += ally.core.current.activations
    counter.max_value = turns
    
    if(turns > 1):
        var choices = []
        for i in range(turns):
            choices.append(tr("gear.cp_possibility_mapping.turn")+str(i+1))
        
        var turn: int = await choice_bus.choose_from_multiple_choice(
            choices, 
            tr("gear.cp_possibility_mapping.action_possibility_mapping.name"), 
            tr("gear.cp_possibility_mapping.action_possibility_mapping.effect"), 
            "", 
            false
        )
        
        counter.update_value(context.unit, context.gear, turn+1, false)
    else:
        counter.update_value(context.unit, context.gear, 1, false)
