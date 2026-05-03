extends ActionReaction

#func get_per_round_hard_limit(specific: SpecificAction) -> int:
#    return UnitAction.get_deployables_from(specific.unit, specific.gear).size()

@export var fxg: PackedScene

func consumes_charges(specific: SpecificAction) -> bool: return false


func get_required_triggering_context() -> Array[Context.PROP]:
    return [Context.PROP.unit, Context.PROP.gear, Context.PROP.action, Context.PROP.resource]


func triggers_on_event(unit: Unit, gear: GearCore, triggering_event: EventCore) -> bool:
    var context: = triggering_event.context
    
    var current_deployed_ids: Array = gear.state.get(UnitAction.DEPLOYED_IDS_KEY, [])
    if current_deployed_ids.is_empty(): return false
    
    if not context.action is ActionAttackWeapon: return false
    var action : ActionAttackWeapon = context.action

    if not action.range_pattern: return false
    if not (action.range_pattern.pattern == Lancer.AOE_TYPE.LINE):
        return false
    
    var attack_summary : DeclaredAttackSummary = triggering_event.context.resource
    for drone_id in current_deployed_ids:
        for attacked_unit in attack_summary.all_attacked_units:
            if(attacked_unit.core.persistent_id == drone_id):
                return true
    
    return false

func activate(context: Context, activation: EventCore) -> void:
    var current_deployed_ids: Array = context.gear.state.get(UnitAction.DEPLOYED_IDS_KEY, [])
    var attack_summary : DeclaredAttackSummary = activation.context.event.context.resource
    
    var attacked_drones: Array[Unit] = []
    for drone_id in current_deployed_ids:
        for attacked_unit in attack_summary.all_attacked_units:
            if(attacked_unit.core.persistent_id == drone_id):
                attacked_drones.append(context.map.get_unit_by_id(drone_id))
    
    var drone: Unit = attacked_drones[0]
    var drone_dist = Tile.distance(activation.context.event.context.unit.state.tile, drone.state.tile)
    for attacked_drone in attacked_drones:
        var attacked_drone_dist = Tile.distance(activation.context.event.context.unit.state.tile, attacked_drone.state.tile)
        if(attacked_drone_dist < drone_dist):
            drone = attacked_drone
    
    var tiles: Array[Vector2i] = []
    var line_tiles: Array[Vector2i] = []
    for tile in attack_summary.all_attacked_tiles:
        if(Tile.distance(activation.context.event.context.unit.state.tile, tile) < drone_dist - 2):
            tiles.append(tile)
            line_tiles.append(tile)
    
    battle_log.log_unit("event.scatter_drone_explode.log", drone, {})
    
    tiles.append_array(Tile.get_all_within(drone.state.tile, 2, context.map))
    var units: Array[Unit] = context.map.get_all_units_at_tiles(tiles)
    units.erase(drone)
    
    var fx_group = FxGroup.create_from_scene(fxg, drone.aligned_position())
    fx_group.run()
    
    activation.queue_event(&"event_unit_die", {
        unit = drone,
        flags = []
    }, Priority.ATTACK.dice)
    
    var specific = SpecificAction.from_context(activation.context.event.context)
    var new_attack_summary = DeclaredAttackSummary.create(
        units, 
        line_tiles, 
        tiles, 
        activation.context.event.context.action.get_origin_voxels(specific, line_tiles, specific.unit.tile())
    )
    
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
