
# Agree: Contract programming for JavaScript

Agree is a library for implementing Contract Programming / 
[Design by contract](http://en.wikipedia.org/wiki/Design_by_contract) in JavaScript,
including `preconditions`, `postconditions` and `class invariants`.

It is inspired by projects like [contracts.coffee](http://disnetdev.com/contracts.coffee),
but requires *no build steps*, *no non-standard language features*, and is *introspectable*.

## Introspection

Functions, classes and instances built with Agree know their associated contracts.
This allows to query the code about its properties, to generate documentation,
test-cases and aid in debugging of failures.

Agree is partially related other work by [author](http://jonnor.com) on introspectable programming,
including [Finito](http://finitosm.org) (finite state machines)
and [NoFlo](http://noflojs.org)/[MicroFlo](http://microflo.org) (dataflow).

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

## Status

**Experimental** as of January 2016.

* Functions, method and class invariants work
* Support for asyncronous functions using Promise (ES6/A+ compatible)
* Contracts can reusable, and used to define interfaces with multiple implementations
* Some proof-of-concept documentation and testing tools exists
* Library has not been used in any real applications yet

High-level TODO:

* Add more tests for core functionality
* Do use-case exploration of a browser/frontend example
* Remove CoffeeScript as run-time dependency
* Setup build automated tests for browser
* Stabilize and document the testing and documentation tools
* Add support for more types of invariants, including on properties

For details see TODO/FIXME/XXX/MAYBE comments in the code.

## Installing

Add Agree to your project using [NPM](http://npmjs.org)

    npm install --save agree

## Examples

[HTTP server](./examples/httpserver.coffee)

See the tests under [./spec/](./spec) for full reference.

## Tools

`agree-doc` can introspect modules and generate plain-text documentation.

`agree-test` can introspect modules, extract examples from contracts,
and automatically generate and run tests from these.
