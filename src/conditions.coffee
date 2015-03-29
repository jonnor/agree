# Conditions/Predicates, can be used as class invariants, pre- or post-conditions
# Some of these can be generic and provided by framework, parametriced to 
# tailor to particular program need.
#
# TODO: add names/descriptions to conditions, for better introspection
# TODO: let predicates declare positive/negative examples, use as doc+tests
# TODO: generalize the composition/parametrization of predicates?
# - look up an identifier (string, number) in some context (arguments, this)
# - take a value for the instance of a set (types, values) to check for 
# TODO: consider fluent interface for condition compositon
# TODO: considering integration with common expect/assert libraries for checks
# TODO: add ability to report cause of predicate failure. Via exception??
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

conditions.numbersOnly = () ->
    for a in arguments
        return false if typeof a != 'number'
    return true
conditions.numbersOnly.description = "all arguments must be numbers"

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