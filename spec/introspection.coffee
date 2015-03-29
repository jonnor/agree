
chai = require 'chai'
agree = require '../'
examples = require './examples'

describe 'Introspection', ->

    describe 'a function', () ->
        it 'knows its Contract', ->
            chai.expect(examples.multiplyByTwo.contract).to.be.instanceof agree.FunctionContract
        it 'has a name', ->
            chai.expect(examples.multiplyByTwo.contract.name).to.equal 'multiplyByTwo'
        it 'has .toString() description', ->
            desc = examples.multiplyByTwo.toString()
            chai.expect(desc).to.contain 'multiplyByTwo'
            chai.expect(desc).to.contain 'no undefined'
            chai.expect(desc).to.contain 'must be numbers'
            chai.expect(desc).to.contain 'body'
            chai.expect(desc).to.contain 'function'
    describe 'a method', () ->
        instance = new examples.Initable
        it 'knows its Contract', ->
            chai.expect(instance.dontcallme.contract).to.be.instanceof agree.FunctionContract
        it 'has a name', ->
            chai.expect(instance.dontcallme.contract.name).to.equal 'Initable.dontcallme'
        it 'knows the Contract of its class', ->
            chai.expect(instance.dontcallme.contract.parent).to.be.instanceof agree.ClassContract
            chai.expect(instance.dontcallme.contract.parent.name).to.equal 'Initable'
        it 'has .toString() description', ->
            desc = agree.introspection.describe instance.dontcallme
            chai.expect(desc).to.contain 'method'
            chai.expect(desc).to.contain 'dontcallme'
            chai.expect(desc).to.contain 'Initable'
            chai.expect(desc).to.contain 'body'
    describe 'a class', () ->
        it 'knows its Contract', ->
            chai.expect(examples.InvalidInit.contract).to.be.instanceof agree.ClassContract
        it 'has a name', ->
            chai.expect(examples.InvalidInit.contract.name).to.equal 'InvalidInit'
        it 'has .toString() description', ->
            desc = examples.Initable.toString()
            chai.expect(desc).to.contain 'class'
            chai.expect(desc).to.contain 'Initable'
            chai.expect(desc).to.contain 'method'
            chai.expect(desc).to.contain 'Initable.dontcallme'
    describe 'a class instance', ->
        it 'knows its Contract', ->
            instance = new examples.Initable
            chai.expect(instance.contract).to.be.instanceof agree.ClassContract
        it 'has .toString() description', ->
            instance = new examples.Initable
            desc = instance.toString()
            chai.expect(desc).to.contain 'instance'
            chai.expect(desc).to.contain 'Initable'
            chai.expect(desc).to.contain 'method'
            chai.expect(desc).to.contain 'Initable.dontcallme'
    describe 'preconditions', ->
        contract = examples.multiplyByTwo.contract
        it 'can be enumerated', ->
            chai.expect(contract.preconditions).to.have.length 2
        it 'has description', ->
            chai.expect(contract.preconditions[0].predicate.description).to.equal 'no undefined arguments'

    describe 'postcondititions', ->
        contract = examples.multiplyByTwo.contract
        it 'can be enumerated', ->
            chai.expect(contract.postconditions).to.have.length 1
        it 'has description', ->
            chai.expect(contract.postconditions[0].predicate.description).to.equal 'all arguments must be numbers'

    describe 'class invariants', ->
        contract = examples.InvalidInit.contract
        it 'can be enumerated', ->
            chai.expect(contract.invariants).to.have.length 1
        it 'has description'


describe 'Observing a function', ->
    observer = null
    func = examples.multiplyByTwo
    beforeEach () ->
        observer = agree.introspection.observe func
    afterEach () ->
        observer.reset()

    describe 'all preconditions fulfilled', ->
        beforeEach () ->
            func 42
        it 'causes body-enter and body-leave event', ->
            names = observer.events.map (e) -> return e.name
            chai.expect(names).to.include 'body-enter'
            chai.expect(names).to.include 'body-leave'
        it 'body-enter event has function arguments', ->
            events = observer.events.filter (e) -> return e.name == 'body-enter'
            chai.expect(events).to.have.length 1
            chai.expect(events[0].data.arguments).to.eql [42], events[0]
        it 'body-leave event has function return values', ->
            events = observer.events.filter (e) -> return e.name == 'body-leave'
            chai.expect(events).to.have.length 1
            chai.expect(events[0].data.returns).to.eql 84
        it 'Observer.toString() has description of events', ->
            desc = observer.toString()
            chai.expect(desc).to.contain 'body-enter'
            chai.expect(desc).to.contain 'body-leave'
            chai.expect(desc).to.contain 'preconditions-checked'
            chai.expect(desc).to.contain 'postconditions-checked'

    describe 'some preconditions failing', ->
        beforeEach () ->
            try
                func "notnumber"
            catch e
                # ignored, observing it
        it 'can get failed precondition', ->
            events = observer.events.filter (e) -> return e.name == 'preconditions-checked'
            failing = events[0].data.filter (c) -> return c.passed == false
            chai.expect(failing).to.be.length 1
            chai.expect(failing[0].condition.predicate.description).to.equal "all arguments must be numbers"
        it 'can get passing precondition', ->
            events = observer.events.filter (e) -> return e.name == 'preconditions-checked'
            passing = events[0].data.filter (c) -> return c.passed == true
            chai.expect(passing).to.be.length 1
            chai.expect(passing[0].condition.predicate.description).to.equal "no undefined arguments"

    describe 'postcondition failing', ->
        it 'can be observed'

    describe 'postcondition never called', ->
        it 'can be observed'



