extends ActionAttackWeapon

@export var buff: Buff
@export var buff2: Buff

func get_action_type(specific: SpecificAction) -> Lancer.ACTION:
    return Lancer.ACTION.QUICK

func requires_line_of_sight(specific: SpecificAction) -> bool:
    return false

func activate(context: Context, activation: EventCore) -> void :
    var specific: = SpecificAction.from_context(context)
    specific.unit = use_attacker_source(context.unit, context.gear, activation)

    var plan: CompconPlan = await get_attack_plan(activation, specific)
    if activation.abort_when( not CompconPlan.is_valid_with_targets(plan, context)): return

    var attacked_tiles_and_units: = await get_attacked_tiles_and_units_from_plan(activation, specific, plan)
    if activation.abort_without_unit(specific.unit): return

    var all_attacked_tiles: Array[Vector2i] = []
    var all_attacked_units: Array[Unit] = []
    all_attacked_tiles.assign(attacked_tiles_and_units.all_attacked_tiles)
    all_attacked_units.assign(attacked_tiles_and_units.all_attacked_units)


    if activation.abort_when( not await TargetActionUtil.confirm_friendly_fire(context, all_attacked_units)): return
    if activation.abort_without_unit(specific.unit): return


    var declared_attack: = DeclaredAttackSummary.create(
        all_attacked_units, 
        plan.target_tiles, 
        all_attacked_tiles, 
        get_origin_voxels(specific, plan.target_tiles, specific.unit.tile())
    )
    context.resource = declared_attack


    spend_actions(activation)


    await run_attack_effects(activation, specific, plan.target_tiles, all_attacked_tiles, all_attacked_units)
    if activation.abort_without_unit(specific.unit): return

    await activation.execute_event(&"event_unit_attack_declared", {
        unit = specific.unit, 
        gear = specific.gear, 
        action = specific.action, 
        resource = declared_attack, 
        flags = context.flags
    })
    
    var tiles: Array[Vector2i] = []
    var unit_height = context.map.elevation_los_blockers(context.unit.state.tile)
    for tile in all_attacked_tiles:
        if(context.map.elevation_los_blockers(tile) > unit_height):
            print(unit_height, " ", context.map.elevation_los_blockers(tile))
            tiles.append(tile)
    
    if not tiles.is_empty():
        await activation.execute_event(&"event_map_damage", {
            target_tiles = tiles, 
            number = 20, 
            flags = [EventMapDamage.FLAG.AP, EventMapDamage.FLAG.BURN]
        })
    
    UnitCondition.clear_buff_id(activation, context.unit, buff.compcon_id)
    UnitCondition.clear_buff_id(activation, context.unit, buff2.compcon_id)
    
    activation.context.gear.wake_action(&"action_charge_dagorath_lance")
    activation.context.gear.hibernate_action(&"action_dagorath_lance")



func on_targeted_tiles(activation: EventCore, direct_target_tiles: Array[Vector2i], all_target_tiles: Array[Vector2i]) -> void:
    pass
