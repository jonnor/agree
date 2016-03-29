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

# TODO: support introspecting 'child' functions from a chained function
# TODO: support introspecting 'parent' chain from a child function

# TODO: support other Promise composition operators than .then
# MAYBE: support custom Promise composition operators
class PromiseChain
  ## describing
  constructor: (@name) ->
    @_agreeType = 'PromiseChain'
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

  # Render chain into a function. Calling returned function executes the whole chain
  toFunction: () ->
    start = @startFunction
    if not start
      start = () ->
        return arguments[0]
    chainSelf = this

    return () ->
      context = {}
      this._agreeChain = chainSelf

      args = arguments
      promise = new Promise (resolve, reject) ->
        ret = start.apply context, args
        return resolve ret

      for thenable in chainSelf.chain
        promise = promise.then thenable.bind(context)
      return promise

  # Render chain into a function, and call it with provided @arguments
  call: (a, ...) ->
    #args = Array.prototype.slice.call arguments
    f = @toFunction()
    return f.apply this, arguments

Chain = (name) ->
  return new PromiseChain name

exports.Chain = Chain
exports.PromiseChain = PromiseChain
