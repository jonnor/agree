
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

    # FIXME: differentiate out classes/ClassContracts
    # TODO: also extract exported Conditions
    contract.options = undefined # immaterial
    structured.functions[exportName] = {
      contract: contract
    }

  return structured

# TODO: use some proper templating engine
renderCommandline = (doc, options) ->
  n =
    functions: Object.keys(doc.functions).length
    classes: Object.keys(doc.classes).length
    unknown: Object.keys(doc.unknown).length
  foundSummary = "Found: #{n.functions} Agree functions, #{n.classes} Agree classes, #{n.unknown} unknown symbols\n"

  functionDoc = []
  for name, data of doc.functions
    d = introspection.describe data.contract
    functionDoc.push d
  functionDoc = functionDoc.join('\n')

  return foundSummary + functionDoc

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
