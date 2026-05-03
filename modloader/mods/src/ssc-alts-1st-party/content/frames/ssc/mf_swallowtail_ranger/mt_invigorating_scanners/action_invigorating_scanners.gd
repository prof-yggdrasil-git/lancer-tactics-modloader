extends ActionReaction


func get_per_round_hard_limit(specific: SpecificAction) -> int: return 1

func get_required_triggering_context() -> Array[Context.PROP]:
    return [Context.PROP.unit, Context.PROP.category, Context.PROP.string]

func triggers_on_event(unit: Unit, gear: GearCore, triggering_event: EventCore) -> bool:
    var triggering_context: Context = triggering_event.context

    if triggering_context.category != Lancer.STATUS.LOCKON: return false

    if not GearCore.is_valid(unit.core.loadout.get_by_persistent_id(triggering_context.string)): return false

    return true

func activate(context: Context, activation: EventCore) -> void :
    #var triggering_context: Context = context.event.context
    var specific: = SpecificAction.from_context(context)
    
    #var tiles: Array[Vector2i] = []
    #for x in context.unit.map.size.x:
        #for y in context.unit.map.size.y:
            #var tile = Vector2i(x, y)
            #if(context.unit.map.shape.is_playable(tile)):
                #tiles.append(tile)
    
    #var targetable_tiles = UnitTile.get_tiles_that_can_see(context.unit.map, tiles, context.unit.get_sensor_range(), context.unit, true)
    #var allies: Array[Unit] = []
    #for ally: Unit in context.unit.get_allied_units(true):
        #if targetable_tiles.has(ally.state.tile) and ally.core.current.reactions > 0 and Tile.distance(ally.state.tile, context.unit.state.tile) <= context.unit.get_sensor_range():
            #allies.append(ally)
    var allies: Array[Unit] = UnitRelation.get_characters_within(context.unit, context.unit.get_sensor_range(), true, func(target: Unit) -> bool: return (target.core.current.reactions > 0) and UnitRelation.are_allies(target, context.unit))
    
    var confirmed: = await CommonActionUtil.confirm_use(context) #, allies
    if activation.abort_when( not confirmed): return
    spend_actions(activation)
    
    #choice_bus.show_using_action(specific)
    var target_unit: Unit = await choice_bus.choose_unit(allies, true, specific)
    
    if(target_unit != null):
        UnitAction.spend_reaction(target_unit)
        
        var movement_type = MovementType.create(target_unit, true, false)
        var pathfinder: Pathfinder = await Pathfinder.generate_for_movement_budget(target_unit, target_unit.get_speed_max(), movement_type)
        var tile = await choice_bus.choose_move_tile(target_unit, pathfinder, true, [])
        
        var move_events: Array[EventCore] = []
        move_events.append(EventCore.create(&"event_unit_set_stat", {
            unit = target_unit, 
            number = target_unit.get_speed_max(), 
            category = Statblock.PROP.speed
        }))
        move_events.append(EventCore.create(&"event_unit_move", {
            unit = target_unit, 
            array = pathfinder.path_to(tile), 
            resource = movement_type, 
            flags = [EventUnitMove.FLAG.IGNORE_BEING_KNOCKED_OFF_COURSE, EventUnitMove.FLAG.IGNORE_NOT_HAVING_ENOUGH_TO_REACH_DEST]
        }))
        move_events.append(EventCore.create(&"event_unit_set_stat", {
            unit = target_unit, 
            number = target_unit.core.current.speed, 
            category = Statblock.PROP.speed
        }))
        activation.queue_events(move_events, Priority.ATTACK.dice)
    
    
    
    
    
