
agree = require '../'

exports.multiplyByTwo = agree.function 'multiplyByTwo'
.pre agree.conditions.noUndefined
.post agree.conditions.numbersOnly
.body (input) -> return input*2
.getFunction()


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


