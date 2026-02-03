extends Node

var loaded_mods = {}

func _init() -> void:
    print("> Loading mods...")
    
    ContentLibrary.main = ContentLibrary.new()
    
    if(OS.has_feature("editor")):
        #var file = "<test>"
        #print("> Found ", file)
        #var success = load_mod(file)
        #if(success):
            #print("  - Load success.")
        #else:
            #print("  - Load failed.")
        
        #print("> Finished loading mods.")
        
        print("> No mods found.")

    else:
        var mods_path = OS.get_executable_path().get_base_dir().path_join("modloader").path_join("mods")
        var mod_files = DirAccess.get_files_at(mods_path)
        if(len(mod_files) > 0):
            for file in mod_files:
                if(file.ends_with(".zip") or file.ends_with(".pck")):
                    loaded_mods[file] = false
            for file in mod_files:
                if(file.ends_with(".zip") or file.ends_with(".pck")):
                    print("> Found ", file)
                    var success = load_mod(mods_path.path_join(file))
                    if(success):
                        loaded_mods[file] = true
                        print("  - Load success.")
                    else:
                        print("  - Load failed.")
            
            print("> Finished loading mods.")
        else:
            print("> No mods found.")
    
    #var li: UnlockTree = load("res://content/licenses/mhi/li_wyrm.tres")
    #li.rank_1.granted_frames.append()
    
    #var img: Resource = Image.load_from_file("/home/gavstarb/Pictures/CubeyCraig/Assets/Blocks/Failure.png")
    #img = ImageTexture.create_from_image(img)
    #var sprites = ContentLibrary.main.get_mech_frame("mf_wyrm").sprites
    #sprites.append(sprites[0])
    #sprites[0] = img
    
    print("> Loading texture packs...")
    ContentLibrary.main.build_initial_content_library()
    
    var tp_path = OS.get_executable_path().get_base_dir().path_join("modloader").path_join("texturepacks")
    if OS.has_feature("editor"):
        tp_path = "/home/gavstarb/Games/Lancer Tactics/0.4.7/modloader/texturepacks"
    var files = DirAccess.get_files_at(tp_path)
    
    if(len(files) > 0):
        for file in files:
            if(file.ends_with(".zip")):
                print("> Found ", file)
                var success = load_texture_pack(tp_path.path_join(file))
                if(success):
                    print("  - Load success.")
                else:
                    print("  - Load failed.")
    
        print("> Finished loading texture packs.")
    else:
        print("> No texture packs found.")

func _ready() -> void:
    if OS.has_feature("editor"):
        get_tree().call_deferred("change_scene_to_file", "res://lancer_tactics.tscn")
    else:
        get_tree().call_deferred("change_scene_to_file", ProjectSettings.get_setting("application/run/main_scene"))

