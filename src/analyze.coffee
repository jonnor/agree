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

checkPromisePairs = (chain) ->
    # Find pairwise functions, A & B, and their respective contracts
    # Generate example values satisfying postcond(A)
    #  can be successExample of Contract
    #  (later) be synthesized/inferred from Condition examples
    # Check each example against precond(B) to find violations
    #  (later) reduce the case to a minimal one
    # Report

exports.main = main = () ->
    throw new Error 'Not implemented yet'
