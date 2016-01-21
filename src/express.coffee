## Convenience stuff around Express.JS
# Will eventually be moved into its own library

agree = require('./agree')

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

# TODO: allow referencing named schemas
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

# TODO: treat as special case of responseHeaderMatches ?
conditions.responseHeaderSet = (header) ->
  check = (req, res) ->
    actual = res._headers[header.toLowerCase()]
    err = if not actual? then new Error "Response did not set header '#{header}'" else null
    return err

  c = new agree.Condition check, "Response has set header '#{header}'", { 'header': header }
  c.target = 'arguments'
  return c

conditions.responseContentType = (type) ->
  check = (req, res) ->
    header = res._headers['content-type']
    actual = header?.split(';')[0]
    err = if actual != type then new Error "Response has wrong Content-Type. Expected '#{type}', got '#{actual}'" else null
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

exports.installExpressRoutes = (app, routes) ->
  for name, route of routes
    contract = agree.getContract route
    method = contract.attributes.http_method?.toLowerCase()
    path = contract.attributes.http_path
    if method and path
      app[method] path, route
    else
      console.log "WARN: Contract '#{contract.name}' missing HTTP method/path"

exports.mockingMiddleware = (req, res, next) ->
  # attaches data sent with json() function
  original = res.json
  res.json = (obj) ->
    res._jsonData = obj
    original.apply res, [obj]
  next()

exports.requestFail = (i, args, failures, reason) ->
  [req, res] = args
  res.status 422
  errors = failures.map (f) -> { condition: f.condition.name, message: f.error.toString() }
  res.json { errors: errors }

exports.conditions = conditions
