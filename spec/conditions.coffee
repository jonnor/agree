
agree = require '../'
chai = require 'chai'

describe 'Conditions', ->

  # Data-driven test based on introspecting the examples
  Object.keys(agree.conditions).forEach (name) ->
    condition = agree.conditions[name]

    describe "#{name}", ->
      return it.skip('missing examples', () ->) if not condition.examples?.length

      condition.examples.forEach (example) ->
          describe "#{example.name}", ->
            testcase = if example.valid then 'should pass' else 'should fail'
            it testcase, ->
              cond = example.create()
              pass = cond.apply example.context(), example.args
              chai.expect(pass).to.equal example.valid
            
