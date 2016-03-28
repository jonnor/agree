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
deferred = (trigger) ->
  state =
    resolve: null
    reject: null
  p = new Promise (resolve, reject) ->
    state.resolve = resolve
    state.reject = reject
  trigger.resolve = (val) ->
    state.resolve val
  trigger.reject = (err) ->
    state.reject err
  return p

class PromiseChain
  constructor: (@name) ->
    @chain = []

  then: (thenable) ->
    @chain.push thenable
    return this

  _render: () ->
    trigger = {}
    promise = deferred trigger
    for thenable in @chain
      promise = promise.then thenable
    return [promise, trigger]

  promisify: () ->
    [promise, trigger] = @_render()
    console.log 'p', promise
    return promise

  # returns Promise for the whole chain, pushes @value into the first one
  call: (val) ->
    [promise, trigger] = @_render()
    trigger.resolve val
    return promise

Chain = (name) ->
  return new PromiseChain name

exports.Chain = Chain
exports.PromiseChain = PromiseChain