func add_texture(resourcepath: String, filepath: String) -> bool:
    #if(filepath.ends_with("_front.png")):
    #    return true
    #elif(filepath.ends_with("_back.png")):
    #    return true
    
    var img = Util.load_external_image(filepath)
    img.resource_path = filepath
    var compcon_id = ContentLibrary.get_compcon_id_from_path(resourcepath)
    if(resourcepath.get_file().begins_with("mf_")):
        var resource = ContentLibrary.main.get_mech_frame(compcon_id)
        if(resource != null):
            resource.sprites.append(img)
            return true
        return false
    if(resourcepath.get_file().begins_with("slicetype_")):
        var resource = ContentLibrary.main.get_portrait_slice_type(compcon_id)
        if(resource != null):
            resource.load_slices()
            
            var slice = PortraitSlice.new()
            slice.base = img
            slice.key = StringName(filepath.get_file().get_basename())
            
            var front_filepath = "/".join([filepath.get_base_dir(), "%s%s%s" % [filepath.get_file().get_basename(), PortraitSliceType.PORTRAIT_FRONT_SLICE_SUFFIX, ".png"]])
            if(Util.file_exists(front_filepath)):
                slice.front = Util.load_external_image(front_filepath)
            var back_filepath = "/".join([filepath.get_base_dir(), "%s%s%s" % [filepath.get_file().get_basename(), PortraitSliceType.PORTRAIT_BACK_SLICE_SUFFIX, ".png"]])
            if(Util.file_exists(back_filepath)):
                slice.back = Util.load_external_image(back_filepath)
            
            var filename = filepath.get_file()
            for size_tag in PortraitSliceType.SIZE_TAGS:
                if filename.contains("_%s_" % size_tag) or filename.contains("_%s." % size_tag):
                    slice.size_tag = size_tag

                    slice.key = StringName(filepath.get_file().replace(
                        ("_%s_" % slice.size_tag), ""
                    ).replace(
                        ("_%s." % slice.size_tag), "."
                    ).get_basename())
            
            if slice.base and slice.base.get_size() != PortraitSandwich.MAX_SIZE:
                print("WARNING: portrait asset \"%s\" is not the required 128x128px. It is: %s" % [filepath, slice.base.get_size()])
            if slice.front and slice.front.get_size() != PortraitSandwich.MAX_SIZE:
                print("WARNING: portrait asset \"%s\" is not the required 128x128px. It is: %s" % [front_filepath, slice.front.get_size()])
            if slice.back and slice.back.get_size() != PortraitSandwich.MAX_SIZE:
                print("WARNING: portrait asset \"%s\" is not the required 128x128px. It is: %s" % [back_filepath, slice.back.get_size()])
            
            resource.loaded_slices.append(slice)
            return true
        return false
    return false

func load_mod(pack_path: String) -> bool:
    var success = true
    if not OS.has_feature("editor"):
        success = ProjectSettings.load_resource_pack(pack_path)
    if(success):
        var json: JSON = load("res://mod.json")
        if(json == null):
            print("  - Failed to load mod.json")
            return false
        print("  - Name: ", json.data["name"])
        print("  - Author: ", json.data["author"])
        print("  - Version: ", json.data["version"])
        
        if(json.data.has("dependencies")):
            for value in json.data["dependencies"]:
                print("  - Has dependency: ", value)
                var has = false
                var dep = ""
                for key: String in loaded_mods.keys():
                    if(key.begins_with(value)):
                        dep = key
                        has = true
                        break
                if has:
                    if(loaded_mods[dep]):
                        print("  - Dependency already loaded: ", dep)
                    else:
                        print("> Found ", dep)
                        var success2 = load_mod(pack_path.get_base_dir().path_join(dep))
                        if(success2):
                            loaded_mods[dep] = true
                            print("  - Load success.")
                            print("> Resuming load of ", pack_path.get_file())
                        else:
                            print("  - Load failed.")
                            print("> Resuming load of ", pack_path.get_file())
                            print("  - Could not load dependency.")
                            return false
                else:
                    print("  - Could not find dependency.")
                    return false
                
                if not OS.has_feature("editor"):
                    ProjectSettings.load_resource_pack(pack_path)
        
        var rg: ResourceGroup 
        if(json.data.has("resource_groups")):
            for key in json.data["resource_groups"].keys():
                rg = load(key)
                for value in json.data["resource_groups"][key]:
                    rg.paths.append(value)
                print("  - Added ", len(json.data["resource_groups"][key]), " entries to ", key)
        
        ContentLibrary.main.build_initial_content_library()
        
        if(json.data.has("licenses")):
            for key in json.data["licenses"].keys():
                var li = ContentLibrary.main.get_license_tree(ContentLibrary.get_compcon_id_from_path(key))
                for rank in ["rank_1", "rank_2", "rank_3"]:
                    if(json.data["licenses"][key].has(rank)):
                        var li_rank
                        match rank:
                            "rank_1": li_rank = li.rank_1
                            "rank_2": li_rank = li.rank_2
                            "rank_3": li_rank = li.rank_3
                        if(json.data["licenses"][key][rank].has("gear")):
                            for value in json.data["licenses"][key][rank]["gear"]:
                                li_rank.granted_gear.append(ContentLibrary.main.get_kit(ContentLibrary.get_compcon_id_from_path(value)))
                                print("  - Added ", ContentLibrary.get_compcon_id_from_path(value), " to rank ", rank[-1], " of ", ContentLibrary.get_compcon_id_from_path(key))
                        if(json.data["licenses"][key][rank].has("frames")):
                            for value in json.data["licenses"][key][rank]["frames"]:
                                li_rank.granted_frames.append(ContentLibrary.main.get_mech_frame(ContentLibrary.get_compcon_id_from_path(value)))
                                print("  - Added ", ContentLibrary.get_compcon_id_from_path(value), " to rank ", rank[-1], " of ", ContentLibrary.get_compcon_id_from_path(key))
                        #print(json.data["licenses"][i][key][rank])
        
        if(json.data.has("textures")):
            for key in json.data["textures"].keys():
                var count = 0 #len(json.data["textures"][i][key])
                for value in json.data["textures"][key]:
                    if add_texture(key, value):
                        count += 1
                    else:
                        print("  - Failed to add texture ", value, " to ", key)
                print("  - Added ", count, " textures to ", key)
        
        if(json.data.has("translate")):
            for key in json.data["translate"].keys():
                var translation = Translation.new()
                translation.locale = key
                var keys = json.data["translate"][key].keys()
                for key2 in keys:
                    translation.add_message(key2, json.data["translate"][key][key2])
                TranslationServer.add_translation(translation)
                print("  - Added ", len(keys), " translations for locale '", key, "'")
        
        return true
    return false

