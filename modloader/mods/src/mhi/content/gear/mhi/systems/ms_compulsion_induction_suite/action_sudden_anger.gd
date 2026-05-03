extends ActionAttackTech

@export var buff_self : Buff
@export var buff_target : Buff

func can_target_unit(potential_target: Unit, specific: SpecificAction) -> bool:
    if not super.can_target_unit(potential_target, specific): return false
    return true

func on_hit(activation: EventCore, attacked_unit: Unit) -> void :
    var context: = activation.context

    var buff = UnitCondition.apply_buff(activation, context.unit, buff_self, context.gear)
    var target_buff = UnitCondition.apply_buff(activation, attacked_unit, buff_target, context.gear)
    target_buff.from_gear = buff.persistent_id
    
