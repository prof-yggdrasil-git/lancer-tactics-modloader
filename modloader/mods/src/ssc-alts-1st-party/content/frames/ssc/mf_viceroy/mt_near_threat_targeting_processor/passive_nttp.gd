extends PassiveWeaponMod

static var character_sheet_script = preload("res://ui/page/character_sheet/character_sheet.gd")
static var loaded = false

var gear_cache: Dictionary[UnlockRank, Array]
var prev_frame_id: StringName = &""
var unit_core_cache: UnitCore
var suffix: String = ".viceroy"
var frame_id: StringName = &"mf_micro_monarch"
var WM: String = "-"

func _init() -> void:
    character_sheet_script.character_sheet_bus.on_open.connect(on_character_sheet_opened)
    character_sheet_script.character_sheet_bus.on_close.connect(on_character_sheet_closed)
    character_sheet_script.character_sheet_bus.changed_character.connect(on_changed_character)
    character_sheet_script.character_sheet_bus.pick_weapon.connect(on_pick_weapon)
    
    ContentLibrary.main.finished_initial_load.connect(add_weapons)
    
    if not loaded:
        add_weapons()
        loaded = true

func get_overloaded_action_attack_weapon(action: ActionAttackWeapon) -> ActionAttackWeapon:
    var script: GDScript = action.get_script()
    var new_script = GDScript.new()
    new_script.source_code = "extends \""+script.resource_path+"""\"
func is_weapon_type(check_type: Lancer.WEAPON_TYPE, gear: GearCore = null) -> bool: return (super.is_weapon_type(check_type, gear) or Lancer.WEAPON_TYPE.CQB == check_type)

func type_description(specific_gear: GearCore = null) -> String:
    if weapon_size == Lancer.WEAPON_SIZE.NONE: return tr("lancer.actiontype.attack_basic")
    return "%s / %s %s" % [super.type_description(specific_gear), tr(Lancer.weapon_size_name(weapon_size)), tr(Lancer.weapon_type_name(Lancer.WEAPON_TYPE.CQB))]
"""
    new_script.reload()
    var new_action: = ActionAttackWeapon.new()
    new_action.set_script(new_script)
    for property in action.get_property_list():
        if(property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE):
            new_action.set(property["name"], action.get(property["name"]))
    return new_action

