# Agree - Introspectable Contracts Programming for JavaScript
# * Copyright (c) 2016 Jon Nordby <jononor@gmail.com>
# * Agree may be freely distributed under the MIT license

## Contracts
# Allows specifying pre/post-conditions, class invariants on function, methods and classes.
#
# Contracts core
# FIXME: add more flexible default error/precondfail reporting.
#    - .error 'throws' | 'callback' | 'return' ?
# FIXME: make post-condition and invariants also obey/use onError callback
# TODO: add first-class support for Promises, wrapper for node.js type async callbacks
#   - initially should be just for the body. Secondarily we could try to support async preconditions?
#   - since preconditions may rely on state not available sync, one should write a wrapper which
#   fetches all data to be asserted in preconditions, then pass it in as arguments
#  Should work with any A+/ES6/ES2015-compatible promises
#
#  Open questions
#   - when a function body errors, should we then still evaluate the post-conditions?
#   - if we do, should we report these in onError? should we pass the body error, or not fire at all?
#   should there be a way to indicate functions which may fail (without it being a bug)
#
# API considerations
#
# - functions and classes/objects have-a (set of) contract(s)
# - contracts should be declarable as an entity, and then later, associated with zero or more functions/classes
# - as a convenience, should be possible to declare the contract for function/class 'inline'
# - but for public APIs, contracts should always be declared separately - to encourage tracking them closely
# - MAYBE: have a way to create contracts/functions which inherit others
#
# Later
#
# TODO: allow to compose Contracts and/or have multiple on one function/class
# TODO: allow pre/postconditions on init/constructor functions
# TODO: allow to declare properties, and invariants on them, using ES5 Object.defineProperty
# https://developer.mozilla.org/de/docs/Web/JavaScript/Reference/Global_Objects/Object/defineProperty
# TODO: A way to declare and verify symmetrical functions, ie ones which cancel eachother out
# requires to defined equality operators, over some context/domain?
# example: increment()/decrement(), init()/reset(), push()/pop()
# MAYBE: allow to 'inherit' when replacing a function, on object or prototype
#
# Debugging
# - TODO: ability to log failing predicates, including description, location of fail, reason for fail
# - TODO: ability to cause failing predicate to cause breakpoint using `debugger` statement
#
# Performance
# - MAYBE: allow opt-out of postcondition and class invariant checking
#
# Research: See ./doc/braindump.md
#
# Random/ideas:
# - Should contracts and their use be registered globally, for dependency tracking?
# Could allow tracking whether they are all set up statically or not
#
# References:
#
# - http://c2.com/cgi/wiki?DesignByContract
# - http://disnetdev.com/contracts.coffee/ custom syntax+compiler based on coffee-script
# - http://dlang.org/contracts.html built-in support for contracts in D

agree = {}

Promise = require 'bluebird'
introspection = require './introspection'
common = require './common'
agree.getContract = common.getContract

# Framework
class ContractFailed extends Error

# TODO: attach contract and failure info to the Error object
class PreconditionFailed extends ContractFailed
    constructor: (name, cond) ->
       @message = "#{name}: #{cond?.name}"

class PostconditionFailed extends ContractFailed
    constructor: (name, cond) ->
       @message = "#{name}: #{cond?.name}"

class ClassInvariantViolated extends ContractFailed
    constructor: (name, cond) ->
       @message = "#{name}: #{cond?.name}"

class NotImplemented extends Error
    constructor: () ->
        @message = 'Body function not implemented'

agree.ContractFailed = ContractFailed
agree.PostconditionFailed = PostconditionFailed
agree.ClassInvariantViolated = ClassInvariantViolated

runInvariants = (invariants, instance, args) ->
    return [] if not agree.getContract(instance)? # XXX: is this a programming error?
    results = []
    for invariant in invariants
        results.push
            error: invariant.check.apply instance
            invariant: invariant # TODO: remove, use condition instead
            condition: invariant
    return results

runConditions = (conditions, instance, args, retvals) ->
    results = []
    for cond in conditions
        target = if retvals? and cond.target != 'arguments' then retvals else args
        results.push
            error: cond.check.apply instance, target
            condition: cond
    return results

isPromise = (obj) ->
    p = typeof obj?.then == 'function'
    return p

