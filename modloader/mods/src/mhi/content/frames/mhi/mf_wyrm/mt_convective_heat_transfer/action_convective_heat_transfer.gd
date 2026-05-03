extends ActionReaction

@export var cht_movement_type: MovementType

func get_required_triggering_context() -> Array[Context.PROP]:
    return [Context.PROP.unit, Context.PROP.number]

func triggers_on_event(unit: Unit, gear: GearCore, triggering_event: EventCore) -> bool:
    var context: Context = triggering_event.context
    
    if not context.unit == unit: return false
    
    if (not unit.core.current.heat == 0): return false

    return true

func activate(context: Context, activation: EventCore) -> void :
    var movement_type: = cht_movement_type.duplicate()
    movement_type.merge_in(MovementType.create(context.unit, false))
    var pathfinder: Pathfinder = await Pathfinder.generate_for_movement_budget(context.unit, ceil(context.event.context.number / 2.), movement_type)
    
    var plan: CompconPlan = await TargetActionUtil.ask_for_movement_alt(
        context.unit, 
        pathfinder, 
        SpecificAction.from_context(activation.context), 
        [],
        null,
        [EventUnitPickMove.FLAG.MANDATORY]
    )
    if activation.abort_without_movement_plan(plan, context.unit): return

    var move_events: Array[EventCore] = []
    move_events.append(EventCore.create(&"event_unit_move", {
        unit = context.unit, 
        array = plan.move_path, 
        resource = movement_type, 
        flags = [EventUnitMove.FLAG.IGNORE_BEING_KNOCKED_OFF_COURSE]
    }))
    activation.queue_events(move_events)
