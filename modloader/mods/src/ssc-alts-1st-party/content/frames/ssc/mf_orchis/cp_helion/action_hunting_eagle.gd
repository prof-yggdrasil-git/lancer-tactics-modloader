extends ActionReaction

@export var buff: Buff

func get_per_turn_soft_limit(specific: SpecificAction) -> int:
    return 99

func get_per_round_hard_limit(specific: SpecificAction) -> int:
    return 1

func triggers_on_event(unit: Unit, gear: GearCore, triggering_event: EventCore) -> bool:
    if not triggering_event.context.is_property_present(Context.PROP.event): return false
    var move_event: EventCore = triggering_event.context.event
    if(move_event.context.unit == unit): return false
    if UnitRelation.are_allies(move_event.context.unit, unit): return false
    if not move_event.context.is_property_present(Context.PROP.object): return false
    var specific: SpecificAction = move_event.context.object
    if(specific.unit != unit): return false
    return true

func activate(context: Context, activation: EventCore) -> void:
    var triggering_context: Context = activation.context.event.context
    var unit: Unit = context.unit
    var attacked_unit = triggering_context.unit
    
    var gear = unit.core.loadout.get_by_compcon_id(&"cp_helion")
    if not GearCore.is_valid(gear): return
    var specific = SpecificAction.create(unit, gear, self)
    if not await CommonActionUtil.confirm_use_alt(specific): return
    
    spend_actions(activation)
    
    await activation.execute_event(&"event_unit_damage", {
        unit = attacked_unit, 
        number = 3,
        category = Lancer.DAMAGE_TYPE.KINETIC,
        flags = [],
        target_unit = unit, 
        gear = specific.gear, 
        action = specific.action, 
    })
    if not Unit.is_valid(attacked_unit): return
    
    UnitCondition.apply_buff(activation, attacked_unit, buff, gear)
