# Contracts allows specifying pre/post-conditions, class invariants on function, methods and classes.
#
# Contracts core
# FIXME: pre/postconditions should be proper objects
#    - in the chainable API, should be
#    - see TODO in ./conditions.coffee
# FIXME: add default error/precondfail reporting.
#    - .error 'throws' | 'callback' | 'return' ?
# TODO: add first-class support for Promises, wrapper for node.js type async callbacks
#
# API
#
# - functions and classes/objects have-a (set of) contract(s)
# - contracts should be declarable as an entity, and then later, associated with zero or more functions/classes
# - as a convenience, should be possible to declare the contract for function/class 'inline'
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
# Documentation
# - TODO: allow to generate HTML API docs; including pre,post,classinvariants
#
# Testing
# - TODO: allow to attach examples to a Contract, both for failing cases, and for passing.
#   - should include the expected result information
#   - use this to automatically create test-cases
# - TODO: allow to verify all pre,post,classinvariants have been triggered
# - MAYBE: allow to go over all declared
# - MAYBE: allow to cause a contract used by a function to fail, to check error handling
# - MAYBE: do fuzz testing, to determine input conditions that pass precondition but fails postcond?
#
# Debugging
# - TODO: ability to log failing predicates, including description, location of fail, reason for fail
# - TODO: ability to cause failing predicate to cause breakpoint using `debugger` statement
#
# Performance
# - MAYBE: allow opt-out of postcondition and class invariant checking
#
# Research:
# - Investigate how unit tests can be generated from introspected
# invariants, or how checks can replace unit tests for simple cases
# - Investigate to which extent invariants can be statically checked,
# prototype reasoning about some simple cases.
# http://coffeescript.org/documentation/docs/nodes.html
# http://www.coffeelint.org/
# https://github.com/jashkenas/coffeescript/issues/1466
# - investigate composition of contracts through Promises,
# can we reason about the chain of promises / sub-promises?
# - investigate using a set of contract interface as an executable coding style
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
            passed: invariant.apply instance
            invariant: invariant
    return results

runConditions = (conditions, instance, args) ->
    results = []
    for cond in conditions
        results.push
            passed: cond.predicate.apply instance, args
            condition: cond
    return results

class FunctionEvaluator
    constructor: (@bodyFunction, @options) ->
        null

    emit: (eventName, payload) ->
        @observer eventName, payload if @observer
    observe: (eventHandler) ->
        @observer = eventHandler

    run: (instance, args, contract) ->
        instanceContract = agree.getContract instance
        invariants = if instanceContract? then instanceContract.invariants else []
        argsArray = Array.prototype.slice.call args

        # preconditions
        preconditions = if not @options.checkPrecond then [] else runConditions contract.preconditions, instance, args
        @emit 'preconditions-checked', preconditions
        failures = preconditions.filter (r) -> return not r.passed
        return failures[0].condition.onFail() if failures.length

        # invariants pre-check
        invs = if not @options.checkClassInvariants then [] else runInvariants invariants, instance, args
        @emit 'invariants-pre-checked', { invariants: invs, context: instance, arguments: argsArray }
        failures = invs.filter (r) -> return not r.passed
        throw new ClassInvariantViolated contract.name, failures[0].invariant if failures.length

        # function body
        @emit 'body-enter', { context: instance, arguments: argsArray }
        ret = @bodyFunction.apply instance, args
        @emit 'body-leave', { context: instance, arguments: argsArray, returns: ret }

        # invariants post-check
        invs = if not @options.checkClassInvariants then [] else runInvariants invariants, instance, args
        @emit 'invariants-post-checked', { invariants: invs, context: instance, arguments: argsArray }
        failures = invs.filter (r) -> return not r.passed
        throw new ClassInvariantViolated contract.name, failures[0].invariant if failures.length

        # postconditions
        postconditions = if not @options.checkPostcond then [] else runConditions contract.postconditions, instance, [ret]
        @emit 'postconditions-checked', postconditions
        failures = postconditions.filter (r) -> return not r.passed
        throw new PostconditionFailed @name, failures[0].condition if failures.length

        # success
        return ret
    

wrapFunc = (self, evaluator) ->
    return () ->
        instance = this
        evaluator.run instance, arguments, self

class FunctionContract
    constructor: (@name, @parent, @options = {}, @parentname) ->
        @name = 'anonymous function' if not @name
        @postconditions = []
        @preconditions = []

        defaultOptions =
            checkPrecond: true
            checkClassInvariants: true
            checkPostcond: true
        for k,v of defaultOptions
            @options[k] = v if not @options[k]?

    # attach this Contract to an external function
    attach: (original) ->
        evaluator = new FunctionEvaluator null, @options
        func = wrapFunc this, evaluator
        func._agreeContract = this # back-reference for introspection
        func._agreeEvaluator = evaluator # back-reference for introspection
        func.toString = () ->
            return introspection.describe this
        func._agreeEvaluator.bodyFunction = original
        return func

    body: (func) ->
        f = @attach func
        if @parent and @parentname
            @parent.klass.prototype[@parentname] = f
        return this

    ## Fluent construction
    post: () -> @postcondition.apply @, arguments
    postcondition: (conditions) ->
        conditions = [conditions] if not conditions.length
        for c in conditions
            o = { predicate: c }
            @postconditions.push o
        return this

    pre: () -> @precondition.apply @, arguments
    precondition: (conditions, onFail) ->
        conditions = [conditions] if not conditions.length
        for c in conditions
            defaultFail = () ->
                throw new PreconditionFailed @name, c
            o = { predicate: c }
            o.onFail = if onFail then onFail else defaultFail
            @preconditions.push o
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
    constructor: (@name, @options) ->
        @name = 'anonymous class' if not @name
        @invariants = []
        @initializer = () ->
            # console.log 'ClassContract default initializer'

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
        for cond in conditions
            @invariants.push cond
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
                throw new ClassInvariantViolated if not invariant.apply instance
        return instance

    getClass: ->
        return @klass

agree.ClassContract = ClassContract

agree.Class = (name) ->
    return new ClassContract name

module.exports = agree
