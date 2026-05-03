extends BuffResistDamage

@export var buffs_cache: Dictionary = {}
@export var passive_on_hit_cache: Dictionary = {}

func is_buff_context_valid_for_passive(core: BuffCore, context: Context) -> bool:
    #print(context.unit.core.frame.compcon_id, " ", core.get_holder_unit(context.target_unit.map).core.frame.compcon_id)
    if(context.unit != core.get_holder_unit(context.unit.map)): return false
    if context.object is AttackRoll:
        var roll: AttackRoll = context.object as AttackRoll
        if roll.hit:
            return false
        return true
    return false

func triggers_on_event(core: BuffCore, unit: Unit, triggering_event: EventCore) -> bool:
    if(triggering_event.context.target_unit != unit): return false
    if not buffs_cache.has(triggering_event.context.target_unit.core.persistent_id): return false
    if triggering_event.context.object is AttackRoll:
        var roll: AttackRoll = triggering_event.context.object as AttackRoll
        if roll.hit:
            return false
        return true
    return false

func activate(core: BuffCore, activation: EventCore) -> void:
    var context: Context = activation.context.event.context
    var target_unit: Unit = context.target_unit
    var buffs: Array[BuffCore] = buffs_cache[target_unit.core.persistent_id]
    buffs_cache.erase(target_unit.core.persistent_id)
    #for buff in target_unit.state.buffs.duplicate():
        #if not buffs.has(buff):
            #UnitCondition.clear_buff(activation, target_unit, buff)
    target_unit.state.buffs = buffs
    
    #var on_hit_effects: Array[OnHitEffect] = passive_on_hit_cache[target_unit.core.persistent_id]
    for mod_id in activation.context.event.context.gear.mod_ids:
        var mod: GearCore = target_unit.core.loadout.get_by_persistent_id(mod_id)
        if GearCore.is_valid(mod):
            for passive in mod.kit.passives:
                if passive is PassiveWeaponMod:
                    passive = passive as PassiveWeaponMod
                    #passive.on_hit_effects = on_hit_effects
                    passive.on_hit_effects = passive_on_hit_cache[target_unit.core.persistent_id][mod.persistent_id][passive]
    passive_on_hit_cache.erase(target_unit.core.persistent_id)
    
