extends Buff

func on_application(event: EventCore, core: BuffCore, unit: Unit) -> void:
    set_speed(unit)

func on_clear(event: EventCore, core: BuffCore, unit: Unit) -> void:
    unit.core.current.speed = unit.get_speed_max() + (unit.core.current.speed - 1)

func activate(core: BuffCore, activation: EventCore) -> void:
    set_speed(activation.context.unit)

func set_speed(unit: Unit):
    if(unit.core.current.speed > 1):
        if(unit.state.spaces_moved_this_turn > 1):
            unit.core.current.speed = 0
        else:
            unit.core.current.speed = 1
