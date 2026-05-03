extends Buff

@export var buff_foolish_urge_target : Buff
@export var puppet_movement_type : MovementType

var tiles_cache

func get_required_triggering_context() -> Array[Context.PROP]:
    return [Context.PROP.unit, Context.PROP.gear, Context.PROP.action, Context.PROP.resource]

func triggers_on_event(core: BuffCore, unit: Unit, triggering_event: EventCore) -> bool:
    var context: = triggering_event.context
    if context.unit != unit: return false
    
    if not context.action is ActionAttackWeapon: return false
    var action : ActionAttackWeapon = context.action

    if not action.range_pattern: return false
    if not (action.range_pattern.pattern == Lancer.AOE_TYPE.LINE or action.range_pattern.pattern == Lancer.AOE_TYPE.CONE):
        return false
    
    tiles_cache = triggering_event.context.resource.all_attacked_tiles
    
    return true

func activate(core: BuffCore, activation: EventCore) -> void :
    var new_units: Array[Unit] = []
    var attack_summary : DeclaredAttackSummary = activation.context.event.context.resource
    for unit in activation.context.unit.map.get_all_units():
        if(UnitCondition.has_buff(unit, buff_foolish_urge_target.compcon_id, core.persistent_id)):
            var movement_type: = puppet_movement_type.duplicate()
            movement_type.merge_in(MovementType.create(unit, false))
            var pathfinder: Pathfinder = await Pathfinder.generate_for_movement_budget(unit, unit.get_speed_max(), movement_type)
            
            #print("attacked tiles")
            #print(str(tiles_cache))
            #print("reachable tiles")
            #print(str(pathfinder.reachable_tiles))
            
            for tile in attack_summary.all_attacked_tiles:
                if not pathfinder.is_tile_standable(unit, tile, movement_type):
                    attack_summary.all_attacked_tiles.erase(tile)
            if(len(attack_summary.all_attacked_tiles) > 0):
                var target_tile = Tile.closest_possible_to(attack_summary.all_attacked_tiles, unit.state.tile)
                target_tile = Tile.closest_possible_to(pathfinder.reachable_tiles, target_tile)
                #target_tile = Tile.get_closest_pair_between(tiles_cache, pathfinder.reachable_tiles).to
                if target_tile in attack_summary.all_attacked_tiles:
                    new_units.append(unit)
                    attack_summary.all_attacked_tiles.erase(target_tile)
                
                var plan: CompconPlan = CompconPlan.create([], pathfinder.path_to(target_tile))

                var move_events: Array[EventCore] = []
                move_events.append(EventCore.create(&"event_unit_set_stat", {
                    unit = unit, 
                    number = unit.get_speed_max(), 
                    category = Statblock.PROP.speed
                }))
                move_events.append(EventCore.create(&"event_unit_move", {
                    unit = unit, 
                    array = plan.move_path, 
                    resource = movement_type, 
                    flags = [EventUnitMove.FLAG.IGNORE_BEING_KNOCKED_OFF_COURSE, EventUnitMove.FLAG.IGNORE_NOT_HAVING_ENOUGH_TO_REACH_DEST]
                }))
                move_events.append(EventCore.create(&"event_unit_set_stat", {
                    unit = unit, 
                    number = unit.core.current.speed, 
                    category = Statblock.PROP.speed
                }))
                activation.queue_events(move_events, Priority.ATTACK.dice)
                
                UnitCondition.clear_buff_id(activation, unit, buff_foolish_urge_target.compcon_id, core.persistent_id)

    UnitCondition.clear_buff_id(activation, activation.context.unit, core.base.compcon_id)
    
    new_units.append_array(attack_summary.all_attacked_units)
    var new_attack_summary = DeclaredAttackSummary.create(new_units, tiles_cache, attack_summary.directly_attacked_tiles, attack_summary.source_voxels)
    
    activation.context.event.context.resource = new_attack_summary
    
    #activation.queue_event(&"event_unit_attack_declared", {
        #unit = activation.context.event.context.unit, 
        #gear = activation.context.event.context.gear, 
        #action = activation.context.event.context.action, 
        #resource = new_attack_summary, 
        #flags = activation.context.event.context.flags
    #}, Priority.ATTACK.dice)
    #
    #activation.context.event.set_aborted()

func on_clear(event: EventCore, core: BuffCore, unit: Unit) -> void :
    for target_unit in unit.map.get_all_units():
        if(UnitCondition.has_buff(target_unit, buff_foolish_urge_target.compcon_id)):
            UnitCondition.clear_buff_id(event, target_unit, buff_foolish_urge_target.compcon_id, core.persistent_id)
    
