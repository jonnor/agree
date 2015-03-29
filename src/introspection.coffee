
agree = require '../'

# TODO: add ability to describe objects as HTML
# MAYBE: let console/string describe just render the HTML with super simple style

nl = "\n"
ind = "  "

tryDescribeFunction = (thing, prefix) ->
    contract = thing.contract
    return null if not contract
    return null if contract.constructor.name != 'FunctionContract'

    type = if contract.parent then "method" else "function"

    output = nl+prefix+"#{type} #{contract.name}()"
    # precond
    output += nl+prefix+ind+'preconditions:'
    for cond in contract.preconditions
        d = cond.name or cond.predicate?.description or cond.description or "unknown"
        output += nl+prefix+ind+ind+d

    # postcond
    output += nl+prefix+ind+'postconditions:'
    for cond in contract.postconditions
        d = cond.name or cond.predicate?.description or cond.description or "unknown"
        output += nl+prefix+ind+ind+d

    # body
    if contract.bodyFunction
        output += nl+prefix+ind+'body:'
        for line in contract.bodyFunction.toString().split '\n'
            output += nl+prefix+ind+ind+line
    
    return output

tryDescribeClass = (thing, prefix) ->
    contract = thing.contract
    return null if not contract
    return null if contract.constructor.name != 'ClassContract'

    type = if typeof thing == 'object' then "instance" else "class"

    output = prefix+"#{type} #{contract.name}"
    for name, prop of thing.prototype
        out = tryDescribeFunction prop, prefix+ind
        output += out if out
    for name, prop of thing
        out = tryDescribeFunction prop, prefix+ind
        output += out if out

    return output

# Return information
exports.describe = (thing) ->
    return "No contract" if not thing.contract?
    contract = thing.contract

    output = tryDescribeFunction thing, ""
    return output if output

    output = tryDescribeClass thing, ""
    return output if output

    output = 'Unknown contract'
    return output
