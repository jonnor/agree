
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
        it 'has .toString() description'
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
        it 'has .toString() description'

    describe 'preconditions', ->
        contract = examples.multiplyByTwo.contract
        it 'can be enumerated', ->
            chai.expect(contract.preconditions).to.have.length 1
        it 'has description', ->
            chai.expect(contract.preconditions[0].predicate.description).to.equal 'no undefined arguments'

    describe 'postcondititions', ->
        contract = examples.multiplyByTwo.contract
        it 'can be enumerated', ->
            chai.expect(contract.postconditions).to.have.length 1
        it 'has description', ->
            chai.expect(contract.postconditions[0].description).to.equal 'all arguments must be numbers'

    describe 'class invariants', ->
        contract = examples.InvalidInit.contract
        it 'can be enumerated', ->
            chai.expect(contract.invariants).to.have.length 1
        it 'has description'

    # TODO: implement observation of pre/post/class-invariants
    # - run with some sort of Spy which records events

describe 'Spying', ->

    beforeEach () ->

    afterEach () ->

    # interesting to determine code coverage, failing tests if not 100% 
    # - not all preconditions hit -> insufficient unhappy cases
    # - postcondition not success -> insufficient happy cases, or buggy code/conditions
    describe 'all preconditions hit', ->
        it 'can be observed',


    describe 'not all preconditions hit', ->
        it 'can be observed'

    describe 'postcondition failing', ->
        it 'can be observed'

    describe 'postcondition never called', ->
        it 'can be observed'



