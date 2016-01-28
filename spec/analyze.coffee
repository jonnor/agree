
chai = require 'chai'
agree = require '../'
examples = require './examples'

conditions = agree.conditions

conditions.isArray = new agree.Condition (thing) ->
    return if Array.isArray(thing) then null else new Error "Argument '#{thing}' is not an Array"
  , 'is array'

conditions.lengthAbove = (length) ->
  check = (array) ->
    return new Error "Array length #{array.length} is not > #{length}" if not array.length
  return new agree.Condition check, "Array has length > #{length}"

arrayOfNumbers = new agree.FunctionContract 'returnsArray'
  .ensures conditions.isArray
  .successExample '3 items',
    arguments: 3
    returns: [1, 2, 3]
  .successExample 'empty array',
    arguments: 0
    returns: []
  .implement (length) ->
    a = []
    for i in [0...length]
      a.push i
    return Promise.resolve a

arrayLength = new agree.FunctionContract 'takesArray'
  .requires conditions.isArray
  .implement (a) ->
    return Promise.resolve a.length

firstItem = new agree.FunctionContract 'takesNonZeroArray'
  .requires conditions.isArray
  .requires conditions.lengthAbove 0
  .implement (a) ->
    return Promise.resolve a[0]


describe 'Static analysis of Promise chain', ->
  f = null

  # FIXME: introspect functions/contracts from the Promise chain itself
  describe 'functions with compatible signatures', ->
    it 'passes check', () ->
      arrayOfNumbers 3
      .then arrayLength
      .then (val) ->
        chai.expect(val).to.equal 3

      res = agree.analyze.checkPairs arrayOfNumbers, arrayLength
      fails = res.filter (r) -> return not r.valid
      chai.expect(fails).to.have.length 0

  describe 'functions with incompatible signatures', ->
    fails = []
    it 'fails check', ->
      res = agree.analyze.checkPairs arrayOfNumbers, firstItem
      fails = res.filter (r) -> return not r.valid
      chai.expect(fails).to.have.length 1
    it 'has helpful info on why'



