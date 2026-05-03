extends ActionSystemApplyBuff

@export var action: Action

func activate(context: Context, activation: EventCore) -> void:
    await super.activate(context, activation)
    if activation.aborted: return
    
    var specific: = SpecificAction.create(context.unit, context.gear, action)
    await activation.execute_event(&"event_gear_activate", {
        unit = specific.unit, 
        gear = specific.gear, 
        action = specific.action, 
        flags = [Action.FLAG.AS_FREEBIE], 
        event = activation
    })
