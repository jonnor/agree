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

  return new agree.Condition check, "Request must have Content-Type '#{type}'"

conditions.requestSchema = (schema, options = {}) ->
  tv4 = require 'tv4'
  options.allowUnknown = false if not options.allowUnknown
  schemaDescription = schema.id
  schemaDescription = schema if not schemaDescription?
  check = (req, res) ->
    result = tv4.validateMultiple req.json, schema, !options.allowUnknown
    if result.valid
      return null
    else
      message = []
      for e in result.errors
        console.log 'schema err', e
        message.push "#{e.message} for path '#{e.dataPath}'"
      return new Error message.join('\n')
  return new agree.Condition check, "Request body must follow schema '#{schemaDescription}'"

## Routes, with their contracts
routes = {}

# TODO: add post-conditions on response headers, data (JSON schema)
# TODO: add pre-conditions on request data, or needing a particular state
# FIXME: failing pre-conditions should generally return 422, not 500
routes.getSomeData = agree.function 'GET /somedata'
.attr 'http_method', 'GET'
.attr 'http_path', '/somedata'
.pre conditions.requestContentType 'application/json'
.attach (req, res) ->
    res.json db.somedata

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
        type:
          description: 'A tag'
          example: "my favorite thing"
          type: 'string'

requestFail = (i, args, failures) ->
  [req, res] = args
  res.status(422)
  errors = failures.map (f) -> { condition: f.condition.condition.name, message: f.error.toString() }
  res.json { errors: errors }

routes.createResource = agree.function 'POST /newresource'
.attr 'http_method', 'POST'
.attr 'http_path', '/newresource'
.pre (conditions.requestContentType 'application/json'), requestFail
.pre (conditions.requestSchema createSchema), requestFail
.attach (req, res) ->
    db.newresource = req.json

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

## Setup
express = require 'express'
app = express()
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
