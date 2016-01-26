
chai = require 'chai'
agree = require '../'

projectPath = (p) ->
  path = require 'path'
  return path.join __dirname, '..', p

agreeDoc = (modulePath, extraArgs, callback) ->
  child_process = require 'child_process'
  prog = projectPath "./bin/agree-doc"
  args = [
    modulePath
  ].concat extraArgs
  options = {}
  child_process.execFile prog, args, options, callback

describe 'agree-doc', ->

  describe 'on HTTP server example', ->
    example = projectPath 'examples/httpserver.coffee'
    stdout = ""
    stderr = ""

    describe 'requesting plain-text docs', ->

      it 'exitcode is 0', (done) ->
        agreeDoc example, [], (err, sout, serr) ->
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

    describe 'requesting API Blueprint docs', ->

      it 'exitcode is 0', (done) ->
        agreeDoc example, ['--blueprint'], (err, sout, serr) ->
          stdout = sout
          stderr = serr
          chai.expect(err).to.not.exist
          return done err
      describe 'Blueprint', ->
        blueprint = ''
        before () ->
          blueprint = stdout
        it 'has header', () ->
          chai.expect(blueprint).to.contain 'FORMAT: 1A\n'
        it 'includes all routes', () ->
          chai.expect(blueprint).to.contain '/newresource [POST]\n'
          chai.expect(blueprint).to.contain '/somedata [GET]\n'
        it 'has headers', () ->
          chai.expect(blueprint).to.include '+ Headers\n'
          chai.expect(blueprint).to.include 'Location: /'
        it 'has Body examples', () ->
          chai.expect(blueprint).to.include '+ Body\n'
        it 'has Requests', () ->
          chai.expect(blueprint).to.include '+ Request (application/json)\n'
        it 'has Responses', () ->
          chai.expect(blueprint).to.include '+ Response 201 (application/json)\n'
        it 'has Schema', () ->
          chai.expect(blueprint).to.include '+ Schema\n'
          chai.expect(blueprint).to.include '"$schema": "http://json-schema.org/draft-04/schema"'

