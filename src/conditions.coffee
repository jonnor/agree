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

conditions = {}

conditions.noUndefined = () ->
    for a in arguments
        return false if not a?
    return true
conditions.noUndefined.description = "no undefined arguments" 

conditions.noUndefined.examples = [
    name: 'one undefined argument'
    valid: false
    create: () -> return conditions.noUndefined
    context: () -> return null
    args: [ undefined, 2, 3 ]
]
conditions.noUndefined.toJSON = () -> return this.description

conditions.numbersOnly = () ->
    for a in arguments
        return false if typeof a != 'number'
    return true
conditions.numbersOnly.description = "all arguments must be numbers"
conditions.numbersOnly.toJSON = () -> return this.description

# parametric functions, returns a predicate
conditions.neverNull = (attribute) ->
    return () ->
        return this[attribute]?

conditions.attributeEquals = (attribute, value) ->
    return () ->
        return this[attribute] == value

conditions.attributeTypeEquals = (attribute, type) ->
    return () ->
        return typeof this[attribute] == type

module.exports = conditions