func add_weapons():
    var translation = Translation.new()
    translation.locale = TranslationServer.get_locale()
    
    for man: Manufacturer in ContentLibrary.main.manufacturer_library.values():
        for id: StringName in Manufacturer.all_kits[man.compcon_id]:
            if(id.begins_with("mw_") and not id.contains(".")):
                var original: Kit = ContentLibrary.main.get_kit(id)
                if not (original.compcon_id.contains(suffix) or ContentLibrary.main.gear_library.has((original.compcon_id + suffix) as StringName)):
                    var kit: Kit = original.duplicate_deep(DEEP_DUPLICATE_ALL)
                    var splt_id = id.split(WM)
                    if(len(splt_id) <= 1):
                        kit.compcon_id = (id + suffix) as StringName
                    else:
                        kit.compcon_id = (splt_id[0] + suffix + WM + WM.join(splt_id.slice(1))) as StringName
                    var path = original.resource_path.replace(".tres", suffix + ".tres")
                    kit.take_over_path(path)
                    ContentLibrary.main.compcon_id_to_path[kit.compcon_id] = path
                    
                    if not (kit.is_core_power() or kit.is_trait):
                        var valid = false
                        for i in range(len(kit.actions)):
                            if is_instance_of(kit.actions[i], ActionAttackWeapon):
                                if kit.actions[i].is_weapon_type(Lancer.WEAPON_TYPE.LAUNCHER) and not kit.actions[i].is_weapon_type(Lancer.WEAPON_TYPE.CQB):
                                    valid = true
                                    kit.actions[i].threat = 3
                                    kit.actions[i] = get_overloaded_action_attack_weapon(kit.actions[i])
                        if(valid):
                            #print(id)
                            
                            ContentLibrary.main.gear_library[kit.compcon_id] = kit
                            
                            for entry in ["name", "effect", "on_attack", "on_hit", "on_crit", "on_miss", "trigger", "confirm", "pop", "log"]:
                                var key = "gear."+id+"."+entry
                                var text = tr(key)
                                if(text == key):
                                    text = ""
                                if(entry == "name"):
                                    translation.add_message("gear."+kit.compcon_id+"."+entry, text+"")
                                else:
                                    translation.add_message("gear."+kit.compcon_id+"."+entry, text)
                                
                                for i in range(len(kit.actions)):
                                    var original_path = original.actions[i].resource_path
                                    var new_path = original_path.replace(id, kit.compcon_id).replace(suffix+".tres", ".tres").replace(".tres", suffix+".tres")
                                    if(original_path.contains("::")):
                                        new_path = original_path.split("::")[0].replace(id, kit.compcon_id).replace(suffix+".tres", suffix.path_join(original.actions[i].get_id()+suffix+".tres"))
                                    #print(original_path, " ", new_path)
                                    kit.actions[i].take_over_path(new_path)
                                    
                                    if(kit.actions[i].get_id() != ""):
                                        key = "gear."+kit.compcon_id+"."+kit.actions[i].get_id()+"."+entry
                                        text = Translate.action(original, original.actions[i], entry, false)
                                        if(text != ""):
                                            if(entry == "name"):
                                                translation.add_message(key, text+"")
                                            else:
                                                translation.add_message(key, text)
                            
                            Manufacturer.compcon_id_to_man[kit.compcon_id] = man.compcon_id

    TranslationServer.add_translation(translation)

func get_child(node: Node, name: StringName) -> Node:
    if(node != null):
        for child in node.get_children():
            if(child.name == name):
                return child
    return null

func print_children(node: Node):
    for child in node.get_children():
        print(child.name)

func get_unit_core() -> UnitCore:
    var scene_tree = Engine.get_main_loop()
    if(is_instance_of(scene_tree, SceneTree)):
        scene_tree = scene_tree as SceneTree
        var root: Node = scene_tree.get_root()
        var node: Node = root
        for name in [&"LancerTactics", &"campaign_title_screen", &"LevelTitle", &"Interface", &"Default", &"CharacterSheet"]:
            node = get_child(node, name)
        
        if(node == null):
            node = root
            for name in [&"LancerTactics", &"campaign_instant_action", &"LevelFightSetup", &"Interface", &"Default", &"CharacterSheet"]:
                node = get_child(node, name)
        
        if(node == null):
            node = root
            for name in [&"LancerTactics", &"campaign_editor", &"LevelCombatEditor", &"Interface", &"Default", &"CharacterSheet"]:
                node = get_child(node, name)
        
        if(node == null):
            node = root
            for name in [&"LancerTactics", &"campaign_instant_action", &"Gamemaster", &"Interface", &"Default", &"CharacterSheet"]:
                node = get_child(node, name)
        
        #print_children(node)
        #node.print_tree_pretty()
        return node.unit_core
    return null

func on_character_sheet_opened():
    #print("character sheet opened")
    var unit_core = get_unit_core()
    #print(unit_core.frame.compcon_id)
    prev_frame_id = unit_core.frame.compcon_id
    unit_core_cache = unit_core

func on_changed_character():
    #print("character changed")
    var unit_core = get_unit_core()
    #print(unit_core.frame.compcon_id, " ", prev_frame_id)
    if(unit_core.frame.compcon_id != prev_frame_id):
        clear_illegal_mounts(unit_core)
        
        prev_frame_id = unit_core.frame.compcon_id
    
    remove_weapons_from_licenses()
    unit_core_cache = unit_core

