extends ActionSystemApplyBuff

func is_available_to_activate(unit: Unit, gear: GearCore) -> bool:
    if(unit.map.game_core.round_count > 1 and not gear.is_action_hibernating(&"action_redline_dispersion")):
        gear.hibernate_action(&"action_redline_dispersion")
        return false
    return super.is_available_to_activate(unit, gear)

func apply_additional_effect(specific: SpecificAction, target_unit: Unit, activation: EventCore) -> void :
    specific.gear.wake_action(&"action_overload_coolant_loop")
    specific.gear.hibernate_action(&"action_redline_dispersion")
    UnitCondition.clear_buff_id(activation, specific.unit, &"buff_overload_coolant_loop", specific.gear.persistent_id)
