
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
      t.run test.thing, test.contract, ex, (err, results) ->
        #console.log 'ran', test.name, ex.name, err, results
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
  runTests tests, (err, results) ->
    throw err if err
    errors = []
    ran = []
    for outer in results
      for r in outer
        ran.push r
        errors.push r if r.error?

    console.log "Ran #{ran.length} tests"
    if errors.length
      console.log "#{errors.length} tests failed:\n", (errors.map (e) -> "#{e.name}: #{e.error}").join('\n')
      process.exit 2
    else
      process.exit 0

main() if not module.parent
