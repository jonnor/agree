chai = require 'chai'
agree = require '../'
examples = require './examples'

conditions = agree.conditions

# TODO: find way to avoid having to duplicate name when assigning. agree.export
# TODO: allow to have separate name on function as contract
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


.method 'setPropCorrect'
.pre conditions.noUndefined
.post [conditions.attributeEquals 'prop1', 'bar']
.body () ->
    @prop1 = 'bar'

.method 'setPropWrong'
.precondition conditions.noUndefined
.postcondition [conditions.attributeEquals 'prop1', 'bar']
.body () ->
    @prop1 = 'nobar'

describe 'FunctionContract', ->
    f = null
    beforeEach (done) ->
        try 
            f = new examples.Foo
        catch e
            null
        done e

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

    describe 'as reused interface', ->
        c = agree.function 'shared contract'
          .postcondition conditions.noUndefined
        it 'function not obeying contract should fail', ->
            fail = c.attach () -> return undefined
            chai.expect(() -> fail true).to.throw agree.PostconditionFailed
        it 'function obeying contract should pass', ->
            pass = c.attach () -> return true
            chai.expect(() -> pass true).to.not.throw

describe 'precondition failure callbacks', ->
    c = null
    onError = null
    PreconditionCallbacks = agree.Class 'PreconditionCallbacks'
    .method 'callMe'
    .precondition(conditions.noUndefined)
    .precondition(conditions.numbersOnly)
    .error () ->
        onError()
    .body (f) ->
        chai.expect(false).to.equal true, 'body called'
    .getClass()
    beforeEach () ->
        c = new PreconditionCallbacks
    it 'failing first precondition should call error callback once', (done) ->
        onError = done
        c.callMe undefined
    it 'failing second precondition should call error callback once', (done) ->
        onError = done
        c.callMe "a string"

describe 'ClassContract', ->
    f = null
    beforeEach ->
        f = new examples.Foo

    it 'initializer shall be called', ->
        chai.expect(f.prop1).to.equal "foo"
    it 'initializer violating class invariant should throw', ->
        chai.expect(() -> new examples.InvalidInit).to.throw agree.ClassInvariantViolated
    it 'method violating class invariant should throw', ->
        chai.expect(() -> f.setPropNull 2, 3).to.throw agree.ClassInvariantViolated

