
chai = require 'chai'
agree = require '../'
examples = require './examples'

describe 'Introspection', ->

    describe 'a function', () ->
        contract = agree.getContract examples.multiplyByTwo
        it 'knows its Contract', ->
            chai.expect(contract).to.be.instanceof agree.FunctionContract
        it 'has a name', ->
            chai.expect(contract.name).to.equal 'multiplyByTwo'
        it 'has .toString() description', ->
            desc = examples.multiplyByTwo.toString()
            chai.expect(desc).to.contain 'multiplyByTwo'
            chai.expect(desc).to.contain 'no undefined'
            chai.expect(desc).to.contain 'must be numbers'
            chai.expect(desc).to.contain 'body'
            chai.expect(desc).to.contain 'function'
    describe 'a method', () ->
        instance = new examples.Initable
        contract = agree.getContract instance.dontcallme
        it 'knows its Contract', ->
            chai.expect(contract).to.be.instanceof agree.FunctionContract
        it 'has a name', ->
            chai.expect(contract.name).to.equal 'Initable.dontcallme'
        it 'knows the Contract of its class', ->
            chai.expect(contract.parent).to.be.instanceof agree.ClassContract
            chai.expect(contract.parent.name).to.equal 'Initable'
        it 'has .toString() description', ->
            desc = agree.introspection.describe instance.dontcallme
            chai.expect(desc).to.contain 'method'
            chai.expect(desc).to.contain 'dontcallme'
            chai.expect(desc).to.contain 'Initable'
            chai.expect(desc).to.contain 'body'
    describe 'a class', () ->
        contract = agree.getContract examples.InvalidInit
        it 'knows its Contract', ->
            chai.expect(contract).to.be.instanceof agree.ClassContract
        it 'has a name', ->
            chai.expect(contract.name).to.equal 'InvalidInit'
        it 'has .toString() description', ->
            desc = examples.Initable.toString()
            chai.expect(desc).to.contain 'class'
            chai.expect(desc).to.contain 'Initable'
            chai.expect(desc).to.contain 'method'
            chai.expect(desc).to.contain 'Initable.dontcallme'
    describe 'a class instance', ->
        it 'knows its Contract', ->
            instance = new examples.Initable
            contract = agree.getContract instance
            chai.expect(contract).to.be.instanceof agree.ClassContract
        it 'has .toString() description', ->
            instance = new examples.Initable
            desc = instance.toString()
            chai.expect(desc).to.contain 'instance'
            chai.expect(desc).to.contain 'Initable'
            chai.expect(desc).to.contain 'method'
            chai.expect(desc).to.contain 'Initable.dontcallme'
    describe 'preconditions', ->
        contract = agree.getContract examples.multiplyByTwo
        it 'can be enumerated', ->
            chai.expect(contract.preconditions).to.have.length 2
        it 'has description', ->
            chai.expect(contract.preconditions[0].name).to.equal 'no undefined arguments'

    describe 'postcondititions', ->
        contract = agree.getContract examples.multiplyByTwo
        it 'can be enumerated', ->
            chai.expect(contract.postconditions).to.have.length 1
        it 'has description', ->
            chai.expect(contract.postconditions[0].name).to.equal 'all arguments must be numbers'

    describe 'class invariants', ->
        contract = agree.getContract examples.InvalidInit
        it 'can be enumerated', ->
            chai.expect(contract.invariants).to.have.length 1
        it 'has description', ->
            chai.expect(contract.invariants[0].name).to.equal 'prop1 must not be null'


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
            failing = events[0].data.filter (c) -> return c.error != null
            chai.expect(failing).to.be.length 1
            chai.expect(failing[0].condition.name).to.equal "all arguments must be numbers"
        it 'can get passing precondition', ->
            events = observer.events.filter (e) -> return e.name == 'preconditions-checked'
            passing = events[0].data.filter (c) -> return c.error == null
            chai.expect(passing).to.be.length 1
            chai.expect(passing[0].condition.name).to.equal "no undefined arguments"

    describe 'postcondition failing', ->
        it 'can be observed'

    describe 'postcondition never called', ->
        it 'can be observed'



