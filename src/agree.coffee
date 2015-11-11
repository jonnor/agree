# Contracts allows specifying pre/post-conditions, class invariants on function, methods and classes.
#
# Contracts
# TODO: allow pre/postconditions on init/constructor functions
# TODO: allow to declare properties, and invariants on them, using ES5 Object.defineProperty
# https://developer.mozilla.org/de/docs/Web/JavaScript/Reference/Global_Objects/Object/defineProperty
# TODO: a way to declare an interface (pre,post,invar) which can be implemented by multiple function/classes
# TODO: allow/encourage to attach failing and passing examples to contract, use for tests of the contract/predicate itself
# TODO: allow to use a set of contract interface as an executable coding style
# TODO: add first-class support for Promises, wrapper for node.js type async callbacks
# TODO: A way to declare and verify symmetrical functions, ie ones which cancel eachother out
# requires to defined equality operators, over some context/domain?
# example: increment()/decrement(), init()/reset(), push()/pop()
# MAYBE: allow to 'inherit' when replacing a function, on object or prototype
#
# Documentation
# - TODO: allow to generate HTML API docs; including pre,post,classinvariants
#
# Testing
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
#
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
    return [] if not instance.contract? # XXX: is this a programming error?
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

# FIXME: namespace the .contract backref, should be something like _agreeContract, to avoid collisions
class FunctionContract
    constructor: (@name, @parent, @options) ->
        @name = 'anonymous function' if not @name
        @postconditions = []
        @preconditions = []
        @bodyFunction = () ->
            throw new NotImplemented
        @observer = null

        call = (instance, args) =>
            @call instance, args
        @func = () ->
            call this, arguments
        @func.contract = this # back-reference for introspection
        @func.toString = () -> return introspection.describe this

        defaultOptions =
            checkPrecond: true
            checkClassInvariants: true
            checkPostcond: true
        @options = defaultOptions # FIXME: don't override

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

    body: (f) ->
        @bodyFunction = f
        return this

    # Chain up to parent to continue fluent flow there
    method: () ->
        return @parent.method.apply @parent, arguments if @parent

    # Register as ordinary function on
    add: (context, name) ->
        name = @name if not name?
        context[name] = @func
        return this

    # Converting to normal function
    getClass: () ->
        return @parent?.getClass()

    getFunction: () ->
        return @func

    # Executing
    call: (instance, args) ->
        invariants = if instance.contract? then instance.contract.invariants else []
        argsArray = Array.prototype.slice.call args

        # preconditions
        preconditions = if not @options.checkPrecond then [] else runConditions @preconditions, instance, args
        @emit 'preconditions-checked', preconditions
        failures = preconditions.filter (r) -> return not r.passed
        return failures[0].condition.onFail() if failures.length

        # invariants pre-check
        invs = if not @options.checkClassInvariants then [] else runInvariants invariants, instance, args
        @emit 'invariants-pre-checked', { invariants: invs, context: instance, arguments: argsArray }
        failures = invs.filter (r) -> return not r.passed        
        throw new ClassInvariantViolated @name, failures[0].invariant if failures.length

        # body
        @emit 'body-enter', { context: instance, arguments: argsArray }
        ret = @bodyFunction.apply instance, args
        @emit 'body-leave', { context: instance, arguments: argsArray, returns: ret }

        # invariants post-check
        invs = if not @options.checkClassInvariants then [] else runInvariants invariants, instance, args
        @emit 'invariants-post-checked', { invariants: invs, context: instance, arguments: argsArray }
        failures = invs.filter (r) -> return not r.passed        
        throw new ClassInvariantViolated @name, failures[0].invariant if failures.length

        # postconditions
        # FIXME: pass ret and not args to postconditions!!!
        postconditions = if not @options.checkPostcond then [] else runConditions @postconditions, instance, args
        @emit 'postconditions-checked', postconditions
        failures = postconditions.filter (r) -> return not r.passed
        throw new PostconditionFailed @name, failures[0].condition if failures.length

        return ret

    # Observing events
    observe: (eventHandler) ->
        @observer = eventHandler

    emit: (eventName, payload) ->
        @observer eventName, payload if @observer

agree.FunctionContract = FunctionContract
agree.function = (name, parent, options) ->
    return new FunctionContract name, parent, options

class ClassContract
    constructor: (@name, @options) ->
        @name = 'anonymous class' if not @name
        @invariants = []
        @initializer = () ->
            # console.log 'ClassContract default initializer'
        @observer = null

        self = this
        construct = (instance, args) =>
            @construct instance, args
        @klass = () ->
            this.toString = () -> return introspection.describe this
            this.contract = self # back-reference for introspection
            construct this, arguments
        @klass.contract = this # back-reference for introspection
        @klass.toString = () -> return introspection.describe this

        defaultOptions =
            checkPrecond: true
            checkClassInvariants: true
            checkPostcond: true
        @options = defaultOptions # FIXME: don't override

    # add a method
    method: (name) ->
        f = agree.function "#{@name}.#{name}", this
        return f.add @klass.prototype, name

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
            for invariant in instance.contract?.invariants
                throw new ClassInvariantViolated if not invariant.apply instance
        return instance

    # Observing events
    observe: (eventHandler) ->
        @observer = eventHandler

    getClass: ->
        return @klass

agree.ClassContract = ClassContract

agree.Class = (name) ->
    return new ClassContract name

module.exports = agree

