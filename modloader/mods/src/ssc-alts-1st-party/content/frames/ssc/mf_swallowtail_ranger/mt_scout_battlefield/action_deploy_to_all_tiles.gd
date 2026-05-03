extends ActionSystemDeploy

@export var valid_tiles: Array[Vector2i] = []

func targetable_tiles_override(specific, tiles_chosen_so_far, from_tile, precalculated_los) -> Array[Vector2i]:
    return valid_tiles.duplicate()

func get_target_requirements(specific: SpecificAction) -> TargetRequirements:
    var target_requirements = super.get_target_requirements(specific)
    target_requirements.targetable_tiles_override = targetable_tiles_override
    return target_requirements

func activate(context: Context, activation: EventCore) -> void:
    await super.activate(context, activation)
    if activation.aborted: return
