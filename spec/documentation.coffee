
chai = require 'chai'
agree = require '../'

projectPath = (p) ->
  path = require 'path'
  return path.join __dirname, '..', p

agreeDoc = (modulePath, callback) ->
  child_process = require 'child_process'
  prog = projectPath "./bin/agree-doc"
  args = [
    modulePath
  ]
  options = {}
  child_process.execFile prog, args, options, callback

describe 'agree-doc', ->

  describe 'on HTTP server example', ->
    example = projectPath 'examples/httpserver.coffee'
    stdout = ""
    stderr = ""

    describe 'requesting plain-text docs', ->

      it 'exitcode is 0', (done) ->
        agreeDoc example, (err, sout, serr) ->
          stdout = sout
          stderr = serr
          chai.expect(err).to.not.exist
          return done err
      it 'stdout includes all functions', () ->
        chai.expect(stdout).to.contain 'GET /somedata'
        chai.expect(stdout).to.contain 'POST /newresource'
      it 'stdout contains preconditions', () ->
        chai.expect(stdout).to.include 'preconditions:'
        chai.expect(stdout).to.include 'Request must have Content-Type'
        chai.expect(stdout).to.include 'Request body must follow schema'
      it 'stdout contains postconditions', () ->
        chai.expect(stdout).to.include 'postconditions:'
        chai.expect(stdout).to.include 'Reponse is sent'
        chai.expect(stdout).to.include 'Response body follows schema'