func on_pick_weapon(mount: MechMount, primary: bool):
    #print("pick weapon")
    remove_weapons_from_licenses()
    var unit_core = get_unit_core()
    if(unit_core.frame.compcon_id == frame_id):
        add_weapons_to_licenses(unit_core)

func on_character_sheet_closed():
    remove_weapons_from_licenses()
    clear_illegal_mounts()
    prev_frame_id = &""

func add_weapons_to_licenses(unit_core: UnitCore):
    unit_core_cache = unit_core
    var ranks = []
    for rank_progress in unit_core.pilot.licenses:
        ranks.append_array(rank_progress.tree.get_all_unlocked_ranks_for_rank(rank_progress.rank))
    for tree_id: StringName in Manufacturer.all_licenses[&"gms"]:
        var tree: UnlockTree = ContentLibrary.get_license_tree(tree_id)
        ranks.append_array(tree.get_all_unlocked_ranks_for_rank(3))
    
    for i in range(len(ranks)):
        var kits: Array[Kit] = []
        gear_cache[ranks[i]] = ranks[i].granted_gear.duplicate()
        for kit in ranks[i].granted_gear:
            var valid = false
            if not (kit.is_core_power() or kit.is_trait):
                for action: ActionAttackWeapon in kit.get_weapon_actions():
                    if action.is_weapon_type(Lancer.WEAPON_TYPE.LAUNCHER) and not action.is_weapon_type(Lancer.WEAPON_TYPE.CQB):
                        valid = true
            if valid:
                #print(kit.compcon_id)
                kits.append(ContentLibrary.main.gear_library[(kit.compcon_id + suffix) as StringName])
            else:
                kits.append(kit)
        ranks[i].granted_gear = kits

func remove_weapons_from_licenses():
    for rank: UnlockRank in gear_cache.keys():
        rank.granted_gear = gear_cache[rank]
    gear_cache = {}

func clear_illegal_mounts(unit_core = null):
    if(unit_core == null):
        unit_core = get_unit_core()
    
    if(unit_core_cache != null):
        #print("remove")
        #if(prev_frame_id == frame_id):
        if(unit_core.frame.compcon_id != frame_id):
            for weapon in unit_core_cache.loadout.get_all_weapons():
                for mount in unit_core_cache.loadout.mounts:
                    if(mount.contains_gear(weapon) and weapon.kit.compcon_id.contains(suffix)):
                        #print(weapon.kit.compcon_id)
                        #mount.clear()
                        if(weapon == mount.slot_primary):
                            mount.slot_primary.kit = ContentLibrary.main.gear_library[weapon.kit.compcon_id.replace(suffix, "") as StringName]
                        elif(weapon == mount.slot_secondary):
                            mount.slot_secondary.kit = ContentLibrary.main.gear_library[weapon.kit.compcon_id.replace(suffix, "") as StringName]
        else:
            for weapon in unit_core_cache.loadout.get_all_weapons():
                for mount in unit_core_cache.loadout.mounts:
                    if(mount.contains_gear(weapon) and not weapon.kit.compcon_id.contains(suffix)):
                        var valid = false
                        if not (weapon.kit.is_core_power() or weapon.kit.is_trait):
                            for action: ActionAttackWeapon in weapon.kit.get_weapon_actions():
                                if action.is_weapon_type(Lancer.WEAPON_TYPE.LAUNCHER) and not action.is_weapon_type(Lancer.WEAPON_TYPE.CQB):
                                    valid = true
                            if valid:
                                #mount.clear()
                                if(weapon == mount.slot_primary):
                                    mount.slot_primary.kit = ContentLibrary.main.gear_library[(weapon.kit.compcon_id + suffix) as StringName]
                                elif(weapon == mount.slot_secondary):
                                    mount.slot_secondary.kit = ContentLibrary.main.gear_library[(weapon.kit.compcon_id + suffix) as StringName]
            unit_core_cache = null
        
        
