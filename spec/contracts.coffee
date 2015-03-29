chai = require 'chai'
agree = require '../'
examples = require './examples'

conditions = agree.conditions

agree.Class 'Foo'
.add examples
.init () ->
    @prop1 = "foo"
    @numberProp = 1
.invariant conditions.neverNull 'prop1'
.invariant conditions.attributeTypeEquals 'numberProp', 'number'

.method 'setNumberWrong'
.precondition conditions.noUndefined
.postcondition [conditions.attributeEquals 'prop1', 'bar']
.body (arg1, arg2) ->
    @prop1 = null

.method 'setPropNull'
.precondition conditions.noUndefined
.body (arg1, arg2) ->
    @prop1 = null

.method 'addNumbers'
.precondition conditions.noUndefined
.body (arg1, arg2) ->
    return arg1+arg2

# TODO: allow to reuse/name the contract, and use different body/name
agree.function 'setPropCorrect'
.add examples.Foo.prototype
.pre conditions.noUndefined
.post [conditions.attributeEquals 'prop1', 'bar']
.body () ->
    @prop1 = 'bar'

agree.function 'setPropWrong'
.add examples.Foo.prototype
.precondition conditions.noUndefined
.postcondition [conditions.attributeEquals 'prop1', 'bar']
.body () ->
    @prop1 = 'nobar'

describe 'FunctionContract', ->
    f = null
    beforeEach ->
        f = new examples.Foo

    it 'function with valid arguments should succeed', ->
        chai.expect(examples.multiplyByTwo 13).to.equal 26
    it 'function with failing precondition should throw', ->
        chai.expect(() -> examples.multiplyByTwo undefined).to.throw agree.PreconditionFailed
    it 'method with valid arguments should succeed', ->
        chai.expect(f.addNumbers(1, 2)).to.equal 3
    it 'method with failing precondition should throw', ->
        cons = () ->
            f.addNumbers undefined, 0
        chai.expect(cons).to.throw agree.PreconditionFailed
    it 'method violating postcondition should throw', ->
        chai.expect(() -> f.setPropWrong 1).to.throw agree.PostconditionFailed
    it 'method not violating postcondition should succeed', ->
        chai.expect(f.setPropCorrect()).to.equal "bar"

describe 'precondition failure callbacks', ->
    c = null
    onUndefined = null
    onNonNumber = null
    PreconditionCallbacks = agree.Class 'PreconditionCallbacks'
    .method 'callMe'
    .precondition(conditions.noUndefined, () -> onUndefined())
    .precondition(conditions.numbersOnly, () -> onNonNumber())
    .body (f) ->
        chai.expect(false).to.equal true, 'body called'
    .getClass()
    beforeEach () ->
        c = new PreconditionCallbacks
    it 'failing first precondition should call only first callback', (done) ->
        onNonNumber = () -> chai.expect(false).to.equal true, 'onNonNumber called'
        onUndefined = done
        c.callMe undefined
    it 'failing second precondition should call only second callback', (done) ->
        onUndefined = () -> chai.expect(false).to.equal true, 'onUndefined called'
        onNonNumber = done
        c.callMe "a string"

describe 'ClassContract', ->
    f = null
    beforeEach ->
        f = new examples.Foo

    it 'initializer shall be called', ->
        chai.expect(f.prop1).to.equal "foo"
    it 'initializer violating class invariant should throw', ->
        chai.expect(examples.InvalidInit).to.throw agree.ClassInvariantViolated
    it 'method violating class invariant should throw', ->
        chai.expect(() -> f.setPropNull 2, 3).to.throw agree.ClassInvariantViolated

