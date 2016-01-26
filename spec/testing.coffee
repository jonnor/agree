
chai = require 'chai'
agree = require '../'

projectPath = (p) ->
  path = require 'path'
  return path.join __dirname, '..', p

agreeTest = (modulePath, callback) ->
  child_process = require 'child_process'
  prog = projectPath "./bin/agree-test"
  args = [
    modulePath
  ]
  options = {}
  child_process.execFile prog, args, options, callback

findPasses = (str) ->
  return str.match /^.*: PASS$/mg
findFails = (str) ->
  m = str.match /^.*: Error:.*$/mg
  m = [] if not m?
  return m

describe 'agree-test', ->

  describe 'on HTTP server example', ->
    example = projectPath 'examples/httpserver.coffee'
    stdout = ""
    stderr = ""

    describe 'when passing all tests', ->

      it 'exitcode is 0', (done) ->
        agreeTest example, (err, sout, serr) ->
          stdout = sout
          stderr = serr
          chai.expect(err).to.not.exist
          return done err
      it 'stdout includes passing tests', () ->
        chai.expect(stdout).to.contain 'GET /somedata'
        passes = findPasses(stdout)
        chai.expect(passes).to.have.length 2
      it 'stdout has no failing tests', () ->
        fails = findFails(stdout)
        chai.expect(fails, fails).to.have.length 0

    describe 'when injecting faults', -> # TODO: implement
      it 'exitcode is non-zero'
      it 'stdout lists failures'
      it 'stdout shows failure details'
