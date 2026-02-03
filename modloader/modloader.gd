#!/usr/bin/env -S godot -s
#extends SceneTree
extends Node

func _init() -> void:
    var scene_tree = Engine.get_main_loop()
    if(is_instance_of(scene_tree, SceneTree)):
        scene_tree = scene_tree as SceneTree
        print("[Modloader Enabled]")
        #modded_start(scene_tree)
        modded_start.call_deferred(scene_tree)
    else:
        print("> Failed to find SceneTree")

func modded_start(scene_tree: SceneTree) -> void:
    var cwd = OS.get_executable_path().get_base_dir()
    if not DirAccess.dir_exists_absolute(cwd.path_join("modloader")):
        cwd = "user://"
    
    var pack_path = cwd.path_join("modloader").path_join("modloader.pck")
    #if OS.has_feature("macos"):
    #    pack_path = pack_path.replace("Lancer Tactics.app/Contents/MacOS/", "")
    var success = ProjectSettings.load_resource_pack(pack_path)
    #var success = ProjectSettings.load_resource_pack("/home/gavstarb/Programming/Godot/Projects/Lancer Tactics - Modded/modloader.pck")
    #var success = true
    
    if(success):
        #root.set_title(pack_path)
        scene_tree.root.set_title("%s (Modded)" % ProjectSettings.get_setting("application/config/name"))
        while X.live_worker_threads > 0: await X.process_frame()
        scene_tree.change_scene_to_file.call_deferred("res://modloader.tscn")
        #change_scene_to_file.call_deferred(ProjectSettings.get_setting("application/run/main_scene"))
    else:
        print("> Failed to find modloader pck, exiting...")
        scene_tree.quit()
