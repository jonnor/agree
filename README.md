
# Agree: Introspectable Contracts programming for JavaScript/CoffeeScript

Agree is a library for implementing
[Design by contract](http://en.wikipedia.org/wiki/Design_by_contract) in JavaScript,
including `preconditions`, `postconditions` and `class invariants`.

It is inspired by projects like [contracts.coffee](http://disnetdev.com/contracts.coffee),
but requires no build steps or non-standard language features, and is *introspectable*.

## Introspection

Functions, classes and instances built with Agree know their associated contracts.
This allows to query the code about its properties, to generate documentation,
test-cases and aid in debugging of failures.

## Goals

- No special dependencies, works anywhere (browser, node.js, etc)
- That contracts are used is completely transparent to consuming code
- Can start using contracts stepwise, starting with just some functions/methods
- JavaScript-friendly fluent API (even if written with CoffeeScript)
- Preconditions can, and are encouraged to be used for input validation at runtime

Usecases

- [NoFlo](http://noflojs.org) components: verifying data on inports, specifying component behavior
- HTTP REST apis: specifying behavior, validating request, consistent error handling
- Abstractions: multiple implementations of same interface fully described

## Status

**Experimental** as of March 2015.

* Functions, method and simple class invariants work
* Library has not been used in any real applications yet

High-level TODO:

* Add more helpers for debugging/testing/documentation
* Add async support; Promises and node.js style callbacks
* Add support for contract interfaces, allow reusing a contract multiple times
* Add support for more types of invariants, including on properties

For details see TODO/FIXME/XXX/MAYBE comments in the code.


## Examples

See the tests under [./spec/](./spec) for full reference

    agree = require 'agree'
    c = agree.conditions
    oneNumber = () ->
        # custom condition predicate
        return arguments.length == 1 and typeof arguments[0] == 'number'

    # define a function
    addNumbers = agree.function 'addNumbers'
    .precondition c.noUndefined, () -> console.log 'got undefined!'
    .precondition c.numbersOnly, () -> console.log 'not numbers!'
    .postcondition oneNumber 
    .body (a, b) ->
        # Will only be called when all preconditions were satisfied
        return a+b
    .getFunction()

    # observe the function
    observer = agree.introspection.observe addNumbers

    # use the function
    addNumbers undefined, 2      # stdout: got undefined!
    addNumbers "foo", "baar"     # stdout: not numbers!
    addNumbers 2, 3              # returns 5

    console.log observer         # will print out the events, including failing/passing pre/post conditions

    # TODO: add example of checking test coverage, fuzzing

