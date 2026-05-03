extends Buff

func is_in_soft_cover_zone(unit: Unit, tile_override: Vector2i = Tile.INVALID) -> bool:
    var unit_tile: = unit.state.tile
    if(tile_override != Tile.INVALID):
        unit_tile = tile_override
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
    if not soft_cover_spaces.has(unit_tile): 
        return false
    return true

func is_ally(unit1: Unit, unit2: Unit):
    unit1.get_faction()
    

func triggers_on_event(core: BuffCore, unit: Unit, triggering_event: EventCore) -> bool:
    var triggering_context: = triggering_event.context
    var triggering_unit: = triggering_context.unit
    var owner_unit: = core.get_owner_unit(triggering_context.map)

    match triggering_event.base.event_type:
        &"event_unit_move":
            if(triggering_unit != unit): return false
            if is_in_soft_cover_zone(triggering_unit, triggering_context.target_tiles[0]): return false
        &"event_unit_damage":
            if(triggering_unit == unit):
                if(triggering_context.category as Lancer.DAMAGE_TYPE) == Lancer.DAMAGE_TYPE.HEAT: return false
            else:
                if(triggering_context.target_unit == null): return false
                if(triggering_context.target_unit != unit): return false
        &"event_unit_attack":
            if(triggering_unit != unit): return false
        &"event_unit_save":
            if not Unit.is_valid(triggering_unit): return false
            if(triggering_unit != unit): return false
        &"event_unit_apply_status":
            var gear: = owner_unit.map.get_gear_by_id(triggering_context.string)
            if not GearCore.is_valid(gear): return false
            if not unit.core.loadout.get_all_gear().has(gear): return false
            if UnitRelation.are_allies(unit, triggering_unit): return false

    return true

func activate(core: BuffCore, activation: EventCore) -> void:
    UnitCondition.clear_buff(activation, activation.context.unit, core)
