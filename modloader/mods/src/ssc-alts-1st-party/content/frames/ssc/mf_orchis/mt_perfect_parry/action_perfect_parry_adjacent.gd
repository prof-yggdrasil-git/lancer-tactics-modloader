extends ActionReaction

@export var buff: Buff

func triggers_on_event(unit: Unit, gear: GearCore, triggering_event: EventCore) -> bool:
    if(triggering_event.context.unit == unit): 
        return true
    if not Unit.is_valid(triggering_event.context.unit): return false
    if not UnitRelation.are_allies(triggering_event.context.unit, unit): return false
    if UnitRelation.is_adjacent(triggering_event.context.unit, unit):
        if not UnitCondition.has_buff(triggering_event.context.unit, buff.compcon_id, gear.persistent_id):
            return true
    else:
        if UnitCondition.has_buff(triggering_event.context.unit, buff.compcon_id, gear.persistent_id):
            return true
    return false

func activate(context: Context, activation: EventCore) -> void:
    var unit: Unit = context.unit
    var moving_units = [activation.context.event.context.unit]
    if(activation.context.event.context.unit == unit):
        moving_units = unit.get_allied_units()
    
    for moving_unit: Unit in moving_units:
        if UnitRelation.is_adjacent(moving_unit, unit):
            if not UnitCondition.has_buff(moving_unit, buff.compcon_id, context.gear.persistent_id):
                #buff.log_on_application = true
                UnitCondition.apply_buff(activation, moving_unit, buff, context.gear)
                #buff.log_on_application = false
        else:
            if UnitCondition.has_buff(moving_unit, buff.compcon_id, context.gear.persistent_id):
                #buff.log_on_application = true
                UnitCondition.clear_buff_id(activation, moving_unit, buff.compcon_id, context.gear.persistent_id)
                #buff.log_on_application = false
