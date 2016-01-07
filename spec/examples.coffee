
agree = require '../'

exports.multiplyByTwo = agree.function 'multiplyByTwo'
.pre agree.conditions.noUndefined
.pre agree.conditions.numbersOnly
.post agree.conditions.numbersOnly
.attach (input) ->
    return input*2


# Invalid init
agree.Class 'InvalidInit'
.add exports
.invariant agree.conditions.neverNull 'prop1'
.init () ->
    @prop1 = null

agree.Class 'Initable'
.add exports
.invariant agree.conditions.neverNull 'prop1'
.init () ->
    @prop1 = "valid"
.method 'dontcallme'
.body (ignor) ->


