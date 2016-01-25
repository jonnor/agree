## Case study and example of implementing a HTTP server with JSON-based REST API, using Agree
try
  agree = require '..' # when running in ./examples of git
catch e
  agree = require 'agree' # when running as standalone example
agreeExpress = agree.express
conditions = agreeExpress.conditions 
tester = new agreeExpress.Tester null

## Contracts
# In production, Contracts on public APIs should be kept in a separate file from implementation
contracts = {}
# Shared contract setup
jsonApiFunction = (method, path) ->
  agree.function "#{method.toUpperCase()} #{path}"
  .attr 'http_method', method
  .attr 'http_path', path
  .attr 'tester', tester # XXX: experimental
  .error agreeExpress.requestFail
  .pre conditions.requestContentType 'application/json'
  .post conditions.responseEnded

contracts.getSomeData = jsonApiFunction 'GET', '/somedata'
  .post conditions.responseStatus 200
  .post conditions.responseContentType 'application/json'
  .post conditions.responseSchema
    id: 'somedata.json'
    "$schema": "http://json-schema.org/draft-04/schema"
    type: 'object'
    required: ['initial']
    properties:
      initial: { type: 'string' }
      nonexist: { type: 'number' }
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

contracts.createResource = jsonApiFunction 'POST', '/newresource'
  .pre conditions.requestSchema
    id: 'newresource.json'
    '$schema': 'http://json-schema.org/draft-04/schema'
    type: 'object'
    required: ['name', 'tags']
    properties:
      name: { type: 'string' }
      tags: { type: 'array', uniqueItems: true, items: { type: 'string' } }
  .post conditions.responseStatus 201
  .post conditions.responseHeaderMatches 'Location', /\/newresource\/[\d]+/


## Database access
# Simulated example of DB or key-value store, for keeping state. SQL or no-SQL in real-life
db =
  state:
    somekey: { initial: 'Foo' }
  get: (key) ->
    return new Promise (resolve, reject) ->
        data = db.state[key]
        return resolve data
  set: (key, data) ->
    return new Promise (resolve, reject) ->
        db.state[key] = data
        return resolve key
  add: (key, data) ->
    return new Promise (resolve, reject) ->
        db.state[key] = [] if not db.state[key]?
        db.state[key].push data
        sub = db.state[key].length
        return resolve sub

## Implementation
routes = {}
routes.getSomeData = contracts.getSomeData.attach (req, res) ->
  db.get 'somekey'
  .then (data) ->
    res.json data
    Promise.resolve null

routes.createResource = contracts.createResource.attach (req, res) ->
  db.add 'newresource', res.body
  .then (key) ->
    res.set 'Location', "/newresource/#{key}"
    res.status(201).end()
    Promise.resolve null

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