func extract_all_from_zip(reader: ZIPReader, extract_path: String):
    DirAccess.make_dir_recursive_absolute(extract_path)
    var root_dir = DirAccess.open(extract_path)

    var files = reader.get_files()
    for file_path in files:
        if file_path.ends_with("/"):
            root_dir.make_dir_recursive(file_path)
            continue

        root_dir.make_dir_recursive(root_dir.get_current_dir().path_join(file_path).get_base_dir())
        var file = FileAccess.open(root_dir.get_current_dir().path_join(file_path), FileAccess.WRITE)
        var buffer = reader.read_file(file_path)
        file.store_buffer(buffer)

func delete_dir_recursive(path: String):
    for file in DirAccess.get_files_at(path):
        if(file.ends_with("/")):
            delete_dir_recursive(path.path_join(file))
        else:
            DirAccess.remove_absolute(path.path_join(file))
    DirAccess.remove_absolute(path)

func load_texture_pack(pack_path: String) -> bool:
    var zr = ZIPReader.new()
    zr.open(pack_path)
    var extract_path = "user://texturepack_cache".path_join(pack_path.get_file().get_basename()) #pack_path.get_base_dir().path_join("_temp")
    if(DirAccess.dir_exists_absolute(extract_path)):
        delete_dir_recursive(extract_path)
    extract_all_from_zip(zr, extract_path)
    
    var json_path = extract_path.path_join("textures.json")
    if(FileAccess.file_exists(json_path)):
        var json = JSON.parse_string(FileAccess.open(json_path, FileAccess.READ).get_as_text())
        if(json.has("textures")):
            for key in json["textures"].keys():
                var count = 0 #len(json.data["textures"][i][key])
                for value in json["textures"][key]:
                    if add_texture(key, extract_path.path_join(value)):
                        count += 1
                    else:
                        print("  - Failed to add texture ", value, " to ", key)
                print("  - Added ", count, " textures to ", key)
        
        if(json.has("translate")):
            for key in json["translate"].keys():
                var translation = Translation.new()
                translation.locale = key
                var keys = json["translate"][key].keys()
                for key2 in keys:
                    translation.add_message(key2, json["translate"][key][key2])
                TranslationServer.add_translation(translation)
                print("  - Added ", len(keys), " translations for locale '", key, "'")
        
        #delete_dir_recursive(extract_path)
        return true
    
    delete_dir_recursive(extract_path)
    return false
