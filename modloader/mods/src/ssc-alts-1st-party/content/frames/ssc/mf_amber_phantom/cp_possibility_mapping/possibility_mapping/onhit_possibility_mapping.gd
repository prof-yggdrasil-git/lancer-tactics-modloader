extends OnHitEffect

#static  var choice_bus: ChoiceBus = load("res://ui/choice_controller/choice_bus.tres")
#static  var battle_log: BattleLogBus = load("res://ui/component/battle_log/battle_log_bus.tres")

@export var bonus_damage_buff: BuffDamage

func on_hit(activation: EventCore, attacked_unit: Unit) -> void :
    var context: Context = activation.context
    #print(context.unit.core.frame.compcon_id, " ", context.target_unit.core.frame.compcon_id)
    #var weapon_mod: GearCore = context.gear.get_weapon_mod(context.unit.core.loadout)
    var gear: GearCore = context.unit.core.loadout.get_by_compcon_id(&"cp_possibility_mapping")
    if not GearCore.is_valid(gear): return

    var counter: = gear.get_die_counter_passive()
    var turns: = context.unit.core.current.activations
    for ally in context.unit.get_allied_units():
        turns += ally.core.current.activations
    var current_turn = counter.max_value - turns
    var is_predicted_turn = current_turn == counter.get_current(gear)
    #print(current_turn, " ", counter.get_current(gear))
    
    if(counter.get_current(gear) > 0):
        var specific: = SpecificAction.create(context.unit, gear, gear.kit.actions[1])
        var confirm = await CommonActionUtil.confirm_use_alt(specific)
        if not confirm: return

        UnitCondition.apply_buff_id(activation, context.unit, bonus_damage_buff.compcon_id, gear)
        
        if not is_predicted_turn:
            activation.queue_event(&"event_unit_damage", {
                unit = context.unit, 
                number = Dice.roll_d6(), 
                category = Lancer.DAMAGE_TYPE.HEAT, 
                target_unit = context.unit, 
                gear = gear, 
                action = specific,
                flags = [Lancer.DAMAGE_FLAG.SELF_INFLICTED]
            })
        
        counter.update_value(context.unit, gear, 0, true)
