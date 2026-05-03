extends Buff

@export var buff_target : Buff

func get_required_triggering_context() -> Array[Context.PROP]:
    return [Context.PROP.unit, Context.PROP.resource]

func triggers_on_event(core: BuffCore, unit: Unit, triggering_event: EventCore) -> bool:
    return true

func can_overwatch(unit: Unit, triggering_context: Context):
    if(unit.core.current.reactions <= 0): return false
    
    if not UnitAction.can_activate_gear(SpecificAction.from_id(unit, &"ms_overwatch")): return false
    
    if not UnitRelation.can_affect(unit, triggering_context.unit): return false

    if not MovementType.is_contextual_move_reactable(triggering_context): return false

    if UnitRelation.get_weapons_that_can_overwatch(unit, triggering_context.unit).is_empty(): return false
    
    if CommonActionUtil.is_overwatch_in_progress(unit): return false
    
    return true

func activate(core: BuffCore, activation: EventCore) -> void :
    for unit in activation.context.unit.map.get_all_units():
        if(UnitCondition.has_buff(unit, buff_target.compcon_id, core.persistent_id)):
            #print("mech_name")
            #print(unit.core.mech_name, unit.core.persistent_id)
            if(can_overwatch(unit, activation.context.event.context)):
                var target_unit: Unit = activation.context.event.context.unit
                var specific: SpecificAction = SpecificAction.from_id(unit, &"ms_overwatch")

                var possible_weapons: Array[SpecificAction] = UnitRelation.get_weapons_that_can_overwatch(unit, target_unit)
                await CommonActionUtil.choose_and_use(
                    activation, 
                    specific, 
                    possible_weapons, 
                    CommonActionUtil.choose_and_use_spend_action, 
                    target_unit, 
                    [Action.FLAG.CAN_FOLLOWUP, Action.FLAG.IS_OVERWATCH], 
                    true
                )
            
                UnitCondition.clear_buff_id(activation, unit, buff_target.compcon_id, core.persistent_id)
                UnitCondition.clear_buff(activation, activation.context.unit, core)
                return

func on_clear(event: EventCore, core: BuffCore, unit: Unit) -> void :
    for target_unit in unit.map.get_all_units():
        if(UnitCondition.has_buff(target_unit, buff_target.compcon_id)):
            UnitCondition.clear_buff_id(event, target_unit, buff_target.compcon_id, core.persistent_id)
    