class FunctionEvaluator
    constructor: (@bodyFunction, onError, @options) ->
        defaultFail = (instance, args, failures, stage) ->
            errors = failures.map (f) -> f.condition.name + ' ' + f.error.toString()
            msg = errors.join('\n')

            # FIXME: include standard, structured info with the Error objects
            if stage == 'preconditions'
                err = new PreconditionFailed msg
            else if stage == 'invariants-pre' or stage == 'invariants-post'
                err = new ClassInvariantViolated msg
            else if stage == 'postconditions'
                err = new PostconditionFailed msg
            else
                err = new Error "Agree.FunctionEvaluator: Unknown stage #{stage}"
            throw err

        @onError = if onError then onError else defaultFail
        # TODO: support callbacking with the error object instead of throwing
        # TODO: also pass invariant and post-condition failures through (user-overridable) function

    emit: (eventName, payload) ->
#        payload.context = undefined
#        console.log 'e', eventName, payload
        @observer eventName, payload if @observer
    observe: (eventHandler) ->
        @observer = eventHandler

    run: (instance, args, contract) ->
        instanceContract = agree.getContract instance
        invariants = if instanceContract? then instanceContract.invariants else []
        argsArray = Array.prototype.slice.call args

        preChecks = () =>
            # preconditions
            preconditions = if not @options.checkPrecond then [] else runConditions contract.preconditions, instance, args
            @emit 'preconditions-checked', preconditions
            prefailures = preconditions.filter (r) -> return r.error?
            if prefailures.length
                erret = @onError instance, args, prefailures, 'preconditions'
                return [true, errret]

            # invariants pre-check
            invs = if not @options.checkClassInvariants then [] else runInvariants invariants, instance, args
            @emit 'invariants-pre-checked', { invariants: invs, context: instance, arguments: argsArray }
            invprefailures = invs.filter (r) -> return r.error?
            if invprefailures.length
                errret = @onError instance, args, invprefailures, 'invariants-pre'
                return [true, errret]

            return [false, null]

        postChecks = (ret) =>
            # invariants post-check
            invs = if not @options.checkClassInvariants then [] else runInvariants invariants, instance, args
            @emit 'invariants-post-checked', { invariants: invs, context: instance, arguments: argsArray }
            invpostfailures = invs.filter (r) -> return r.error?
            if invpostfailures.length
                errret = @onError instance, args, invpostfailures, 'invariants-post'
                return [true, errret]

            # postconditions
            postconditions = if not @options.checkPostcond then [] else runConditions contract.postconditions, instance, args, [ret]
            @emit 'postconditions-checked', postconditions
            postfailures = postconditions.filter (r) -> return r.error?
            if postfailures.length
                errret = @onError instance, args, postfailures, 'postconditions'
                return [true, erret]

            return [false, null]

        # pre-checks
        [stop, checkErr] = preChecks()
        return if stop

        # function body
        @emit 'body-enter', { context: instance, arguments: argsArray }
        ret = @bodyFunction.apply instance, args
        @emit 'body-leave', { context: instance, arguments: argsArray, returns: ret }

        # post-checks
        if isPromise ret
            ret = ret.then (value) ->
                [stop, checkErr] = postChecks value
                if stop
                    return Promise.reject checkErr
                else
                    return Promise.resolve value
        else
            postChecks ret
        return ret
    

### Condition
# Can be used as precondition, postcondition or invariant in a FunctionContract or ClassContract
# The predicate function @check should return an Error object on failure, or null on pass
#
# Functions which returns a Condition, can be used to provide a family of parametric conditions
###
class Condition
    constructor: (@check, @name, @details) ->
        @name = 'unnamed condition' if not @name

agree.Condition = Condition

wrapFunc = (self, evaluator) ->
    return () ->
        instance = this
        evaluator.run instance, arguments, self

