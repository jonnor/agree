# Agree - Introspectable Contracts Programming for JavaScript
# * Copyright (c) 2016 Jon Nordby <jononor@gmail.com>
# * Agree may be freely distributed under the MIT license

## JSON Schema support
#
# TODO: allow to infer schema from example object(s). TODO: check existing libraries for this feature
# TODO: allow registering and referencing named schemas
# MAYBE: combine inferred schema, with class-invariant,
#    to ensure all properties are declared in constructor with defaults?
#    if used as pre-condition on other functions, basically equivalent to a traditional class type!
# TODO: allow to infer schema from Knex schema/queries or Postgres/*SQL schemas

exports.validate = (data, schema, options) ->
  tv4 = require 'tv4'

  result = tv4.validateMultiple data, schema, !options.allowUnknown
  #console.log 'd', data, result
  if result.valid
    return null
  else
    message = []
    for e in result.errors
      message.push "#{e.message} for path '#{e.dataPath}'"
    return new Error message.join('\n')

exports.normalize = (schema) ->
  schema['$schema'] = 'http://json-schema.org/draft-04/schema' if not schema['$schema']

  return schema



