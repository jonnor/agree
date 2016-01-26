## Case study and example of implementing a HTTP server with JSON-based REST API, using Agree
try
  agree = require '..' # when running in ./examples of git
catch e
  agree = require 'agree' # when running as standalone example
agreeExpress = agree.express
conditions = agreeExpress.conditions
Promise = agree.Promise # polyfill for node.js 0.10 compat

## Contracts
# In production, Contracts for public APIs should be kept in a separate file from implementation
contracts = {}
# Shared contract setup
jsonApiFunction = (method, path) ->
  agree.function "#{method.toUpperCase()} #{path}"
  .attr 'http_method', method
  .attr 'http_path', path
  .error agreeExpress.requestFail
  .requires conditions.requestContentType 'application/json'
  .ensures conditions.responseEnded

contracts.getSomeData = jsonApiFunction 'GET', '/somedata'
  .ensures conditions.responseStatus 200
  .ensures conditions.responseContentType 'application/json'
  .ensures conditions.responseSchema
    id: 'somedata.json'
    type: 'object'
    required: ['initial']
    properties:
      initial: { type: 'string' }
      nonexist: { type: 'number' }
  .successExample 'All headers correct',
    _type: 'http-request-response'
    headers:
      'Content-Type': 'application/json'
    responseCode: 200
  .failExample 'Wrong Content-Type',
    _type: 'http-request-response'
    headers:
      'Content-Type': 'text/html'
    responseCode: 422

contracts.createResource = jsonApiFunction 'POST', '/newresource'
  .requires conditions.requestSchema
    id: 'newresource.json'
    type: 'object'
    required: ['name', 'tags']
    properties:
      name: { type: 'string' }
      tags: { type: 'array', uniqueItems: true, items: { type: 'string' } }
  .ensures conditions.responseStatus 201
  .ensures conditions.responseContentType 'application/json' # even if we don't have body
  .ensures conditions.responseHeaderMatches 'Location', /\/newresource\/[\d]+/
  .successExample 'Valid data in body',
    _type: 'http-request-response'
    headers:
      'Content-Type': 'application/json'
    body:
      name: 'myname'
      tags: ['first', 'second']
    responseCode: 201
  .failExample 'Invalid data',
    _type: 'http-request-response'
    headers:
      'Content-Type': 'application/json'
    body:
      name: 'valid'
      tags: [1, 2, 3]
    responseCode: 422

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
routes.getSomeData = contracts.getSomeData.implement (req, res) ->
  db.get 'somekey'
  .then (data) ->
    res.json data
    Promise.resolve res

routes.createResource = contracts.createResource.implement (req, res) ->
  db.add 'newresource', req.body
  .then (key) ->
    res.set 'Location', "/newresource/#{key}"
    res.set 'Content-Type', 'application/json' # we promised..
    res.status(201).end()
    Promise.resolve res

## Setup
express = require 'express'
bodyparser = require 'body-parser'
app = express()
app.use bodyparser.json()
app.use agreeExpress.mockingMiddleware
agreeExpress.installExpressRoutes app, routes
module.exports = routes # for introspection by Agree tools
agree.testing.registerTester 'http-request-response', new agreeExpress.Tester app

## Run
main = () ->
  port = process.env.PORT
  port = 3333 if not port
  app.listen port, (err) ->
    throw err if err
    console.log "#{process.argv[1]}: running on port #{port}"

main() if not module.parent
