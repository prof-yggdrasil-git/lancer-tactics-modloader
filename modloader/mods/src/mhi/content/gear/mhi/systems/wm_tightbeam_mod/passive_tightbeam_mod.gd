extends PassiveWeaponMod

func is_applicable_to(gear: GearCore) -> bool:
    if not super.is_applicable_to(gear):
        return false
    
    for action in gear.kit.get_weapon_actions():
        if(action.range_pattern):
            if(action.range_pattern.pattern == Lancer.AOE_TYPE.LINE):
                return true
    
    return false
