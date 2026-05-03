extends ActionReactionApplyBuff

@export var buff: Buff
@export var buff2: Buff

func is_in_soft_cover_zone(unit: Unit) -> bool:
    var soft_cover_spaces: Array[Vector2i] = []
    for dep: Unit in unit.map.get_all_units(false, false):
        if dep.core.frame.is_deployable or dep.core.frame.is_marker():
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
                                    if not soft_cover_spaces.has(tile):
                                        soft_cover_spaces.append(tile)
    if not soft_cover_spaces.has(unit.state.tile): 
        return false
    return true

func triggers_on_event(unit: Unit, gear: GearCore, triggering_event: EventCore) -> bool:
    var triggering_unit: = triggering_event.context.unit
    if not Unit.is_valid(triggering_unit): return false
    if not UnitCondition.has_buff(unit, buff.compcon_id):
        if(unit != triggering_unit): return false
    else:
        if not UnitRelation.are_allies(unit, triggering_unit): return false
        if(Tile.distance(unit.state.tile, triggering_unit.state.tile) > unit.get_sensor_range()):
            if UnitCondition.has_buff(triggering_unit, buff2.compcon_id, gear.persistent_id):
                UnitCondition.clear_buff_id(triggering_event, triggering_unit, buff2.compcon_id, gear.persistent_id)
            return false
        else:
            if not UnitCondition.has_buff(triggering_unit, buff2.compcon_id, gear.persistent_id):
                UnitCondition.apply_buff(triggering_event, triggering_unit, buff2, gear)
    
    if(triggering_event.base.event_type != &"event_turn_end"): return false
    
    if not is_in_soft_cover_zone(triggering_unit): return false
    
    return true

func activate(context: Context, activation: EventCore) -> void:
    await super.activate(context, activation)
    if activation.aborted: return
