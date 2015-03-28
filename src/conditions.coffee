# Predicates, can be used as class invariants, pre- or post-conditions
# Some of these can be generic and provided by framework, parametriced to 
# tailor to particular program need
#
# TODO: generalize the composition/parametrization of predicates?
# - look up an identifier (string, number) in some context (arguments, this)
# - take a value for the instance of a set (types, values) to check for 

conditions = {}

conditions.noUndefined = () ->
    for a in arguments
        return false if not a?
    return true

conditions.numbersOnly = () ->
    for a in arguments
        return false if typeof a != 'number'
    return true

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
