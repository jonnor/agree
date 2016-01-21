## Case study and example of implementing a HTTP server with JSON-based REST API, using Agree
try
  agree = require '..' # when running in ./examples of git
catch e
  agree = require 'agree' # when running as standalone example
agreeExpress = agree.express
conditions = agreeExpress.conditions 
tester = new agreeExpress.Tester null

## Simulating access to a DB or key-value store, for keeping state. SQL or no-SQL in real-life
db = { somedata: { initial: 'Foo' } }
routes = {} ## Routes, with their contracts
# TODO: add example of pre-conditions needing a particular app state, like existance of resource created by previous call

# Shared contract setup
jsonApiFunction = (method, path) ->
  agree.function "#{method.toUpperCase()} #{path}"
  .attr 'http_method', method
  .attr 'http_path', path
  .attr 'tester', tester # XXX: experimental
  .error agreeExpress.requestFail
  .pre conditions.requestContentType 'application/json'
  .post conditions.responseEnded

somedataSchema =
  id: 'somedata.json'
  "$schema": "http://json-schema.org/draft-04/schema"
  type: 'object'
  required: ['initial']
  properties:
    initial: { type: 'string' }
    nonexist: { type: 'number' }
routes.getSomeData = jsonApiFunction 'GET', '/somedata'
.post conditions.responseStatus 200
.post conditions.responseContentType 'application/json'
.post conditions.responseSchema somedataSchema
.successExample 'correct-headers',
  headers:
    'Content-Type': 'application/json'
  responseCode: 200
  responseBody:
    'initial': 'Foo'
.failExample 'wrong-content-type',
  headers:
    'Content-Type': 'text/html'
  responseCode: 422
.attach (req, res) ->
    res.json db.somedata

createSchema =
  id: 'newresource.json'
  '$schema': 'http://json-schema.org/draft-04/schema'
  type: 'object'
  required: ['name', 'tags']
  properties:
    name: { type: 'string' }
    tags: { type: 'array', uniqueItems: true, items: { type: 'string' } }
routes.createResource = jsonApiFunction 'POST', '/newresource'
.pre conditions.requestSchema createSchema
.post conditions.responseStatus 201
.post conditions.responseHeaderMatches 'Location', /\/newresource\/[\d]+/
.attach (req, res) ->
    db.newresource = [] if not db.newresource
    db.newresource.push req.body
    res.set 'Location', "/newresource/#{db.newresource.length}"
    res.status(201).end()

## Setup
express = require 'express'
bodyparser = require 'body-parser'
app = express()
app.use bodyparser.json()
app.use agreeExpress.mockingMiddleware
agreeExpress.installExpressRoutes app, routes
module.exports = routes # for introspection by Agree tools
tester.app = app

## Run
main = () ->
  port = process.env.PORT
  port = 3333 if not port
  app.listen port, (err) ->
    throw err if err
    console.log "#{process.argv[1]}: running on port #{port}"

main() if not module.parent
