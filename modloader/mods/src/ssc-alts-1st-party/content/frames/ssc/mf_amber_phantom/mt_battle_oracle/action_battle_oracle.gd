extends ActionReactionAttacked

func get_per_round_hard_limit(specific: SpecificAction) -> int: return 1

func activate(context: Context, activation: EventCore) -> void:
    var specific: = SpecificAction.create(context.unit, context.gear, context.action)
    
    var units: Array[Unit] = []
    var unit_tiles: Array[Vector2i] = []
    for unit in UnitRelation.get_characters_within(context.unit, context.unit.get_sensor_range(), false):
        units.append(unit)
        unit_tiles.append(unit.state.tile)
    
    if units.is_empty(): return
    spend_actions(activation)
    
    await camera_bus.show_all_tiles(unit_tiles)
    
    var target_unit: Unit = await choice_bus.choose_unit(units, true, specific)
    
    var movement_type: = MovementType.create_for_involuntary(target_unit)
    movement_type.must_move_max_possible = true
    movement_type.straight_line = true
    #var pathfinder: Pathfinder = await Pathfinder.generate_for_movement_budget(target_unit, 2, movement_type)
    var tiles: Array[Vector2i] = []
    var height = target_unit.map.elevation(target_unit.state.tile)
    for tile in Tile.get_all_within(target_unit.state.tile, 2, target_unit.map):
        if(target_unit.map.elevation(tile) <= height + Tile.distance(target_unit.state.tile, tile)):
            tiles.append(tile)
    
    var pathfinder: Pathfinder = await Pathfinder.generate_for_given_tiles(target_unit, tiles, movement_type)

    var plan: CompconPlan = await TargetActionUtil.ask_for_movement_alt(target_unit, pathfinder, specific)
    if activation.abort_without_movement_plan(plan, target_unit): return

    activation.queue_event(&"event_unit_move", {
        unit = target_unit, 
        array = plan.move_path, 
        resource = movement_type, 
    })
