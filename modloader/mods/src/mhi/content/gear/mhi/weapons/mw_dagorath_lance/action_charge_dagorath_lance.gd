extends ActionSystemApplyBuff

#func activate(context: Context, activation: EventCore) -> void :
    #var unit: Unit = context.unit
    #var specific: = SpecificAction.from_context(context)
#
    #var target_units: Array[Unit]
    #var target_tiles: Array[Vector2i]
    #if apply_only_to_self or not UnitTargeting.requires_tile_target(specific):
        #target_units = [unit]
        #target_tiles = [unit.tile()]
        #var aoe_tiles: Array[Vector2i] = []
        #var range_pattern: = get_range_pattern_for_target(specific)
        #if range_pattern: aoe_tiles.assign(range_pattern.get_aoe_tiles(target_tiles, unit.occupied_tiles(), unit.state.occupying_size, unit.map.shape))
        #var confirmed: bool = true
        #if activation.abort_when( not confirmed): return
    #else:
        #var plan: CompconPlan = await TargetActionUtil.ask_for_targets(activation)
        #if activation.abort_without_targeting_plan(plan): return
        #target_units = plan.target_units
        #target_tiles = plan.target_tiles
    #if activation.abort_without_units(target_units): return
#
    #spend_actions(activation)
    #await run_system_fxgs(unit, target_units)
    #if activation.abort_without_unit(unit): return
#
    #await apply_buffs_to_targets(activation, specific, target_units, target_tiles)
    #if activation.abort_without_unit(unit): return
#
    #if kickstart_sibling_action != &"":
        #var sibling_action: = specific.gear.get_action(kickstart_sibling_action)
        #activation.queue_event(&"event_gear_activate", {
            #unit = specific.unit, 
            #gear = specific.gear, 
            #action = sibling_action, 
            #event = activation, 
            #flags = [Action.FLAG.AS_FREEBIE]
        #}, Priority.ACTIVATE.early_followup)

func apply_additional_effect(specific: SpecificAction, target_unit: Unit, activation: EventCore) -> void :
    specific.gear.wake_action(&"action_dagorath_lance")
    specific.gear.hibernate_action(&"action_charge_dagorath_lance")
    specific.unit.state.end_ordnance_phase()
    
