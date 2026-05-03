extends ActionReaction

const DEPLOYED_IDS_KEY: String = "deployed_ids"


@export var actions: Array[Action] = []

func triggers_on_event(unit: Unit, gear: GearCore, triggering_event: EventCore) -> bool:
    if(unit != triggering_event.context.unit): return false
    return true

func activate(context: Context, activation: EventCore) -> void:
    var tiles: Array[Vector2i] = []
    for x in context.unit.map.size.x:
        for y in context.unit.map.size.y:
            var tile = Vector2i(x, y)
            if(context.unit.map.shape.is_playable(tile)):
                tiles.append(tile)
    
    var possible_actions: Array[SpecificAction] = []
    for action in actions:
        action.valid_tiles = tiles
        possible_actions.append(SpecificAction.create(context.unit, context.gear, action))
    
    var chosen: SpecificAction = await TargetActionUtil.choice_bus.choose_from_gear(
        possible_actions,
        tr("gear.mt_scout_battlefield.choose"),
        true
    )
    
    if(chosen != null):
        await activation.execute_event(&"event_gear_activate", {
            unit = chosen.unit, 
            gear = chosen.gear, 
            action = chosen.action, 
            flags = [Action.FLAG.AS_FREEBIE], 
            event = activation
        })
    else:
        return
    
    chosen = await TargetActionUtil.choice_bus.choose_from_gear(
        possible_actions,
        tr("gear.mt_scout_battlefield.choose"),
        true
    )
    
    if(chosen != null):
        var deployed_ids = chosen.gear.get_state_string_array(UnitAction.DEPLOYED_IDS_KEY)
        if(len(deployed_ids) > 0):
            var dep: Unit = chosen.unit.map.get_unit_by_id(deployed_ids[0])
            var dep_tiles = []
            if dep.core.frame.is_marker():
                for dep_gear: GearCore in dep.core.loadout.get_all_gear():
                    for passive in dep_gear.kit.passives:
                        if is_instance_of(passive, PassiveTerrainZone):
                            passive = passive as PassiveTerrainZone
                            if(passive.terrain_data != null):
                                if(passive.terrain_data.cover == TerrainData.COVER.SOFT):
                                    for tile in passive.range_pattern.get_aoe_tiles(
                                        passive.range_pattern.pattern,
                                        passive.range_pattern.value,
                                        dep.map.shape,
                                        dep.get_size(),
                                        [dep.state.tile] as Array[Vector2i],
                                        [dep.state.tile] as Array[Vector2i]
                                    ):
                                        if not dep_tiles.has(tile):
                                            dep_tiles.append(tile)
            else:
                dep_tiles.append_array(dep.occupied_tiles())
            
            if(chosen == possible_actions[0] or chosen == possible_actions[1]):
                for tile in dep_tiles.duplicate():
                    for vec in [Vector2i(0, -1), Vector2i(-1, -1), Vector2i(-1, 0)]:
                        if not dep_tiles.has(tile + vec):
                            dep_tiles.append(tile + vec)                    
            
            for tile in dep_tiles:
                for tile2 in Tile.get_all_within(tile, 4, chosen.unit.map):
                    if tiles.has(tile2):
                        tiles.erase(tile2)
    
        await activation.execute_event(&"event_gear_activate", {
            unit = chosen.unit, 
            gear = chosen.gear, 
            action = chosen.action, 
            flags = [Action.FLAG.AS_FREEBIE], 
            event = activation
        })
    
    chosen.unit.state.is_using_protocols = true
