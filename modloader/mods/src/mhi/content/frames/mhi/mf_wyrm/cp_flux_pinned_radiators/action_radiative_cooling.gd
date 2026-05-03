extends ActionReaction

func get_required_triggering_context() -> Array[Context.PROP]:
    return [Context.PROP.unit]

func triggers_on_event(unit: Unit, gear: GearCore, triggering_event: EventCore) -> bool:
    var context: Context = triggering_event.context
    
    if(not context.unit == unit): return false
    
    if(not unit.state.spaces_moved_this_turn == 3): return false
    
    return true

func activate(context: Context, activation: EventCore) -> void :
    if(context.unit.core.current.heat > 0):
        activation.queue_event(&"event_unit_cool", {
            unit = context.unit, 
            number = 1
        })
    
    if(context.unit.state.burn > 0):
        effect_bus.play_text(tr("gear.cp_flux_pinned_radiators.action_radiative_cooling.clear_burn.pop").format({amount = 1}), context.unit.state.tile)
        battle_log.log_unit("gear.cp_flux_pinned_radiators.action_radiative_cooling.clear_burn.log", context.unit, {amount = 1})
        
        context.unit.set_current_burn(context.unit.state.burn - 1)
