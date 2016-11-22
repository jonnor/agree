
agree = require '../' if not agree
chai = require 'chai' if not chai

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
              error = cond.check.apply example.context(), example.args
              pass = not error?
              chai.expect(pass).to.equal example.valid
            
