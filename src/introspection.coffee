
agree = require '../'

# Return information
exports.describe = (thing) ->
    return "Unknown contract" if not thing.contract?

    ind = "    "
    nl = "\n"

    contract = thing.contract

    type = "function"
    type = 'class' if typeof thing == 'object'
    type = 'method' if type == 'function' and contract.parent

    output = "#{type} #{contract.name}"

    # precond
    output += nl+ind+'preconditions:'
    for cond in contract.preconditions
        d = cond.name or cond.predicate?.description or cond.description or "unknown"
        output += nl+ind+ind+d

    # postcond
    output += nl+ind+'postconditions:'
    for cond in contract.postconditions
        d = cond.name or cond.predicate?.description or cond.description or "unknown"
        output += nl+ind+ind+d

    # body
    if contract.bodyFunction
        output += nl+ind+'body:'
        for line in contract.bodyFunction.toString().split '\n'
            output += nl+ind+ind+line
    
    return output
