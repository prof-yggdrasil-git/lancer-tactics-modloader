extends ActionReactionApplyBuff

func get_required_triggering_context() -> Array[Context.PROP]:
    return []

func triggers_on_event(unit: Unit, gear: GearCore, triggering_event: EventCore) -> bool:

    if buffs.all( func(buff: Buff) -> bool:
        if buff.multiple_copies_can_stack: return false
        if UnitCondition.has_buff(unit, buff.compcon_id, gear.persistent_id): return true
        return false
    ): return false

    return true

func activate(context: Context, activation: EventCore) -> void :
    spend_actions(activation)

    apply_buffs_and_statuses_to(context.unit, context.gear, activation)
