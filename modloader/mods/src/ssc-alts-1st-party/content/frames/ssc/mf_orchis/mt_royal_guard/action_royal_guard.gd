extends ActionReaction

static  var map_bus: MapBus = preload("res://engine/gamemaster/map/map_bus.tres")

var follow_unit: Unit = null
var triggered: Dictionary = {}

func triggers_on_event(unit: Unit, gear: GearCore, triggering_event: EventCore) -> bool:
    if(triggering_event.base.event_type == &"event_turn_start"):
        follow_unit = null
        for key in triggered.keys():
            triggered[key] = false
        var counter: = gear.get_die_counter_passive()
        if(triggering_event.context.unit == unit or counter.get_current(gear) == 99):
            counter.update_value(unit, gear, unit.get_speed_max() + 2, true)
        return false
    if(triggering_event.base.event_type == &"event_unit_move"):
        if(triggering_event.context.unit == unit): 
            triggered[unit] = false
            return false
        if not Unit.is_valid(triggering_event.context.unit): return false
        if not UnitRelation.is_adjacent(triggering_event.context.unit, unit): return false
        if(triggering_event.context.unit.state.tile == unit.state.tile): return false
        if not UnitRelation.are_allies(triggering_event.context.unit, unit): return false
        var movement_type: MovementType = triggering_event.context.resource
        if movement_type:
            if movement_type.teleport: return false
        if UnitCondition.is_immobilized(unit): return false
        if UnitCondition.has_status(unit, Lancer.STATUS.SLOWED): return false
        #print(triggered)
        if triggered.has(unit):
            if triggered[unit]: return false
        triggered[unit] = true
        return true
    return false

func activate(context: Context, activation: EventCore) -> void:
    var unit: Unit = context.unit
    var moving_unit: Unit = activation.context.event.context.unit
    var specific: = SpecificAction.from_context(context)
    
    var counter: = context.gear.get_die_counter_passive()
    if(counter.get_current(context.gear) > 1):
        
        if(follow_unit != moving_unit):
            var follow = await CommonActionUtil.confirm_use_alt(specific)
            if not follow: 
                triggered[unit] = false
                return
            follow_unit = moving_unit
        
        var target_tile: Vector2i = Tile.INVALID
        if(activation.context.event.context.array.is_empty()):
            target_tile = activation.context.event.context.target_tiles.front()
        else:
            target_tile = activation.context.event.context.array.back().tile
        var diff = (target_tile - follow_unit.state.tile)
        target_tile = unit.state.tile + diff
        #print(diff)
        #print(target_tile)
        
        var movement_type = MovementType.create_for_standard_move(unit)
        movement_type.ignore_engagement = true
        movement_type.ignore_rxns = true
        movement_type.spend_move = false
        
        var statuses_cache: = moving_unit.state.statuses.duplicate()
        moving_unit.state.statuses.append(StatusCondition.new(Lancer.STATUS.EXILED, Lancer.UNTIL.MANUAL, context.gear.persistent_id))
        #UnitTile.update_tracking_and_statuses(unit.map)
        #map_bus.update_unit_tile_tracking.emit()
        moving_unit.update_cached_values_and_token()
        
        #var pathfinder = await Pathfinder.generate_for_movement_budget(unit, counter.get_current(context.gear)-1, movement_type)
        var pathfinder = await Pathfinder.generate_for_given_tiles(unit, Tile.get_all_within(unit.state.tile, Tile.distance(unit.state.tile, target_tile), unit.map), movement_type)
        
        moving_unit.state.statuses = statuses_cache
        #map_bus.update_unit_tile_tracking.emit()
        moving_unit.update_cached_values_and_token()
        #UnitTile.update_tracking_and_statuses(unit.map)
        
        var path = pathfinder.path_to(target_tile)
        #print(path, " ", len(path))
        for i in range(len(path)):
            if not pathfinder.is_tile_standable(unit, path.back().tile, movement_type):
                if not (unit.map.get_all_units_at_tile(path.back().tile) == [moving_unit]):
                    path.pop_back()
            elif pathfinder.get_cost_to_tile(path.back().tile) > counter.get_current(context.gear)-1:
                path.pop_back()
        if path.is_empty(): 
            triggered[unit] = false
            return
        target_tile = path.back().tile
        var cost = pathfinder.get_cost_to_tile(target_tile)
        #print(target_tile)
        #print(cost)
        
        #effect_bus.play_text("-"+str(mini(cost, counter.get_current(context.gear) - 1)), unit.state.tile)
        effect_bus.play_text(tr("gear.mt_royal_guard.pop") % str(maxi((counter.get_current(context.gear) - cost) - 1, 0)), unit.state.tile)
        counter.update_value(unit, context.gear, maxi(counter.get_current(context.gear) - cost, 1), true)

        var dot = Vector2(diff).dot(Vector2(moving_unit.state.tile - unit.state.tile))
        #effect_bus.play_text(str(dot), unit.state.tile)
        if(dot < 0):
            activation.queue_event(&"event_unit_move", {
                unit = unit,
                array = path,
                resource = movement_type,
                object = specific
            })
        else:
            activation.context.event.queue_event(&"event_unit_move", {
                unit = unit,
                array = path,
                resource = movement_type,
                object = specific
            })
    
    follow_unit = null #prompt every time
    
    
    
    
