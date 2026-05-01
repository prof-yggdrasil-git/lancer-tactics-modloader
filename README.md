# Lancer Tactics Modloader
A mod loader for [Lancer Tactics](https://wick.itch.io/lancer-tactics), compatible with version v0.7.1.
- i'm doing hacky updates for 0.7.1, all credit to GavstarB for building the base code
- i recommend using a second copy of the game folder entirely, and keeping an original copy of any pilots you update to use modded licenses/frames/weapons/core bonuses

*(Older modloader versions for v0.4.7+ can be found in the* `/old/` *directory)*

## Installation
- Click the green code button and download zip.
- Unzip into the game folder.
- Make sure the `modloader` folder and `override.cfg` file are in the same directory as your game executable (i.e. `LancerTactics.exe` on Windows).
- Run the Lancer Tactics executable.

*(To disable the modloader, rename or remove the* `override.cfg` *file)*

**Due to Godot's removal of the** `--script` **parameter, users on MacOS are currently unable to use the modloader.**

## Where can I find Mods?
- Mods made by **GavstarB** (me) can be found [here](https://github.com/GavstarB/lancer-tactics-mods).
- Compatible versions for 0.7.1 will be included in this codebase for ease of use

## How it works
- `override.cfg` loads the `modloader/modloader.gd` script and runs it in the game's context. It uses this script to patch the `modloader/modloader.pck` file into the game. It then switches scene to a scene loaded from that file.
- In the modloader scene, it then runs the code for detecting and loading mods and texture packs. A loaded .pck can only add or replace game resources outright, so each mod and texture pack contains a `mod.json` or `textures.json` file, which tells the modloader which of the game's resources it needs to add references to so it can load the new content. Otherwise, the same resource file would need to be replaced over and over to add each mod's references, leaving only the version with references to the last loaded mod's resources and breaking all the other mods.
- Once all modded content is loaded, it switches scene to the game's default scene.

Note: the modloader currently replaces several game files in order to ensure mod functionality, which are not included in the `/src/` directory on this page because they contain game source code.

## Making Texture Packs
A texture pack allows adding alternative tokens for mechs and additional assets to the in-game character creator. It is a .zip file containing image assets and a `textures.json` file formatted as in the example below:

```
{
    "textures": {
        "slicetype_accessories_other": [
            "example_accessory.png"
        ],
        "mf_goblin": [
            "example_mech_token.png"
        ]
    }
}
```

Frame names use the compcon id and so are usually in the form `mf_<name>` (with the notable exception of the Everest and Viceroy, which are `mf_standard_pattern_i_everest` and `mf_micro_monarch`).

The valid character creator slices are:
- `slicetype_accessories_glasses`
- `slicetype_accessories_hair`
- `slicetype_accessories_jewelry`
- `slicetype_accessories_other`
- `slicetype_accessories_scarves`
- `slicetype_beard`
- `slicetype_body`
- `slicetype_body_texture`
- `slicetype_clothing_inner`
- `slicetype_clothing_outer`
- `slicetype_ears`
- `slicetype_eyebrows`
- `slicetype_eyes`
- `slicetype_head`
- `slicetype_head_texture`
- `slicetype_mouth`
- `slicetype_mustache`
- `slicetype_nose`

If you register an asset called `example.png`, the modloader will automatically load the assets `example_back.png` and `example_front.png` if they exist. In the character creator, these define the foreground and background layers. For mechs, `example_back.png` is used when the token is facing away from the camera.

Certain red, green and blue color values are replaced at runtime with the colors chosen in the customization options. Green `#00FF00` also seems to be used as a mask in some of the character creator slices.

An asset pack released by Gen, who made the Lancer Tactics sprites, can be found [here](https://gentrigger.itch.io/lancer-tactics-mech-sprites). It contains the color keys, templates, and mech assets used for the game.

## Making mods
To make mods, you will need the game's source code. Currently, the only method of getting it is decompiling the game executable, which you do at your own risk.

After making your mod, you will need to make the file `res://mod.json`, formatted as in the example below:

```
{
    "name": "Example Mod",
    "author": "GavstarB",
    "version": "1.0",
    "resource_groups": {
        "res://engine/resource_groups/resgrp_buffs.tres": [
            "res://content/gear/em/systems/ms_example/buff_example.tres"
        ],
        "res://engine/resource_groups/resgrp_frames.tres": [
            "res://content/frames/em/mf_example/mf_example.tres"
        ],
        "res://engine/resource_groups/resgrp_kits.tres": [
            "res://content/gear/em/systems/ms_example/ms_example.tres"
        ],
        "res://engine/resource_groups/resgrp_licenses.tres": [
            "res://content/licenses/em/li_example.tres"
        ],
        "res://engine/resource_groups/resgrp_manufacturers.tres": [
            "res://content/manufacturers/man_em.tres"
        ]
    },
    "licenses": {
        "res://content/licenses/gms/li_gms.tres": {
            "rank_1": {
                "gear": [
                    "res://content/gear/em/systems/ms_example.tres"
                ],
                "frames": [
                    "res://content/frames/em/mf_example/mf_example.tres"
                ]
            },
            "rank_2": {
                "gear": [],
                "frames": []
            },
            "rank_3": {
                "gear": [],
                "frames": []
            }
        }
    },
    "textures": {
        "slicetype_accessories_other": [
            "example_accessory.png"
        ]
    },
    "translate": {
        "en": {
            "lancer.man.em": "Example Manufacturer",
            "lancer.man.em.short": "EM",
            "frame.mf_example.name": "Example Frame",
            "frame.mf_example.flavor": "Flavor text.",
            "frame.mf_example.flavor.short": "Example",
            "gear.ms_example.name": "Example System",
            "gear.ms_example.effect": "Example description.",
            "gear.ms_example.action_example.name": "Example Action",
            "gear.ms_example.action_example.effect": "Example description."
        }
    }
}
```

Only the `name`, `author` and `version` fields are required, the others can be safely omitted.

Registering mechs or gear with rank 1 of `res://content/licenses/gms/li_gms.tres` will make them available to all characters without needing to be unlocked.

When making a .pck, make sure to export only the files you made, including `mod.json`. The `mod.json` configuration will register your new resources with the game resources automatically. Replacing those game resources will almost certainly break other mods loaded before yours.

There is currently no detailed guide on how to make and export a mod, but when one exists I will link it here.
