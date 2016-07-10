# Agree - Introspectable Contracts Programming for JavaScript
# * Copyright (c) 2016 Jon Nordby <jononor@gmail.com>
# * Agree may be freely distributed under the MIT license

common = require './common'

# TODO: add ability to describe objects as HTML
# MAYBE: let console/string describe just render the HTML with super simple style

# TODO: add a test for function/method must have preconditions
# TODO: add a test for function/method must have postconditions

nl = "\n"
ind = "  "

tryDescribeFunction = (thing, prefix) ->
    contract = common.getContract thing
    return null if not contract
    return null if contract.constructor.name != 'FunctionContract'

    type = if contract.parent then "method" else "function"

    output = nl+prefix+"#{type} '#{contract.name}'"
    # precond
    output += nl+prefix+ind+'preconditions:' if contract.preconditions.length
    for cond in contract.preconditions
        d = cond.name or cond.check?.description or cond.description or "unknown"
        output += nl+prefix+ind+ind+d

    # postcond
    output += nl+prefix+ind+'postconditions:' if contract.postconditions.length
    for cond in contract.postconditions
        d = cond.name or cond.check?.description or cond.description or "unknown"
        output += nl+prefix+ind+ind+d

    # body
    evaluator = thing._agreeEvaluator
    if evaluator? and evaluator.bodyFunction
        output += nl+prefix+ind+'body:'
        for line in evaluator.bodyFunction.toString().split '\n'
            output += nl+prefix+ind+ind+line
    
    return output

tryDescribeClass = (thing, prefix) ->
    contract = common.getContract thing
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
    contract = common.getContract thing
    return "No contract" if not contract?

    output = tryDescribeFunction thing, ""
    return output if output

    output = tryDescribeClass thing, ""
    return output if output

    output = 'Unknown contract'
    return output

fbpSafeComponentName = (s) ->
  return null if not s
  return s.split(' ').join('_')

# XXX: hacky representation of PromiseChain as an FBP graph
chainToFBP = (chain) ->
  graph =
    inports: {}
    outports: {}
    processes: {}
    connections: []

  names = []
  chain.chain.forEach (step, idx) ->
    name = fbpSafeComponentName(step.description) or "then-#{idx}"
    names.push name
    component = 'agree/Function' # TODO: use name of Contract if known
    graph.processes[name] =
      component: component
      metadata: {}
    conn =
      src:
        process: names[idx-1]
        port: 'out'
      tgt:
        process: name
        port: 'in'
    if idx
      graph.connections.push conn
  return graph

executionToFlowtrace = (chain) ->
  # FIXME: actually include events from execution
  # TODO: allow to synthesize graph from functions
  trace =
    header:
      graphs: {}
    events: []
  trace.header.graphs['default'] = chainToFBP chain

  return trace

# TODO: support transforming observed events to FBP runtime network:data,
# for use with FBP clients like Flowhub and tools like Flowtrace
exports.toFBP = (thing) ->
  if thing._agreeType == 'PromiseChain'
    return chainToFBP thing
  else if typeof thing == 'function' and thing._agreeChain
    return chainToFBP thing._agreeChain
  return null

# XXX: right now can only observe one thing, which might be too inconvenient in practice
# should possibly observe a set of things. Issue is that then event monitoring / analysis also needs to take filter
class Observer
    constructor: (@thing) ->
        @reset()
        @contract = common.getContract @thing
        @evaluator = @thing?._agreeEvaluator

        if @evaluator
            @evaluator.observe (event, data) =>
                @onEvent event, data

    reset: () ->
        @events = []
        @evaluator.observe null if @evaluator

    onEvent: (eventName, payload) ->
        @events.push
            name: eventName
            data: payload
        @emit 'event', eventName, payload
        # MAYBE: emit specific events? 'precondition-failed' etc

    emit: (m, args) ->
        # TODO: allow to follow events as they happen

    toString: () ->
        # TODO: event-aware toString() formatting
        # TODO: colorize failures
        lines = []
        lines.push "agree.Observer: #{@events.length} events"
        for event in @events
            data = JSON.stringify event.data, (key, val) ->
                # avoid circular reference when context is global
                return if key == 'context' and val.global? then 'global' else val
            lines.push "  #{event.name}: #{data}"
        return lines.join '\n'

exports.Observer = Observer
exports.observe = (thing) ->
    return new Observer thing

