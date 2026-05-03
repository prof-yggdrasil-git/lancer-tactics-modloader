extends ActionSystemMovement



func get_per_turn_soft_limit(specific: SpecificAction) -> int:
    return 99

func is_available_to_activate(unit: Unit, gear: GearCore) -> bool:
    if not super.is_available_to_activate(unit, gear): return false
    if UnitCondition.has_status(unit, Lancer.STATUS.FLYING): return false
    if UnitCondition.has_status(unit, Lancer.STATUS.GRAPPLED): return false
    return UnitCondition.can_fly(unit)

func generate_action_pathfinder(specific: SpecificAction) -> Pathfinder:
    return await Pathfinder.generate_for_standard_move(specific.unit, get_movement_type(specific.unit), false)

func activate(context: Context, activation: EventCore) -> void :
    var unit: Unit = context.unit
    var boost_gear: GearCore = context.gear
    var moving_specific: = SpecificAction.from_context(context)
    moving_specific.unit = swap_out_moving_unit(context.unit, context.gear)
    
    var use_movement_type: = get_movement_type(moving_specific.unit)
    
    var saved_current_move: int = unit.core.current.speed
    unit.core.current.speed = unit.get_speed_max()
    var pathfinder: Pathfinder = await generate_fake_flying_pathfinder(activation, moving_specific)
    if activation.abort_without_unit(moving_specific.unit): return
    unit.core.current.speed = saved_current_move
    
    var plan: CompconPlan = await TargetActionUtil.ask_for_movement(context, pathfinder)
    if not CompconPlan.is_valid_with_movement(plan, unit): return
    
    #spend_actions(activation)
    #await activation.execute_event(&"event_unit_boost", {unit = context.unit, event = activation})
    #if activation.abort_without_unit(moving_specific.unit): return
    
    context.resource = use_movement_type
    await activation.execute_reaction_events(ReactionBus.TRIGGER.ENTIRE_MOVEMENT, ReactionBus.TIMING.PRE)
    if activation.abort_without_unit(moving_specific.unit): return
    
    EventUnitMove.ignore_engagement_from_adjacent_units(unit, activation)
    
    UnitCondition.apply_status(activation, unit, Lancer.STATUS.FLYING, Lancer.UNTIL.END_OF_MOVE, boost_gear.persistent_id)
    
    activation.queue_event(&"event_unit_move", {
        unit = unit, 
        array = plan.move_path, 
        resource = use_movement_type, 
    })
    
    unit.core.current.speed = saved_current_move
