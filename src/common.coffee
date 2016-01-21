
exports.getContract = (thing) ->
    if thing._agreeType == 'FunctionContract' or thing._agreeType == 'ClassContract'
        return thing
    return thing?._agreeContract

exports.asyncSeries = (items, func, callback) ->
  items = items.slice 0
  results = []
  next = () ->
    if items.length == 0
      return callback null, results
    item = items.shift()
    func item, (err, result) ->
      return callback err if err
      results.unshift result
      return next()
  next()
