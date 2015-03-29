
chai = require 'chai'
agree = require '../'
examples = require './examples'

describe 'Introspection', ->

    describe 'a function', () ->
        it 'knows its Contract', ->
            chai.expect(examples.multiplyByTwo.contract).to.be.instanceof agree.FunctionContract
        it 'has a name', ->
            chai.expect(examples.multiplyByTwo.contract.name).to.equal 'multiplyByTwo'
    describe 'a method', () ->
        instance = new examples.Initable
        it 'knows its Contract', ->
            chai.expect(instance.dontcallme.contract).to.be.instanceof agree.FunctionContract
        it 'has a name', ->
            chai.expect(instance.dontcallme.contract.name).to.equal 'Initable.dontcallme'
        it 'knows the Contract of its class', ->
            chai.expect(instance.dontcallme.contract.parent).to.be.instanceof agree.ClassContract
            chai.expect(instance.dontcallme.contract.parent.name).to.equal 'Initable'
    describe 'a class', () ->
        it 'knows its Contract', ->
            chai.expect(examples.InvalidInit.contract).to.be.instanceof agree.ClassContract
        it 'has a name', ->
            chai.expect(examples.InvalidInit.contract.name).to.equal 'InvalidInit'
    describe 'a class instance', ->
        it 'knows its Contract', ->
            instance = new examples.Initable
            chai.expect(instance.contract).to.be.instanceof agree.ClassContract

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

    # TODO: list pre/post/invariants, execute functions, compare how many ran/failed to available
    describe 'postcondition failing', ->
    describe 'postcondition never called', ->


