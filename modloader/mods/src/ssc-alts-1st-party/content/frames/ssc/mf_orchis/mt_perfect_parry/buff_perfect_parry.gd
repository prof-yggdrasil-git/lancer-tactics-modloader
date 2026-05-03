extends Buff

@export var buff: Buff

func triggers_on_event(core: BuffCore, unit: Unit, triggering_event: EventCore) -> bool:
    #print(triggering_event.context.target_unit.core.frame.compcon_id, " ", triggering_event.context.unit.core.frame.compcon_id, " ", unit.core.frame.compcon_id)
    if(triggering_event.context.target_unit != unit): return false
    return true

func activate(core: BuffCore, activation: EventCore) -> void:
    var unit: Unit = activation.context.unit
    
    activation.context.event.context.action = get_overloaded_action_attack(activation.context.event.context.action)
    #if activation.context.event.context.action is ActionAttackWeapon:
        #print("TRUE")
        #activation.context.event.context.action.reliable_damage = ""
    var on_hit_effects: Array[OnHitEffect] = []
    for on_hit_effect: OnHitEffect in activation.context.event.context.action.on_hit_effects:
        on_hit_effects.append(get_overloaded_on_hit_effect(on_hit_effect))
    activation.context.event.context.action.on_hit_effects = on_hit_effects
    
    UnitCondition.apply_buff(activation, unit, buff)
    buff.buffs_cache[unit.core.persistent_id] = unit.state.buffs.duplicate()
    var buff_cores: Array[BuffCore] = []
    for buff_core: BuffCore in buff.buffs_cache[unit.core.persistent_id]:
        if(buff_core.base.to == Buff.TO.ONHIT_EFFECT):
            var new_buff_core = buff_core.duplicate()
            new_buff_core.base = get_overloaded_buff(new_buff_core.base)
            if(new_buff_core.base != null):
                buff_cores.append(new_buff_core)
        else:
            buff_cores.append(buff_core)
    unit.state.buffs = buff_cores
    
    buff.passive_on_hit_cache[unit.core.persistent_id] = {}
    for mod_id in activation.context.event.context.gear.mod_ids:
        var mod: GearCore = unit.core.loadout.get_by_persistent_id(mod_id)
        if GearCore.is_valid(mod):
            buff.passive_on_hit_cache[unit.core.persistent_id][mod.persistent_id] = {}
            for passive in mod.kit.passives:
                if passive is PassiveWeaponMod:
                    passive = passive as PassiveWeaponMod
                    buff.passive_on_hit_cache[unit.core.persistent_id][mod.persistent_id][passive] = passive.on_hit_effects.duplicate()
                    var on_hit_effects2: Array[OnHitEffect] = []
                    for on_hit_effect: OnHitEffect in passive.on_hit_effects:
                        on_hit_effects2.append(get_overloaded_on_hit_effect(on_hit_effect))
                    passive.on_hit_effects = on_hit_effects2
    
    #var weapon_mods: Array[PassiveWeaponMod] = context.gear.get_weapon_mod_passives(unit.core.loadout)
    #var mod_on_hit_effects: Array[OnHitEffect] = []
    #for mod: PassiveWeaponMod in weapon_mods: mod_on_hit_effects.append_array(mod.on_hit_effects)
    #
    #var buff_on_hits: Array[BuffCore] = UnitCondition.get_buffs_to(unit, Buff.TO.ONHIT_EFFECT, context)
    #var buff_on_hit_effects: Array[OnHitEffect] = []
    #for onhit_buff: BuffCore in buff_on_hits: buff_on_hit_effects.append_array(onhit_buff.get_values(context).array)



func get_overloaded_action_attack(action: ActionAttack) -> ActionAttack:
    var script: GDScript = action.get_script()
    var new_script = GDScript.new()
    var extend = "ActionAttack"
    if(script.resource_path != ""):
        extend = "\""+script.resource_path+"\""
    new_script.source_code = "extends "+extend+"""
func on_attack(activation: EventCore, attacked_unit: Unit) -> void:
    if activation.context.object is AttackRoll:
        var roll: AttackRoll = activation.context.object
        if roll.hit:
            super.on_attack(activation, attacked_unit)        
    else:
        super.on_attack(activation, attacked_unit)
"""
    new_script.reload()
    var new_action: = ActionAttack.new()
    new_action.set_script(new_script)
    for property in action.get_property_list():
        if(property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE):
            new_action.set(property["name"], action.get(property["name"]))
    return new_action

func get_overloaded_on_hit_effect(on_hit: OnHitEffect) -> OnHitEffect:
    var script: GDScript = on_hit.get_script()
    var new_script = GDScript.new()
    var extend = "OnHitEffect"
    if(script.resource_path != ""):
        extend = "\""+script.resource_path+"\""
    new_script.source_code = "extends "+extend+"""
func apply_statuses_and_buffs(stage: STAGE, activation: EventCore, attacked_unit: Unit) -> void:
    if not (stage == STAGE.ON_ATTACK):
        super.apply_statuses_and_buffs(stage, activation, attacked_unit)

func on_attack(activation: EventCore, attacked_unit: Unit) -> void:
    if activation.context.object is AttackRoll:
        var roll: AttackRoll = activation.context.object
        if roll.hit:
            super.on_attack(activation, attacked_unit)        
    else:
        super.on_attack(activation, attacked_unit)
"""
    new_script.reload()
    var new_on_hit: = OnHitEffect.new()
    new_on_hit.set_script(new_script)
    for property in on_hit.get_property_list():
        if(property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE):
            new_on_hit.set(property["name"], on_hit.get(property["name"]))
    return new_on_hit

func get_overloaded_buff(buff2: Buff) -> Buff:
    if(buff2 != null):
        var script: GDScript = buff2.get_script()
        var new_script = GDScript.new()
        var extend = "Buff"
        if(script.resource_path != ""):
            extend = "\""+script.resource_path+"\""
        new_script.source_code = "extends "+extend+"""
    func get_values(core: BuffCore, context: Context = null) -> Context:
        if(overload_context != null):
            if(context != null):
                if context.object is AttackRoll:
                    var roll: AttackRoll = context.object as AttackRoll
                    if roll.hit:
                        return super.get_values(core, context)
        return Context.create({ array = [] })
    """
        new_script.reload()
        var new_buff: = Buff.new()
        new_buff.set_script(new_script)
        for property in buff2.get_property_list():
            if(property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE):
                new_buff.set(property["name"], buff2.get(property["name"]))
        return new_buff
    return null
