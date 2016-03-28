
chai = require 'chai'
agree = require '../'
examples = require './examples'

Promise = agree.Promise
conditions = agree.conditions

isArrayCheck = (thing) ->
    return if Array.isArray(thing) then null else new Error "Argument '#{thing}' is not an Array"
conditions.isArray = new agree.Condition isArrayCheck, 'is array'

conditions.lengthAbove = (length) ->
  check = (array) ->
    pass = array.length > length
    #console.log 'above', length, pass, array
    return if pass then null else new Error "Array length #{array.length} is not > #{length}"
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

# TODO: figure out how to do this nicer. Problem with Promise is that:
# it starts executing immediately on .then(), which is also the mechanism which constructs chain
# it is single-use, keeping state of an execution
# The need to pass in an object which is then populated with props is also quite horrible API
deferred = (trigger) ->
  state =
    resolve: null
    reject: null
  p = new Promise (resolve, reject) ->
    state.resolve = resolve
    state.reject = reject
  trigger.resolve = (val) ->
    state.resolve val
  trigger.reject = (err) ->
    state.reject err
  return p

class PromiseChain
  constructor: (@name) ->
    @chain = []

  then: (thenable) ->
    @chain.push thenable
    return this

  _render: () ->
    trigger = {}
    promise = deferred trigger
    for thenable in @chain
      promise = promise.then thenable
    return [promise, trigger]

  promisify: () ->
    [promise, trigger] = @_render()
    return promise

  # returns Promise for the whole chain, pushes @value into the first one
  call: (val) ->
    [promise, trigger] = @_render()
    trigger.resolve val
    return promise

Chain = (name) ->
  return new PromiseChain name

passingChain = Chain 'passing'
  .then arrayOfNumbers
  .then arrayLength

failingChain = Chain 'fail'
  .then arrayOfNumbers
  .then firstItem

describe 'Static analysis of Promise chain', ->

  describe 'functions with compatible contracts', ->
    trigger = {}        

    it 'passes check', () ->
      promise = passingChain.promisify()
      res = agree.analyze.checkPromise promise
      res = res[0]
      fails = res.filter (r) -> return not r.valid
      chai.expect(fails).to.have.length 0
    it 'executing the function should return results', (done) ->
      promise = passingChain.call 3
      .then (val) ->
        chai.expect(val).to.equal 3
        done()

  describe 'functions with incompatible contracts', ->
    fails = []
    it 'fails static checking', () ->
      promise = failingChain.promisify()
      res = agree.analyze.checkPromise promise
      res = res[0]
      fails = res.filter (r) -> return not r.valid
      chai.expect(fails).to.have.length 1
    it.skip 'has helpful info on why', () ->
      chai.expect(fails[0].explanation).to.be.a 'string'
      # TODO: implement. Should be something like
      " value $FOO which may be returned by $SOURCE fails precondition $PRE of $TARGET"

    it 'function works with non-problematic input', (done) ->
      promise = failingChain.call 3
      .then (val) ->
        chai.expect(val).to.eql 0
        return done()
    it 'function fails with problematic input ', (done) ->
      promise = failingChain.call 0
      .then (val) ->
        return done new Error "function did not fail, instead sent #{val}"
      .catch (err) ->
        return done()



