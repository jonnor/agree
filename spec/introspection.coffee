
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

    describe 'calling function with valid data', ->
        it 'causes body-enter and body-leave event', ->
            func 42
            names = observer.events.map (e) -> return e.name
            chai.expect(names).to.include 'body-enter'
            chai.expect(names).to.include 'body-leave'
        it 'body-enter event has function arguments', ->
            func 42
            events = observer.events.filter (e) -> return e.name == 'body-enter'
            chai.expect(events).to.have.length 1
            chai.expect(events[0].data.arguments).to.eql [42], events[0]

        it 'body-leave event has function return values'
        it 'Observer.toString() has description of events'

    describe 'not all preconditions hit', ->
        it 'failed precondition is marked'
        it 'passing precondition is marked'

    describe 'all preconditions hit', ->
        it 'can be observed'

    describe 'postcondition failing', ->
        it 'can be observed'

    describe 'postcondition never called', ->
        it 'can be observed'



