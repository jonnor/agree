[![Build Status](https://travis-ci.org/jonnor/agree.svg?branch=master)](https://travis-ci.org/jonnor/agree)
# Agree: Contract programming for JavaScript

Agree is a library for implementing Contract Programming / 
[Design by contract](http://en.wikipedia.org/wiki/Design_by_contract) in JavaScript,
including `preconditions`, `postconditions` and `class invariants`.

It is inspired by projects like [contracts.coffee](http://disnetdev.com/contracts.coffee),
but requires *no build steps*, *no non-standard language features*, and is *introspectable*.

## Status

**Experimental** as of November 2016.

* Functions, method and class invariants work
* Support for asyncronous functions using Promise (ES6/A+ compatible)
* Contracts can be reusable, and used to define interfaces (having multiple implementations)
* Some proof-of-concept documentation and testing tools exists
* Library has not been used in any real applications yet

### TODO 0.1 "minimally useful"

* Lock down the core contracts API
* Add more tests for core functionality
* Do use-case exploration of a browser/frontend example
* Run all automated tests under browser
* Stabilize and document the testing and documentation tools

Future

* Support postcondition expressions that contain function inputs
* Support postconditions expressions matching against 'old' instance members
* Support invariants on properties

For details see TODO/FIXME/XXX/MAYBE comments in the code.

## Installing

Add Agree to your project using [NPM](http://npmjs.org)

    npm install --save agree
    npm install --save-dev agree-tools

## License

MIT, see [LICENSE.md](./LICENSE.md)

## Examples

[HTTP server](./examples/httpserver.coffee)

See the tests under [./spec/](./spec) for full reference.

## Tools

[agree-tools](https://github.com/jonnor/agree-tools) uses the introspection features of Agree
to provide support for testing and documentation, driven by the contracts/code.


## Goals

- No special dependencies, works anywhere (browser, node.js, etc), usable as library
- That contracts are used is completely transparent to consuming code
- Can start using contracts stepwise, starting with just some functions/methods
- JavaScript-friendly fluent API (even if written with CoffeeScript)
- Preconditions can, and are encouraged to, be used for input validation

Usecases

- HTTP REST apis: specifying behavior, validating request, consistent error handling
- [NoFlo](http://noflojs.org) components: verifying data on inports, specifying component behavior
- Interfaces: multiple implementations of same interface fully described


## Introspection

Functions, classes and instances built with Agree know their associated contracts.
This allows to query the code about its properties, to generate documentation,
test-cases and aid in debugging of failures.

Agree is partially related other work by [author](http://jonnor.com) on introspectable programming,
including [Finito](http://finitosm.org) (finite state machines)
and [NoFlo](http://noflojs.org)/[MicroFlo](http://microflo.org) (dataflow).

