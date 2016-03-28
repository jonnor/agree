# Agree - Introspectable Contracts Programming for JavaScript
# * Copyright (c) 2016 Jon Nordby <jononor@gmail.com>
# * Agree may be freely distributed under the MIT license

# NOTE: move to separate library? Should be able to operate on any type of promises
# TODO: Find a better name. Technically this is a 'promise factory',
# but this does not explain about what problem it solves / why it was made / should be used.
#
# Which is to create a way of composing async/Promise functions which can be set up (quasi)statically,
# then later used for actually performing a computation.
# 
# Problem with Promise is that:
# it starts executing immediately on .then(), which is also the mechanism to constructs chain / compose promise functions
# it is single-use, keeping state of an execution
# The need to pass in an object which is then populated with props is also quite horrible API
#
# Existing Promise composition libraries/operators
# https://github.com/kriskowal/q 
# http://bluebirdjs.com/docs/api-reference.html 
#
# Common mistakes with Promises https://pouchdb.com/2015/05/18/we-have-a-problem-with-promises.html

agree = require './agree'
Promise = agree.Promise

# Construct a promise which we can later inject a value into to start the execution chain
deferred = (trigger, startFunction, startContext) ->
  state =
    resolve: null
    reject: null
  p = new Promise (resolve, reject) ->
    state.resolve = resolve
    state.reject = reject
  trigger.resolve = (args) ->
    ret = startFunction.apply startContext, args
    state.resolve ret
  trigger.reject = (err) ->
    state.reject err
  return p

# TODO: support other Promise composition operators than .then
# MAYBE: support custom Promise composition operators
class PromiseChain
  ## describing
  constructor: (@name) ->
    @startFunction = null
    @chain = []

  # alternative to setting @name in constructor
  describe: (@name) ->
    return this

  # Chaining up operations
  # FIXME: don't specialcase start internally
  start: (f) ->
    @startFunction = f
    return this

  then: (thenable) ->
    @chain.push thenable
    return this

  # Execute the chain
  _render: () ->
    trigger = {}
    start = @startFunction or () -> return arguments[0]

    promise = deferred trigger, start, this
    for thenable in @chain
      promise = promise.then thenable
    return [promise, trigger]

  # FIXME: get rid of
  promisify: () ->
    [promise, trigger] = @_render()
    return promise

  # returns Promise for the whole chain, pushes @value into the first one
  call: (a, ...) ->
    [promise, trigger] = @_render()
    args = Array.prototype.slice.call arguments
    trigger.resolve args
    return promise

Chain = (name) ->
  return new PromiseChain name

exports.Chain = Chain
exports.PromiseChain = PromiseChain
