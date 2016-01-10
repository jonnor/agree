# Conditions/Predicates, can be used as class invariants, pre- or post-conditions
# Some of these can be generic and provided by framework, parametriced to 
# tailor to particular program need.
#
# TODO: make Conditions _have a_ predicate function, instead of be one
#  - also take name and description, for better introspection
# TODO: allow/encourage to attach failing and passing examples to contract,
#  - use for tests/doc of the contract/predicate itself
#  - basis for further reasoning, ref doc/brainstorm.md
#  - .precondition(kkk).valid(barisbaz: { bar: baz }).invalid(missingbar: { foo: bar })
#
# TODO: generalize the composition/parametrization of predicates?
# - look up an identifier (string, number) in some context (arguments, this)
# - take a value for the instance of a set (types, values) to check for 
# TODO: considering integration with common expect/assert libraries for checks
# FIXME: return Error object with cause of predicate failure, for better introspection
#
# TODO: find a way to ensure that conditions don't have side-effects!
#
# Ideas:
# IDEA: allow to generate/composte conditions out of JSON schemas

agree = require './agree'
Condition = agree.Condition

conditions = {}

checkUndefined = () ->
    index = 0
    for a in arguments
        isA = a?
        if not isA
            return new Error "Argument number #{index} is undefined"
    return null
conditions.noUndefined = new Condition checkUndefined, 'no undefined arguments'

conditions.noUndefined.examples = [
    name: 'one undefined argument'
    valid: false
    create: () -> return conditions.noUndefined
    context: () -> return null
    args: [ undefined, 2, 3 ]
]

checkNumbers = () ->
    index = 0
    for a in arguments
        if typeof a != 'number'
            return new Error "Argument number #{index} is not a number"
    return null
conditions.numbersOnly = new Condition checkNumbers, "all arguments must be numbers"

# parametric functions, returns a Condition
conditions.neverNull = (attribute) ->
    p = () ->
        return if not this[attribute]? then new Error "Attribute #{attribute} is null" else null
    return new Condition p, "#{attribute} must not be null"

conditions.attributeEquals = (attribute, value) ->
    p = () ->
        return if this[attribute] != value then new Error "Attribute #{attribute} does not equal #{value}" else null
    return new Condition p, "Attribute #{attribute} must equal value"

conditions.attributeTypeEquals = (attribute, type) ->
    p = () ->
        actualType = typeof this[attribute]
        return if actualType != type then new Error "typeof this.#{attribute} != #{type}: #{actualType}" else null
    return new Condition p, "Attribute #{attribute} must be type #{type}"

module.exports = conditions
