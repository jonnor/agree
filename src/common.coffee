
exports.getContract = (thing) ->
    if thing._agreeType == 'FunctionContract' or thing._agreeType == 'ClassContract'
        return thing
    return thing?._agreeContract
