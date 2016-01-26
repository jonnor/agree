
agree = require '../'

exports.multiplyByTwo = agree.function 'multiplyByTwo'
.requires agree.conditions.noUndefined
.requires agree.conditions.numbersOnly
.ensures agree.conditions.numbersOnly
.implement (input) ->
    return input*2


# Invalid init
agree.Class 'InvalidInit'
.add exports
.invariant agree.conditions.neverNull('prop1')
.init () ->
    @prop1 = null

agree.Class 'Initable'
.add exports
.invariant agree.conditions.neverNull('prop1')
.init () ->
    @prop1 = "valid"
.method 'dontcallme'
.body (ignor) ->


