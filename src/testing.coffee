# Agree - Introspectable Contracts Programming for JavaScript
# * Copyright (c) 2016 Jon Nordby <jononor@gmail.com>
# * Agree may be freely distributed under the MIT license

## Testing
# - TODO: allow to attach examples to a Contract, both for failing cases, and for passing.
#   - should include the expected result information
#   - use this to automatically create test-cases
# - TODO: allow to verify all pre,post,classinvariants have been triggered
# - MAYBE: allow to go over all declared
# - MAYBE: allow to cause a contract used by a function to fail, to check error handling
# - MAYBE: do fuzz testing, to determine input conditions that pass precondition but fails postcond?
# - TODO: use fault injection, by removing body of each function in suite, and ensure that at least one test fails
# - TODO: if there are 0 tests found, print error and exit
# - FIXME: add some basic tests for testing tools...
# - MAYBE: add a structured output format
# - TODO: allow Agree users to trigger a self-test using an API
# - MAYBE: can we generate mock objects, or mock services (HTTP) from Agree data?
#    Can this be done from the contracts alone, such that one could publish this
#    as an open executable specification of interface, even if (canonical) implementation is propriatery?

common = require './common'

exports.testers = {} # Module state

findExampleTests = (module) ->
  tests = {}

  # FIXME: share module walking with documentation, by putting into ./introspection
  for n, thing of module
    contract = common.getContract thing
    continue if not contract

    examples = contract.examples

    tests[n] =
      name: contract.name
      thing: thing
      contract: contract
      examples: examples
  return tests

findExampleTypes = (tests) ->
  types = []

  for tn, test of tests
    for en, example of test.examples
      # TODO: have a default type, normalize example data to include it
      # TODO: provide a Tester for the default, which would be just executing the function
      type = example.payload?._type
      if type? and types.indexOf(type) == -1
        types.push type

  return types



runTests = (tester, type, tests, callback) ->
  t = tester
  #console.log 'ex', test.examples

  examples = []
  for n, atest of tests
    for en, example of atest.examples
      if example.payload?._type == type
        example.test = atest # backref
        examples.push example

  runExample = (ex, cb) ->
      #console.log 'run', test.name, ex.name
      test = ex.test
      t.run test.thing, test.contract, ex, (err, checks) ->
        #console.log 'ran', test.name, ex.name, err, checks
        results =
          test: test.name
          example: ex.name
          checks: checks
        cb err, results

  t.setup (err) ->
    return callback err if err
    #console.log 'setup done'
    common.asyncSeries examples, runExample, (err, results) ->
      t.teardown (terr) ->
        console.log 'teardown error', terr if terr
        return callback err, results

renderPlainText = (resultsarr) ->
  errors = []
  results = {}
  for item in resultsarr
    results[item.test] = {} if not results[item.test]?
    results[item.test][item.example] = item.checks.map (c) ->
      status = if c.error then c.error else 'PASS'
      errors.push c.error if c.error?
      return "#{c.name}: #{status}"

  lines = []
  ind = '  '
  for target, tests of results
    lines.push target
    for ex, res of tests
      lines.push "#{ind} #{ex}"
      for r in res
        lines.push "#{ind+ind} #{r}"
  str = lines.join '\n'
  return [str, errors]

exports.registerTester = (type, tester) ->
  exports.testers[type] = tester

exports.main = main = () ->
  path = require 'path'

  modulePath = process.argv[2]
  modulePath = path.resolve process.cwd(), modulePath
  try
    module = require modulePath
  catch e
    console.log e
    process.exit 1

  tests = findExampleTests module
  types = findExampleTypes tests 

  throw new Error "No tests types found: #{tests}" if not Object.keys(tests).length
  throw new Error "No test types found: #{types}" if not types.length

  throw new Error "Only one example type at a time is supported right now, found: #{types}" if types.length > 1  # FIXME: don't assume single test type
  type = types[0]
  tester = exports.testers[type]
  knownTypes = Object.keys exports.testers
  throw new Error "Could not find Tester for example type #{type}. Registered: #{knownTypes}" if not tester

  runTests tester, type, tests, (err, results) ->
    throw err if err

    [text, errors] = renderPlainText results
    console.log text

    if errors.length
      console.log "#{errors.length} tests failed"
      process.exit 2
    else
      process.exit 0

main() if not module.parent
