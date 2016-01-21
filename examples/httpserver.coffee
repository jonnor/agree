## Case study and example of implementing a HTTP server with JSON-based REST API, using Agree
## 
try
  agree = require '..' # when running in ./examples of git
catch e
  agree = require 'agree' # when running as standalone example

## Simulating access to a DB or key-value store, for keeping state
# Would be SQL or no-SQL in real-life
db = {}
db.somedata =
  initial: 'Foo'

## Conditions useful with HTTP/JSON/expressjs
conditions = {}
conditions.requestContentType = (type) ->
  check = (req, res) ->
    actual = req.get 'Content-Type'
    err = if actual != type then new Error "Request must have Content-Type: '#{type}', got '#{actual}'" else null
    return err

  return new agree.Condition check, "Request must have Content-Type '#{type}'", { 'content-type': type }

validateSchema = (data, schema, options) ->
    tv4 = require 'tv4'
    result = tv4.validateMultiple data, schema, !options.allowUnknown
    #console.log 'd', data, result
    if result.valid
      return null
    else
      message = []
      for e in result.errors
        message.push "#{e.message} for path '#{e.dataPath}'"
      return new Error message.join('\n')

conditions.requestSchema = (schema, options = {}) ->
  options.allowUnknown = false if not options.allowUnknown
  schemaDescription = schema.id
  schemaDescription = schema if not schemaDescription?

  check = (req, res) ->
    return validateSchema req.body, schema, options

  return new agree.Condition check, "Request body must follow schema '#{schemaDescription}'", { jsonSchema: schema }

conditions.responseStatus = (code) ->
  check = (req, res) ->
    actual = res.statusCode
    err = if actual != code then new Error "Response did not have statusCode '#{code}', instead '#{actual}'" else null
    return err

  c = new agree.Condition check, "Response has statusCode '#{code}'", { 'statusCode': code }
  c.target = 'arguments'
  return c

conditions.responseContentType = (type) ->
  check = (req, res) ->
    actual = res._headers['content-type'].split(';')[0]
    err = if actual != type then new Error "Response wrong Content-Type. Expected '#{type}', got '#{actual}'" else null
    return err

  c = new agree.Condition check, "Response has Content-Type '#{type}'", { 'content-type': type }
  c.target = 'arguments'
  return c

checkResponseEnded = (req, res) ->
  return if not res.finished then new Error 'Response was not finished' else null
conditions.responseEnded = new agree.Condition checkResponseEnded, "Reponse is sent"
conditions.responseEnded.target = 'arguments'

conditions.responseSchema = (schema, options = {}) ->
  options.allowUnknown = false if not options.allowUnknown
  schemaDescription = schema.id
  schemaDescription = schema if not schemaDescription?
  check = (req, res) ->
    return validateSchema res._jsonData, schema, options
  c = new agree.Condition check, "Response body follows schema '#{schemaDescription}'", { jsonSchema: schema }
  c.target = 'arguments'
  return c

## Routes, with their contracts
routes = {}

# TODO: allow referencing named schemas
createSchema =
  id: 'newresource.json'
  "$schema": "http://json-schema.org/draft-04/schema"
  title: 'Content item'
  description: ""
  type: 'object'
  required: ['name', 'tags']
  properties:
    name:
      type: 'string'
    tags:
      description: ''
      type: 'array'
      minItems: 0
      uniqueItems: true
      items:
        description: 'A tag'
        example: "my favorite thing"
        type: 'string'

requestFail = (i, args, failures) ->
  [req, res] = args
  res.status 422
  errors = failures.map (f) -> { condition: f.condition.name, message: f.error.toString() }
  res.json { errors: errors }

somedataSchema =
  id: 'somedata.json'
  "$schema": "http://json-schema.org/draft-04/schema"
  title: 'Some data'
  description: ""
  type: 'object'
  required: ['initial']
  properties:
    initial:
      type: 'string'
    nonexist:
      type: 'number'

# TODO: add pre-conditions which needing a particular app state, like existance of resource created by previous call
routes.getSomeData = agree.function 'GET /somedata'
.attr 'http_method', 'GET'
.attr 'http_path', '/somedata'
.pre conditions.requestContentType 'application/json'
.post conditions.responseEnded
.post conditions.responseStatus 200
.post conditions.responseContentType 'application/json'
.post conditions.responseSchema somedataSchema
.attach (req, res) ->
    res.json db.somedata

routes.createResource = agree.function 'POST /newresource'
.attr 'http_method', 'POST'
.attr 'http_path', '/newresource'
.pre conditions.requestContentType 'application/json'
.pre conditions.requestSchema createSchema
.post conditions.responseEnded
.post conditions.responseStatus 201
.post conditions.responseContentType 'application/json'
.error requestFail
.attach (req, res) ->
    db.newresource = req.body
    res.status(201).end()

## Utilities
# TODO: move into library?
installExpressRoutes = (app, routes) ->
  for name, route of routes
    contract = agree.getContract route
    method = contract.attributes.http_method?.toLowerCase()
    path = contract.attributes.http_path
    if method and path
      app[method] path, route
    else
      console.log "WARN: Contract '#{contract.name}' missing HTTP method/path"

jsonMockMiddleware = (req, res, next) ->
  # attaches data sent with json() function
  original = res.json
  res.json = (obj) ->
    res._jsonData = obj
    original.apply res, obj
  next()

## Setup
express = require 'express'
bodyparser = require 'body-parser'
app = express()
app.use bodyparser.json()
app.use jsonMockMiddleware
installExpressRoutes app, routes
module.exports = routes # for introspection by Agree tools

## Run
main = () ->
  port = process.env.PORT
  port = 3333 if not port
  app.listen port, (err) ->
    throw err if err
    console.log "#{process.argv[1]}: running on port #{port}"

main() if not module.parent
