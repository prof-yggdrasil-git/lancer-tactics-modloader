extends Buff
const GROUP_ICON: = preload("res://assets/icons/aoe_line.svg")

func check_if_passive_applies(core: BuffCore, context: Context) -> bool:
    var gear: GearCore = context.gear.get_weapon_mod(context.unit.core.loadout)
    if not GearCore.is_valid(gear): return false
    if gear != core.get_owner_gear(context.map): return false
    return true

func get_values(core: BuffCore, context: Context = null) -> Context:
    var variant_group: = VariantActionGroup.create(
        &"wm_tightbeam_mod", 
        tr("gear.wm_tightbeam_mod.name"), 
        tr("gear.wm_tightbeam_mod.effect"), 
        GROUP_ICON, 
        true
    )
    variant_group.priority = Priority.VARIANT_ACTION.swap_out

    var weapon: = VariantAction.create(
        &"tightbeam_mod", 
        tr("gear.wm_tightbeam_mod.name"), 
        tr("gear.wm_tightbeam_mod.effect"), 
        GROUP_ICON, 
        func(original_weapon: ActionAttackWeapon):
            var modified_weapon: ActionAttackWeapon = original_weapon.create_duplicate_for_variant()
            modified_weapon.aim_range = modified_weapon.aim_range + 5
            modified_weapon.range_pattern = RangePattern.create(modified_weapon.range_pattern.pattern, modified_weapon.range_pattern.value + 5)
            var dice = Dice.process_dice_string(modified_weapon.self_heat_dice)
            if(dice.count > 0):
                dice = str(dice.count)+"d"+str(dice.dietype)+"+"+str(dice.bonus + 2)
            else:
                dice = str(dice.bonus + 2)
            modified_weapon.self_heat_dice = dice
            modified_weapon.modified_by_variants = [&"tightbeam_mod_replacement"]
            return modified_weapon
    )
    variant_group.append(weapon)

    return Context.create({object = variant_group})
