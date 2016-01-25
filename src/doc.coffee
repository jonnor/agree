
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

exports.main = main = () ->
  path = require 'path'

  modulePath = process.argv[2]
  modulePath = path.resolve process.cwd(), modulePath

  try
    module = require modulePath
  catch e
    console.log e
    console.log e.line

  docs = extractDoc module
  r = renderCommandline docs
  console.log r

main() if not module.parent
