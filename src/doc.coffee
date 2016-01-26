
## Documentation
# - TODO: allow to generate HTML API docs; including pre,post,classinvariants
# - TODO: allow programs using Agree docs, to have a function they can call in order to 'self-document'

common = require './common'
introspection = require './introspection'

extractDoc = (module) ->
  structured =
    functions: {}
    classes: {}
    unknown: {}

  for exportName, thing of module
    contract = common.getContract thing
    if not contract
      structured.unknown[exportName] = thing.toString()
      continue

    contract.options = undefined # immaterial
    if contract._agreeType == 'FunctionContract'
      target = structured.functions
    if contract._agreeType == 'ClassContract'
      target = structured.functions
    target[exportName] = {
      contract: contract
    }

    # TODO: also extract exported Conditions
    # TODO: extract recursively, not just on top-level. Mirror hierarchy, or flatten tree?

  return structured

# TODO: use some proper templating engine
renderCommandline = (doc, options) ->
  n =
    functions: Object.keys(doc.functions).length
    classes: Object.keys(doc.classes).length
    unknown: Object.keys(doc.unknown).length
  foundSummary = "Found: #{n.functions} Agree functions, #{n.classes} Agree classes, #{n.unknown} unknown symbols"

  functionDoc = []
  for name, data of doc.functions
    d = introspection.describe data.contract
    functionDoc.push d
  functionDoc = functionDoc.join('\n')

  classDoc = []
  for name, data of doc.classes
    d = introspection.describe data.contract
    classDoc.push d
  classDoc = classDoc.join('\n')

  str = foundSummary
  if n.functions
    str += '\n' + functionDoc
  if n.classes
    str += '\n\n' + classDoc

  return str

# for HTTP functions
renderBlueprint = (doc, options) ->

  header = """
  FORMAT: 1A

  # API
  """

  routeDoc = (contract, attr) ->
    path = attr.http_path
    method = attr.http_method
    resource = attr.http_resource or path.substr 1
    action = attr.http_action or contract.name

    includeIndent = '\t\t\t'
    jsonIndented = (o) ->
      json = JSON.stringify o, null, 2
      lines = json.split('\n').map (l) -> includeIndent + l
      return lines.join '\n'

    str = """
    \#\# #{resource} [#{path}]
    \#\#\# #{action} [#{method}]
    """

    # TODO: include examples request/responses

    # Request section
    requestType = null
    requestSchema = null
    for p in contract.preconditions
      requestSchema = p.details.jsonSchema if p.details?.jsonSchema?
      requestType = p.details['content-type'] if p.details?['content-type']?

    str += "\n\n  + Request (#{requestType})" if requestType
    str += "\n\n    + Schema \n\n#{jsonIndented(requestSchema)}\n\n" if requestSchema

    # Reponse section
    responseHeaders = {}
    responseType = null
    responseCode = null
    responseSchema = null
    for p in contract.postconditions
      responseCode = p.details.statusCode if p.details?.statusCode?
      responseType = p.details['content-type'] if p.details?['content-type']?
      responseHeaders[p.details.header] = p.details.regexp if p.details?.header
      responseSchema = p.details.jsonSchema if p.details?.jsonSchema?
      #console.log 'p', p.details
      
    str += "\n\n  + Response #{responseCode} (#{responseType})" if responseCode and responseType
    str += "\n\n    + Schema \n\n#{jsonIndented(responseSchema)}\n\n" if responseSchema
    if Object.keys(responseHeaders).length
      str += "\n\n    + Headers\n"
      for k, v of responseHeaders
        str += "\n#{includeIndent}#{k}: #{v}"

    return str


  routes = []
  for name, func of doc.functions
    contract = func.contract
    continue if not contract
    attr = contract.attributes
    continue if not (attr.http_method and attr.http_path)
    routes.push routeDoc(contract, attr)

  str = header + '\n\n' + routes.join('\n')
  return str

exports.main = main = () ->
  path = require 'path'

  modulePath = process.argv[2]
  modulePath = path.resolve process.cwd(), modulePath
  type = process.argv[3] # FIXME: use proper options parsing

  try
    module = require modulePath
  catch e
    console.log e
    console.log e.line

  docs = extractDoc module
  if type == '--blueprint'
    r = renderBlueprint docs
  else
    r = renderCommandline docs
  console.log r

main() if not module.parent