class FunctionContract
    constructor: (@name, @parent, @options = {}, @parentname) ->
        @name = 'anonymous function' if not @name
        @postconditions = []
        @preconditions = []
        @attributes = {}
        @examples = []
        @_agreeType = 'FunctionContract'

        defaultOptions =
            checkPrecond: true
            checkClassInvariants: true
            checkPostcond: true
        for k,v of defaultOptions
            @options[k] = v if not @options[k]?

    # implement this Contract in a external function
    implement: (original) ->
        evaluator = new FunctionEvaluator null, @onError, @options
        func = wrapFunc this, evaluator
        func._agreeContract = this # back-reference for introspection
        func._agreeEvaluator = evaluator # back-reference for introspection
        func.toString = () ->
            return introspection.describe this
        func._agreeEvaluator.bodyFunction = original
        func._agreeChain = original._agreeChain
        return func

    body: (func) ->
        f = @implement func
        if @parent and @parentname
            @parent.klass.prototype[@parentname] = f
        return this

    ## Fluent construction
    ensures: () -> @postcondition.apply @, arguments
    postcondition: (conditions, target) ->
        conditions = [conditions] if not conditions.length
        for c in conditions
            c = new Condition c, '' if typeof c == 'function' # inline predicate. TODO: allow name?
            c.target = target if target?
            @postconditions.push c
        return this

    requires: () -> @precondition.apply @, arguments
    precondition: (conditions) ->
        conditions = [conditions] if not conditions.length
        for c in conditions
            c = new Condition c, '' if typeof c == 'function' # inline predicate. TODO: allow name?
            @preconditions.push c
        return this

    attr: (key, val) ->
        @attributes[key] = val
        return this

    error: (onError) ->
        # FIXME: should only be for FunctionEvaluator?
        @onError = onError
        return this

    # TODO: Error if example does not pass pre and post-conditions
    successExample: (name, payload) ->
        type = payload._type if payload._type?
        type = 'function-call' if not type?
        @examples.push
            valid: true
            name: name
            payload: payload
            type: type
        return this

    # TODO: Error if example passes pre-conditions
    # XXX: Do we need another .type of failing examples, post-fail..
    # causes post-conditions to fail, but has valid input?
    failExample: (name, payload) ->
        type = payload._type if payload._type?
        type = 'function-call' if not type?
        @examples.push
            valid: false
            name: name
            payload: payload
            type: type
        return this


    # Chain up to parent to continue fluent flow there
    method: () ->
        return @parent.method.apply @parent, arguments if @parent

    # Up
    getClass: () ->
        return @parent?.getClass()

agree.FunctionContract = FunctionContract
agree.function = (name, parent, options, pname) ->
    return new FunctionContract name, parent, options, pname

# TODO: allow ClassContract to be used as interface
class ClassContract
    constructor: (@name, @options = {}) ->
        @name = 'anonymous class' if not @name
        @invariants = []
        @initializer = () ->
            # console.log 'ClassContract default initializer'
        @attributes = {}
        @_agreeType = 'ClassContract'

        self = this
        construct = (instance, args) =>
            @construct instance, args
        @klass = () ->
            this.toString = () -> return introspection.describe this
            this._agreeContract = self # back-reference for introspection
            construct this, arguments
        @klass._agreeContract = this # back-reference for introspection
        @klass.toString = () -> return introspection.describe this

        defaultOptions =
            checkPrecond: true
            checkClassInvariants: true
            checkPostcond: true
        for k, v of defaultOptions
            @options[k] = v if not @options[k]?

    # add a method
    method: (name, opts) ->
        f = agree.function "#{@name}.#{name}", this, opts, name
        return f

    # add constructor
    init: (f) ->
        @initializer = f
        return this

    # add class invariant
    invariant: (conditions) ->
        conditions = [conditions] if not conditions.length
        for c in conditions
            c = new Condition c, '' if typeof c == 'function' # inline predicate. TODO: allow description?
            @invariants.push c
        return this

    attr: (key, val) ->
        @attributes[key] = val
        return this

    # register ordinary constructor
    add: (context, name) ->
        name = @name if not name
        context[name] = @klass
        return this

    construct: (instance, args) ->
        @initializer.apply instance, args

        # Check class invariants
        # FIXME: share this code with FunctionContract.runInvariants
        if @options.checkClassInvariants
            for invariant in agree.getContract(instance)?.invariants
                error = invariant.check.apply instance
                throw new ClassInvariantViolated "Constructor violated invariant: #{error}" if error
        return instance

    getClass: ->
        return @klass

agree.ClassContract = ClassContract

agree.Class = (name) ->
    return new ClassContract name

# Patch Promise.then to be able to introspect the chain
originalThen = Promise.prototype.then
Promise.prototype.then = (fulfill, reject) ->
    newPromise = originalThen.apply this, [fulfill, reject]
    newPromise._agreeParentPromise = this
    return newPromise

# Export our Promise variant. For introspection or compat with old JS runtimes
agree.Promise = Promise

module.exports = agree
