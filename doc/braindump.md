


Embedded devices
----------------
How to apply introspectable contracts to embedded devices?

Challenges come from:

* Poor first-class function support in popular languages like C/C++
* contrained CPU resources of the target devices
* difficulty of writing target-independent code/tests
* difficulty/inconvenience of running tests on-device
* very limited program memory, hard to store lots of introspection data
* often not directly connected to device with the debugging UI

Possible approaches

* Using macros in C/C++. Would both insert pre/post/invart checking code,
and act as markers for tool to build the contract instrospection data.
* Use custom clang/LLVM to compile C/C++, transparently inserting checking code.
Would output contract introspection data.
* Use a modern language with compiler hooks. Maybe Rust?
* DSL...


Cross-language
--------------

Useful when doing polyglot programming,
to be able to model things in the same way.

Most beneficial if one can share tools between different languages:
for documentation, testing, debugging.

Serialize contract to standard .json representation?
All tools operate on this?


Tools wishlist
-------------------

Debugging (in-situ and retroactive)

* Ability to compare multiple different runs,
looking at differences in input/output/conditions
* Ability to see all contracts in
* Ability to see relationships between contracts,
including same-level and hierarchies

Testing

* Ability to know code test coverage,
including verification exhaustiveness

Documentation

* Integration with HTTP api docs tools,
like [Blueprint](https://apiblueprint.org/)

