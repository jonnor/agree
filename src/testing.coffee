
# Testing
# - TODO: allow to attach examples to a Contract, both for failing cases, and for passing.
#   - should include the expected result information
#   - use this to automatically create test-cases
# - TODO: allow to verify all pre,post,classinvariants have been triggered
# - MAYBE: allow to go over all declared
# - MAYBE: allow to cause a contract used by a function to fail, to check error handling
# - MAYBE: do fuzz testing, to determine input conditions that pass precondition but fails postcond?

common = require './common'

findExampleTests = (module) ->
  tests = {}

  for n, thing of module
    contract = common.getContract thing
    continue if not contract

    tester = contract.attributes.tester
    examples = contract.examples
    continue if not tester # FIXME: provide default. Or get rid of concept 

    tests[n] =
      name: contract.name
      thing: thing
      tester: tester
      contract: contract
      examples: examples
  return tests

runTests = (tests, callback) ->
  # FIXME: don't assume single test/tester
  firstKey = Object.keys(tests)[0]
  test = tests[firstKey]
  
  t = test.tester
  #console.log 'ex', test.examples

  runExample = (ex, cb) ->
      #console.log 'run', test.name, ex.name
      t.run test.thing, test.contract, ex, (err, checks) ->
        #console.log 'ran', test.name, ex.name, err, results
        results =
          test: test.name
          example: ex.name
          checks: checks
        cb err, results

  t.setup (err) ->
    return callback err if err
    #console.log 'setup done'
    common.asyncSeries test.examples, runExample, (err, results) ->
      t.teardown (terr) ->
        console.log 'teardown error', terr if terr
        return callback err, results

exports.main = main = () ->
  path = require 'path'

  modulePath = process.argv[2]
  modulePath = path.resolve process.cwd(), modulePath
  try
    module = require modulePath
  catch e
    console.log e

  tests = findExampleTests module
  runTests tests, (err, resultsarr) ->
    throw err if err

    errors = []
    results = {}
    for item in resultsarr
      results[item.test] = {} if not results[item.test]?
      results[item.test][item.example] = item.checks.map (c) ->
        status = if c.error then c.error else 'PASS'
        errors.push c.error if c.error?
        return "#{c.name}: #{status}"

    ind = '  '
    for target, tests of results
      console.log target
      for ex, res of tests
        console.log ind, ex
        for r in res
          console.log ind+ind, r

    if errors.length
      console.log "#{errors.length} tests failed"
      process.exit 2
    else
      process.exit 0

main() if not module.parent
