extends ActionSystem

@export var ram: ActionAttackWeapon
@export var buff: Buff

func is_jammable() -> bool: return false

func can_target_unit(potential_target: Unit, specific: SpecificAction) -> bool:
    return ram.can_target_unit(potential_target, specific)

func activate(context: Context, activation: EventCore) -> void:
    var new_context: = Context.clone(context)
    new_context.gear = context.unit.core.loadout.get_by_compcon_id(&"mw_ram")
    new_context.action = new_context.gear.kit.actions[0].duplicate()
    new_context.action.threat = 6
    new_context.action.knockback = "3"
    UnitCondition.apply_buff(activation, context.unit, buff, context.gear)
    await ram.activate(new_context, activation)
