extends Buff

func is_buff_context_valid_for_passive(core: BuffCore, context: Context) -> bool:
    if not Action.is_valid(context.action): return false
    if not (context.action.get_action_type(SpecificAction.from_context(context)) == Lancer.ACTION.RXN): return false
    return true
