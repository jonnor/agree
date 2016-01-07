


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

Testing/QA

* Ability to know code test coverage,
including verification exhaustiveness
* Ability to calculate complexity

Documentation

* Integration with HTTP api docs tools,
like [Blueprint](https://apiblueprint.org/)

## Quasi-static checking

> An approach to static verification in dynamic languages

### Background

[Static analysis](https://en.wikipedia.org/wiki/Static_program_analysis)
and verification is done at 'compile time', by a compiler or a static analysis tool.
Static analysis tools must generally implement a fully-featured parser
for the target language, which for some languages (like C++) is very hard.
Even then, the amount of things that can be verified are very limited,
due to missing guarantees from the programming language - and no built-in way
for programmer to state further guarantees.

Exceptions are some statically typed languages implementing [algebraic types](https://en.wikipedia.org/wiki/Algebraic_data_type)
(like Rust, Haskell) and [dependent types](https://en.wikipedia.org/wiki/Dependent_type) (like Idris, Agda),
where one can encode user-decided code properties in a type, and the compiler will enforce them.

Most dynamic languages (like JavaScript), have even less things that can be statically verified
- due to their dynamic and dynamically typed nature.
Even something trivial, like referencing undefined variables is not commonly done.

Another verification technique is [dynamic analysis](https://en.wikipedia.org/wiki/Dynamic_program_analysis),
which is done at run-time and with all real-life/external/side effects of the program also being caused,
and requring to trigger all the relevant code paths for good coverage.

### Concept

Quasi-static verification is a mix: We execute code (dynamic analysis),
instead of using a compiler/parser. However, the code is written in a way that
allows us to reason about it, without needing external inputs to trigger,
and without causing external effects.

The following components are needed

1. A way to describe guaranteed and required code properties.
2. A way to load code and properties - without causing side-effects.
3. Tool(s) that reason about whether code is in violation.

Since we're using the host language directly, this is very related to the concept
of an embedded DSL.

### Agree quasi-static

As a particular implementation of this concept could use

1. Contracts (pre/post-conditions / invariants)
2. Promise/function chains, exported on module-level
Would have contracts attached, and the 'body' of the code
be captured but not executed to prevent side-effects.
3. ? example propagation through chain ?
use predicate valid/examples, insert into chain
verify that there are no cases where something passes post-conditions, then fails next precondition?
this assumes that the pre/postconditions of a step/function is well formed
so for full verification, the step must also be verified.
an example which



this strategy likely requires that steps are not stateful, all state must enter through function arguments

## Related

* [libhoare.rs](https://github.com/nrc/libhoare), contracts in Rust

## Thoughs by others

> For a multi paradigm language to derive benefits from functional programming,
> it should allow developers to explicitly write guarantees that can be enforced at compile time.
> This is a promising direction but, to my knowledge, it's not available in any of the languages you mentioned.

[Hacker News: murbard2 on functional programming](https://news.ycombinator.com/item?id=10812198)

> I really want a tool that lets me mix and match operational code with proofs.
> It's common now to write a unit test while debugging something,
> less common to write a randomized property tester,
> and rare to see a theorem prover being used.
> It would be fantastic if I could casually throw in a proof while debugging a hard problem.

[Hacker News: MichaelBurge on Idris](https://news.ycombinator.com/item?id=10856929)
