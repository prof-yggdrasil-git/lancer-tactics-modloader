extends ActionReactionAttacked

@export var attack_fxg: PackedScene
@export var target_fxg: PackedScene


func can_target_unit(potential_target: Unit, specific: SpecificAction) -> bool:
    if not super.can_target_unit(potential_target, specific): return false
    if not potential_target.is_character(): return false
    return true

func get_target_range(specific: SpecificAction) -> int: return 3


func get_per_round_hard_limit(specific: SpecificAction) -> int: return 1


func activate(context: Context, activation: EventCore) -> void :
    var plan: CompconPlan = await TargetActionUtil.ask_for_targets(activation)
    if activation.abort_without_target_unit_plan(plan): return

    spend_actions(activation)

    await CommonActionUtil.run_attack_and_target_fx(
        attack_fxg, context.unit, 
        target_fxg, plan.target_units, 
        null, [],
        false
    )
    
    for target_unit: Unit in plan.target_units:
        activation.queue_events(
            CommonActionUtil.generate_knockback_events(
                target_unit, 
                1, 
                SpecificAction.create(context.unit, context.gear, self)
            )
        )
        
        activation.queue_event(&"event_unit_damage", {
            unit = target_unit, 
            number = 2, 
            category = Lancer.DAMAGE_TYPE.EXPLOSIVE, 

            target_unit = context.action, 
            gear = context.gear, 
            action = context.action
        })
        
        
