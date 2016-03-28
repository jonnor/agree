# Agree - Introspectable Contracts Programming for JavaScript
# * Copyright (c) 2016 Jon Nordby <jononor@gmail.com>
# * Agree may be freely distributed under the MIT license

## Static analysis
# 1) Proving that program will _not work_
# easy case(s). Adding many such will help in most practical QA work
# 2) Proving that program will _always work_
# implies completeness, of both problem specification, and reasoning
# much, much harder. Consequence of mistake also higher, because promise is much stronger
# Near-impossible for (unrestricted) JavaScript, and not a goal of Agree to guarantee.
# However, it may be desirable to have options where we can inform
# about that we're unable to reason (using the implemented strategies),
# where the programmer can help by adding pre/post-conditions
# A semi-complete requirement may be that 'all contracts must be checkable',
# meaning that one can apply the strategies for proving broken code.
# This is basically a code-coverage type concept,
# ensuring not 100% correctness, just 100% analysis coverage.
#
# Scenarios which we'd like to detect, to help the programmer with include
#
# 1) Creating a new function chain, wanting to couple A -> B
# but they have incompatible signatures. Differences can be subtle
# (like due to inconsistent conventions), or huge
# (possibly signalling another function should be used)
# -> add adapter, change target B or change source A
# 2) A function used in multiple places changes return values (post-conditions)
# one or more call-sites still expects the old behavior.
# Can happen both when refactoring a codebase, or when a library is updated
# -> programmer must update call-site, revert change, or add adapter

# MAYBE: Support reducing failures to a minimal case

agree = require './agree'

pairsFromChain = (chain) ->
  pairs = []
  chain = chain.chain

  for i in [0...chain.length]
    first = chain[i]
    second = chain[i+1]
    if first and second
      pairs.push
        source: first
        target: second

  return pairs

generateExampleOutputs = (contract) ->
  # TODO: also support inferring/synthesizing from examples of the Condition
  possible = []
  for ex in contract.examples
    continue if not ex.valid
    continue if not ex.type == 'function-call' # TODO: support transforming from other types?
    possible.push ex

  examples = []
  for ex in possible
    failures = contract.postconditions.filter (c) ->
      err = c.check ex.payload.returns
      return err?
    examples.push ex if failures.length < 1

  return examples

checkPreconditions = (contract, examples) ->
  examples.map (ex) ->
    failures = contract.preconditions.filter (c) ->
      err = c.check ex.payload.returns
      return err?
    r =
      example: ex
      valid: failures.length == 0
      failures: failures
    return r

checkPair = (source, target) ->
  source = agree.getContract source
  target = agree.getContract target

  exs = generateExampleOutputs source
  res = checkPreconditions target, exs
  #console.log 's', res, exs, source, target
  return res

# TODO: lookup chain from function
# TODO: allow to check whole modules
exports.checkChain = checkChain = (chain) ->
  # Find pairwise functions, A & B, and their respective contracts
  pairs = pairsFromChain chain
  #console.log 'p', pairs
  pairs.map (p) ->
    checkPair p.source, p.target

exports.main = main = () ->
    throw new Error 'Not implemented yet'
