extends ActionSystem

@export var action: Action

func get_target_range(specific: SpecificAction) -> int: return 3

func activate(context: Context, activation: EventCore) -> void :
    var specific: = SpecificAction.from_context(context)
    var unit: Unit = context.unit


    var confirmed: = await CommonActionUtil.confirm_use(context)
    if activation.abort_when( not confirmed): return
    spend_actions(activation)
    
    var use_move: = await choice_bus.quick_yesno(unit.state.tile, tr("gear.cp_tengu_assisted_missile_tubes.action_heavens_downpour.choose"), tr("gear.cp_tengu_assisted_missile_tubes.action_heavens_downpour.choose.effect"), false)
    if use_move:
        await activation.execute_event(&"event_gear_activate", {
            unit = unit, 
            gear = context.gear, 
            action = action, 
            flags = [Action.FLAG.AS_FREEBIE], 
            event = activation
        })
        if activation.abort_without_unit(unit): return


    #var all_targets: Array[Unit] = context.map.get_enemy_units(unit, false)
    #Util.filter(all_targets, func(target: Unit) -> bool: return UnitRelation.distance_between(unit, target, true) <= 3 and target.is_character())
    var all_targets: Array[Unit] = UnitRelation.get_characters_within(unit, 3, false, func(target: Unit) -> bool: return UnitRelation.are_enemies(target, unit), unit)

    await run_system_fxgs(
        unit, all_targets, 
        [], 
        false, 
    )
    if activation.abort_without_unit(unit): return


    var damage_amount: int = Dice.roll_string("1d6+3")
    
    var on_fail_func = func on_fail(target_unit: Unit): UnitCondition.apply_status(activation, target_unit, Lancer.STATUS.PRONE, Lancer.UNTIL.MANUAL, context.gear.persistent_id)

    await activation.execute_events(await get_damage_events_with_save_for_half(
        activation, specific, all_targets, damage_amount, Lancer.DAMAGE_TYPE.EXPLOSIVE, Lancer.HASE.HULL, on_fail_func
    ))
    if activation.abort_without_unit(unit): return
    
    if not use_move:
        use_move = await choice_bus.quick_yesno(unit.state.tile, tr("gear.cp_tengu_assisted_missile_tubes.action_heavens_downpour.choose"), tr("gear.cp_tengu_assisted_missile_tubes.action_heavens_downpour.choose.effect"), false)
        if use_move:
            await activation.queue_event(&"event_gear_activate", {
                unit = unit, 
                gear = context.gear, 
                action = action, 
                flags = [Action.FLAG.AS_FREEBIE], 
                event = activation
            }, Priority.ATTACK.movement)



static func get_damage_events_with_save_for_half(
    activation: EventCore, 
    forcing_action: SpecificAction, 
    all_targets: Array[Unit], 
    damage_amount: int, 
    damage_type: Lancer.DAMAGE_TYPE, 
    save_type: Lancer.HASE, 
    additional_effect_for_failures: Callable = func(failed_target: Unit) -> void : pass, 
    damage_flags: Array = [], 
) -> Array[EventCore] :
    var damage_events: Array[EventCore] = []
    for target: Unit in all_targets:
        if not Unit.is_valid(target): continue

        var passed_save: bool = await UnitHasecheck.make_save(activation, target, forcing_action, save_type)
        if not Unit.is_valid(target): continue

        var take_damage: int = damage_amount
        if passed_save: take_damage = Util.half(take_damage)

        var flags: Array = [Lancer.get_damage_save_flag(passed_save), Lancer.DAMAGE_FLAG.SKIP_POSTFX_DELAY]
        flags.append_array(damage_flags)
        damage_events.append(EventCore.create(&"event_unit_damage", {
            unit = target, 
            number = take_damage, 
            category = damage_type, 
            flags = flags, 
            target_unit = forcing_action.unit, 
        }))

        if not passed_save:
            await additional_effect_for_failures.call(target)
    if activation.abort_if_level_exited(): return []


    if not damage_events.is_empty():
        damage_events[damage_events.size() - 1].context.flags.erase(Lancer.DAMAGE_FLAG.SKIP_POSTFX_DELAY)
    
    return damage_events
