extends ActionReaction

const FLAG_IS_COOLANT_LOOP_DAMAGE = 8999

func get_required_triggering_context() -> Array[Context.PROP]:
    return [Context.PROP.unit]

func triggers_on_event(unit: Unit, gear: GearCore, triggering_event: EventCore) -> bool:
    var context: Context = triggering_event.context
    
    if(context.is_property_present(Context.PROP.string)):
        if(context.string != &"cp_flux_pinned_radiators"):
            if(context.is_property_present(Context.PROP.gear) and context.is_property_present(Context.PROP.action)):
                var action_type = context.action.get_action_type(SpecificAction.from_context(context))
                
                if(action_type == Lancer.ACTION.RXN):
                    return false
                
                if UnitCondition.has_buff(unit, &"buff_overload_coolant_loop", gear.persistent_id):
                    UnitCondition.clear_buff_id(triggering_event, unit, &"buff_overload_coolant_loop", gear.persistent_id)
                    gear.hibernate_action(&"action_overload_coolant_loop")
                
        return false
    else:
        if(not context.unit == unit): return false
        
        if(not context.category == Lancer.DAMAGE_TYPE.HEAT): return false

        if UnitCondition.has_buff(unit, &"buff_overload_coolant_loop", gear.persistent_id):
            return true
        else:
            if(context.unit.core.current.heat + context.number > context.unit.get_heat_max() and unit.core.current.reactions > 0):
                return true
            
            return false


func activate(context: Context, activation: EventCore) -> void :
    var unit: Unit = context.unit
    var gear: GearCore = context.gear
    var triggering_event: EventCore = context.event
    
    if UnitCondition.has_buff(unit, &"buff_overload_coolant_loop", gear.persistent_id):
        var abort = true
        if(context.event.context.is_property_present(Context.PROP.flags)):
            if(context.event.context.flags.has(FLAG_IS_COOLANT_LOOP_DAMAGE)):
                abort = false
        if(abort):
            #print("would take "+str(context.event.context.number)+" damage")
            triggering_event.set_aborted()
        return
    
    var confirmed: = await CommonActionUtil.confirm_use(context)
    if activation.abort_when( not confirmed): return
    
    context = Context.clone(activation.context.event.context)
    
    #print("Activated coolant loop")
    #print("would take "+str(context.number)+" damage")
    
    var flags = []
    if(context.is_property_present(Context.PROP.flags)):
        flags = context.flags
    for flag in [Lancer.DAMAGE_FLAG.NO_REDUCE, FLAG_IS_COOLANT_LOOP_DAMAGE]:
        if not context.flags.has(flag):
            flags.append(flag)
    
    #var target_unit = unit
    #if(context.is_property_present(Context.PROP.target_unit)):
        #target_unit = context.target_unit
    var target_unit = context.target_unit
    if(target_unit == null):
        target_unit = unit
    
    context.number = context.unit.get_heat_max() - context.unit.core.current.heat
    activation.context.event.context = context
    
    UnitCondition.apply_buff_id(activation, unit, &"buff_overload_coolant_loop", gear)
    
    spend_actions(activation)
    
    #activation.queue_event(&"event_unit_damage", {
        #unit = unit, 
        #number = context.unit.get_heat_max() - context.unit.core.current.heat, 
        #category = Lancer.DAMAGE_TYPE.HEAT, 
        #flags = flags, 
        #target_unit = target_unit
    #}, Priority.ACTIVATE.gain_self_heat)
    #
    #triggering_event.set_aborted()
    
    
