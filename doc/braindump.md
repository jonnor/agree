# Benefits of contracts

Since contract programming / design-by-contracts is not a common tool/technique,
will likely need to explain the benefits to convince someone to try it out.
Especially relation, and differences to, (static) typing, and automated testing
may be revealing.
<!-- TODO: document this somewhere in project description/README -->

Important to note, that contracts does not exclude (static) typing nor automated testing.
In fact, probably best seen as complimentary. Use together, especially with automated tests!

* Unlike automated tests, validates each and every execution, including in production.
More exhaustive coverage, reducing things that slip through.
* Can encode/enforce more info than (conventional) typing systems.
Reaching expressitivity only available with algebraic types, dependent types and effect typing.
Neither of these are commonly available for JavaScript right now.
* Produces informational error messages as side-effect of verification
* (should) Less effort spent for same verification/coverage level
* (maybe) Allow for static reasoning of programs.
Proved achievable for static systems, like Code Contract for .NET.
Yet unproven for JavaScript, see section 'quasi-static analysis' for details.

## Benefits of Agree approach

Fact that we're applying to a highly dynamic language, that it is a library,
and focused on introspection are probably the key elements here.

Note: Not all these realized yet! Some are hypothetical, possibly even theoretical.

Library

* No special language features required
* No special build or compiler required
* Contracts are just code, can be manipulated programatically with JS
* Can be applied to existing code without changing it (only adding)
* Invisible to calling code, can use inside libraries/modules
* Can be introduced gradually in codebase

Introspection

* Test/code-coverage
* Documentation generation
* Self-documenting
* Automated test-generation
* Self-testing
* Tracing
* (maybe) Quasi-static analysis


## Limitations and Drawbacks

Nothing is perfect. What are they? How to mitigate?

* Requires using a/this library, must be included at runtime.
Mitigation: few dependencies, minimize code size.
* Wraps functions at runtime, using functions for conditions
Mitigation: test, minimize and document performance impact.
Provide best-practices on how to check if this is a problem, and what to do if it is.
* Has/suggests a particular coding style

# Best practices with contracts

For public/external APIs, contracts should be declared in an file external from the implementation.
For instance in a file under ./constracts, then used by files in ./src (implementation) and ./test or ./spec (tests).
This makes sure that changes to publically relied-upon contracts, and get due attention during code review.


# Quasi-static checking

> An approach to static verification in dynamic languages

## Background

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

## Concept

Quasi-static verification is a mix: We execute code (dynamic analysis),
instead of using a compiler/parser. However, the code is written in a way that
allows us to reason about it, without needing external inputs to trigger,
and without causing external effects during the analysis pass.

The following components are needed

1. A way to describe guaranteed and required code properties.
2. A way to load code and properties - without causing side-effects.
3. Tool(s) that reason about whether code is in violation.

Since we're using the host language directly, this is very related to the concept
of an [embedded DSL](http://c2.com/cgi/wiki?EmbeddedDomainSpecificLanguage).

## Agree and quasi-static checking

As a particular implementation of this concept could use

1. Contracts: pre/post-conditions & invariants
2. Promise/function chains, exported on module-level
Would have contracts attached, and the 'body' of the code
be captured but not executed to prevent side-effects.

### Example propagation

* use predicate valid/examples, insert into chain
* verify passing precondition,
* generate new example(s) based on post-condition
* feed into next step

This strategy likely requires that steps are not stateful
(all state must enter through function arguments, exit through return/this).

This assumes that the pre/postconditions of a step/function is well formed.
So for full verification, the step must also be verified.
This could be done through unit testing, local static or dynamic analysis.

If the step is marked as side-effect free (maybe it should be opt-out?),
then we could automatically create unit-tests which ensure that none of
valid pre-condition examples cause post-conditions to fail.

Input data normally used in (unit/behaviour) tests could be good real-life
examples for predicates. Ideally one could declare them one place,
and would be able to act in both capabilities.

### Pairwise coupling

Instead of doing propagation from beginning of a long chain,
try to check the pairs connected together. That is, if data exists
that passes a post-condition of source, but fails pre-condition of target.
If this exists, then is an indicator of broken combination, or wrong pre/post-conditions.
If no examples can be found, no reasoning can be performed, which could
also be considered a failure (at least in stricter modes).

## References

* [Embedded-computing.com: Advanced static analysis meets contract-based programming]
(http://embedded-computing.com/articles/advanced-meets-contract-based-programming/),
explains motivation/concept of combining static analysis and contracts.
* [Contracts as a support to static analysis of open systems]
(http://citeseerx.ist.psu.edu/viewdoc/download?doi=10.1.1.160.8164&rep=rep1&type=pdf)

Related concepts

* [Sagas](http://www.cs.cornell.edu/andru/cs711/2002fa/reading/sagas.pdf)
and [redux-saga](http://yelouafi.github.io/redux-saga/docs/basics/DeclarativeEffects.html),
where instead of performing async operations with some callback at completion, code yields an *Effect*:
An object that describes the async action to perform. The motivation seems to be primarily testability.
Could possibly be used instead of the PromiseChain thing.

# Predicate examples and generative testing

The manually provided examples are good, and neccesary basis,
for being able to generate testcases and to reason about.

However, it is easy to miss some cases this way. Or put alternatively,
it is unreasonably tedious to ensure (up front) that manually written examples covers everything.

    TODO: move fuzz/mutation tools from poly-test out to a dedicated library, that Agree can use?

If doing this well, hopefully get to the point where primarily doing `automated-testing-by-example`.
That is, instead of: setting up a testing framework, writing testcases in imperative code,
somewhere else than the code-under-test, one:
- writes code in a way that describes what is valid & not
- providing a couple of representative examples (some valid, some invalid)
- tools use this information to create & run testcases
- a whole set of testcases is created automatically
- they can be found & ran without any further setup

# Fault injection

Since we know the preconditions, and have in/valid examples, we can use these as basis for
[fault injection](https://en.wikipedia.org/wiki/Fault_injection).

For instance in a msgflo-noflo scenario:
* Agree is used for/inside a NoFlo component
* NoFlo component is used in a (possibly multi-level) NoFlo graph
* The NoFlo graph is exposed as a MsgFlo participant on AMQP

We can pick out functions with Agree contracts at lowest level,
cause a fault there, and then have a test that ensures that
this causes an error to be bubbled all the way up to AMQP.

Can be seen as a kind of [mutation testing](https://en.wikipedia.org/wiki/Mutation_testing),
but where we can make stronger inferences because we know more about
the structure and semantics of the program.

# Composition of code that uses contracts

Ideally any standard JavaScript way of combining the functions/classes using contracts (mostly imperative)
would give all benefits of the contracts, like static verification and test generation.

However this will require very complex [flow-analysis](https://en.wikipedia.org/wiki/Data-flow_analysis),
to determine how values travel through a program, and which values it may take on.
For a dynamic language like JavaScript, the latter is especially hard.

It may be easier if we provide also
a library which guides or enforces best-practices, and maybe support introspection in similar
ways as individual Agree-using functions/classes/instances do. That way, we may be able
to provide the same information

Possible approaches include `higher-order functions`, taking the contracted functions as input.
Typically limited to working with syncronous functions (returning results),
but approach can also work with node.js-style call-continuation-passing (like [Async.js](https://github.com/caolan/async)).
An as special flavor of this, may consider currying-style (like [Ramda](http://ramdajs.com/docs/)).

As a lot of JavaScript code (especially in node.js, but also in browser) is async/deferred,
Promise chains (like [bluebird](http://bluebirdjs.com) or [FlowerFlip](https://github.com/the-grid/Flowerflip))
may be particularly interesting.

Another composition techniques, include dataflow/FBP and finite state machines (see separate sections).

Related

* [Composability in JS using categories](https://medium.com/@homam/composability-from-callbacks-to-categories-in-es6-f3d91e62451e).
Very similar abstraction as Promise, but is instead deferred by default. Also got some notes on relationships to monads.

# Contracts & dataflow/FBP

For projects like [NoFlo](http://noflojs.org) and [MicroFlo](http://microflo.org),
we may want to applying contracts for specifying and verifying dataflow / FBP programming.

Ideally this would allow us to reason about whole (hierarchical) graphs, aided by contracts.

There are a couple different levels one could integrate:

1. On ports. Check conditions against data on inport, and check conditions on data send on outport.
This is basically a type system.
2. In the runtime, for verifying components are generally well-behaved.
3. On individual components. Primarily for ensuring they perform their stated function correctly.

## 1. Contracts on port data

Schema (JSON) and similar conditions are the most relevant here.

## 2. Runtime enforcing contracts on component behavior

For instance, component may declares they are of some kind / has a certain trait,
so that the runtime can know what to expect of the component. Examples may include:

* sync: Sends packets directly upon activation.
* async: Send packets some time after activation.
* generator: Has a port for activating and one for de-activating.
Sends packets at arbitrary times, as long as is active.

May also consider having traits like:

* one-outpacket: Each activation causes one packet to be sent, on a single port.
* one-on-each: Each activation causes one packet to be sent on each (non-error) outport.
* output-or-error: Each activation either causes normal output OR an error, never both.

If the component disobeys any of these constraints, the runtime raises an error.

In general it may be better to avoid most of the potential issues by having an
API which is hard or impossible to misuse. But when the range of 'valid' behavior is
large, this approach may have benefits.
It can help pin-point which component caused a problem instead of only seeing it down the flow,
which massively reduces debugging time.

## 3. Component contracts

For the particular functionality provided by a component,
we need more fine-grained contracts than component traits/types.

The type of contracts most interesting is probably those specifying relations between input and output.
Examples:

* Output value is always a multiple of the input value
* Output value is always higher or lower than input value
* Always sends as many packets as the length of input array

The constracts would checked at runtime, but also be the basis for generating automated tests.

## NoFlo integration

A challenge is that unlike with call-return and call-continuationcall,
it is not apparent when an execution of a component is 'done'.
And with NoFlo 0.5, components can act on packets send in an out-of-order manner,
because it is the components (not the runtime) which queue up data to check whether groups etc match
what is needed to 'fire' / activate.

Right now these state transitions are implicit and unobservable.
This would need to change in order to apply contracts like in 2) or 3).

The contracts conditions would need access to all the data for one activation.
This could be a datastructure like:

```
inputs:
  inport1: [ valueA, ... ]
  inport2: [ valueB, ... ]
outputs:
  out1: [ outValue, ... ]
```
This assumes that sending/receiving order is irrelevant, which is arguably a desirable property anyway.
If this is not feasible, the datastructure could be `inputs: [ port: inport1, data: valueA ]`.

Since NoFlo 0.6 has IP objects which carry the actual values,
it may be that this should be exposed here instead of the raw values.
This would allow verifying things like scoping and groups behavior.

## Using contracted function as component

It may also be interesting to be able to easily create NoFlo components from (especially async),
functions with Agree contracts. Can we and do we want to provide integration tools for this?
Like a NoFlo ComponentLoader or similar...

A tricky part is handling of multiple inputs, can this be done in an automatic way?
If component handles activation strategy, it can collect multiple inputs keyed by the port name.
Promises can only have one input value, so it needs to be objects anyways.

Can we retain the ability to reason about chains of Promises this way, when individual
chains are plugged together by NoFlo graph connections?

## References

* [Contract-based Specification and Verification of Dataflow Programs](http://icetcs.ru.is/nwpt2015/SLIDES/JWiik_NWPT15_presentation.pdf).
Defines concept of `network invariants` and `channel invariants`, and verification strategy both for
individual actors (components) and for networks. "To make the approach usable in practice, channel invariants
should be inferred automatically whenever possible" cited as future work.


# Contracts & finite automata / FSM

For projects like [finito](http://finitosm.org), we may want to apply contracts for specifying & verifying
Finite State Machines.

Ideally this would allow us to reason about whole (hierarchical) machines, aided by the contracts.

References

* [How to prove properties of finite state machines with cccheck]
(http://blogs.msdn.com/b/francesco/archive/2014/09/20/how-to-prove-properties-of-finite-state-machines-with-cccheck.aspx).
References '[lemmas](https://en.wikipedia.org/wiki/Theorem#Terminology)', a theorem-prover concept, as part of their solution.

# Contracts as executable, provable coding style

Mostly `coding style` today is about fairly trivial things like syntax,
including rules around naming, whitespace, blocks etc.
These can to an extent be enforced (or normalized) using modern syntax tools.

However, such tools cannot enforce things beyond syntax. For example:

* Consistent error handling
* Consistent / predictable ordering of arguments
* Consistent handling of options
* Completeness in functionality involving setup/teardown, back/forth, etc..

Possibly this could be done by having a set of contracts,
which all code in a library/module/class obeys?


# User interfaces

As of Jan 2016, most thinking/testing has been on applying to web backend services or small (domain-independent) units.
However, user interfaces, especially in browsers, is an area where JavaScript is even bigger.
In particular, application to functional/reactive styles as popularized by React is worth some consideration.

* Forms/fields. Input validation, whether/how to shown UI elements.
* Model data validation. Both coming from view, and going to view.
* Ensuring that data is shown on screen, possibly in a particular manner.
* Authentication and roles, and their implications on available UI/actions.
* Integration with API/services. Very similar as concerns on backend side, just inverted?

For highly interactive UIs, like in games, availability of actions may depend on particular game states,
which could also be interesting to model as contracts.


# Embedded devices
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

## References

* [C++ standard proposal: Simple contracts for C++](http://www.open-std.org/JTC1/SC22/WG21/docs/papers/2015/n4415.pdf).
Uses the C++11 [generalized attribute](http://www.codesynthesis.com/~boris/blog/2012/04/18/cxx11-generalized-attributes/) mechanism,
contracts to be implemented by compilers.

# Cross-language

Useful when doing polyglot programming,
to be able to model things in the same way.

Most beneficial if one can share tools between different languages:
for documentation, testing, debugging.

Serialize contract to standard .json representation?
All tools operate on this?

# Tools wishlist

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

## Documentation

* Integration with HTTP api docs tools,
like [Blueprint](https://apiblueprint.org/), with [Aglio](https://github.com/danielgtaylor/aglio).
Alternatives include [Swagger](http://swagger.io/) (now Open API Initiative).
[Matic](https://github.com/mattyod/matic) possibly useful for JSON Schema documentation.


# Related

Design-with-contracts / contracts-programming

* [CodeContracts](http://research.microsoft.com/en-us/projects/contracts/), [open source](https://github.com/Microsoft/CodeContracts) contracts for .NET (C# etc).
Has [static checking](http://research.microsoft.com/en-US/projects/contracts/cccheck.pdf) and test-generation capabilities.
[Developer blog](http://blogs.msdn.com/b/francesco/). Interesting feature: `Assume` allows to add (missing) postconditions
to third-party APIs.
* [libhoare.rs](https://github.com/nrc/libhoare), contracts in Rust
* [OpenJML/Java Modelling Language](http://jmlspecs.sourceforge.net/),
combines contracts with [Larch](http://www.eecs.ucf.edu/~leavens/larch-faq.html).
[Design by Contract with JML](http://www.eecs.ucf.edu/~leavens/JML//jmldbc.pdf). [Wikipedia](https://en.wikipedia.org/wiki/Java_Modeling_Language)
* [Plumatic Schema](https://github.com/plumatic/schema), schema-based type validation on functions for Closure(Script).
Interesting connections using schema generators together with property-based / generative testing.

Testing and contracts

* [Enhancing Design by Contract with Know-ledge about Equivalence Partitions](http://www.jot.fm/issues/issue_2004_04/article1.pdf).
Introduces ability to declare partitions for invariants, which a value can belong to.
Then uses a test generator based on the transitions between such partitions.
Also uses an `old` keyword to represent previous value of an instance variable/member, to allow postconditions expressions on it.
* [Testing by Contract - Combining Unit Testing and Design by Contract](http://www.itu.dk/people/kasper/NWPER2002/papers/madsen.pdf),
uses the equivalence partitions implied by preconditions to generate inputs to test.
* [Automatic Testing Based on Design by Contract](http://se.inf.ethz.ch/old/people/ciupa/papers/soqua05.pdf),
tool for fully automated testing for Eiffel by introspection of the code contracts.
* [Seven principles of automated testing, B.Meyer](http://se.ethz.ch/~meyer/publications/testing/principles.pdf). Creator of Design By Contracts and Eiffel.
Definition of a 'Test Oracle', as a piece of code which can automatically. DbC is one way that enables oracles. Property-based-testing is another.
* [](https://arxiv.org/pdf/1512.02102.pdf). Argues for lifting contracts from assertions into (dependent) types.
For instance fully specified types can avoiding needing to take failure into account in signature and implementation, because failing inputs are enforced as impossible by compiler.

Use serialized representation for checking complex types in fail/pass examples. "RgbColor(#aabbcc)"
Very many languages allow to attach custom serializers, and tools which benefit from them. Debuggers etc
Reduces burden on grammar, as any string can be used. Can also be used to hide some examples of equivalence.


JavaScript verification approaches

* [Towards JavaScript Verification with the Dijkstra State Monad](http://research.microsoft.com/en-us/um/people/nswamy/papers/js2fs-dijkstra.pdf)
* [Dependent Types for JavaScript](http://goto.ucsd.edu/~ravi/research/oopsla12-djs.pdf)
* [SymJS: Automatic Symbolic Testing of JavaScript Web Applications](http://www.cs.utah.edu/~ligd/publications/SymJS-FSE14.pdf)
* [Jalangi2: Symbolic execution / dynamic analysis](https://github.com/Samsung/jalangi2)
* [Flow: static type checker for JavaScript](http://flowtype.org/). Gradual typing, manual opt-in annotations


Artificial intelligence

* [STRIPS](https://en.wikipedia.org/wiki/STRIPS)-style planning and answer-set programming, rely on pre- and post-conditions.
See [Programming as planning](http://www.vpri.org/pdf/m2009001_prog_as.pdf) for a recent, integrated example.

Interesting verification approaches

* [Effect typing, inferred types based on their (side)effects](https://research.microsoft.com/en-us/um/people/daan/madoko/doc/koka-effects-2014.html)
* Dependent typing,. Example are Idris and Agda.
* [Extended static checking](https://en.wikipedia.org/wiki/Extended_static_checking). Often using propagations of weakest-precondition / strongest-postcondition from 
[Predicate transformer semantics](https://en.wikipedia.org/wiki/Predicate_transformer_semantics), a sound framework for validating programs.
* Symbolic execution
* [Pex, automatic unit test generation](https://www.microsoft.com/en-us/research/publication/pex-white-box-test-generation-for-net/). Does not require any code annotations

Contracts and embedded systems

* Eiffel, Ada, SPARK
* [Contract Testing for Reliable Embedded Systems](http://archiv.ub.uni-heidelberg.de/volltextserver/15941/1/fajardo_thesis_submit.pdf), uses contracts also for specifying hardware,
including environment, input levels, timing and logic set restrictions. Demonstrates an enforcing implementation of this for I2C devices, using FPGA.
* [Executable Contracts for Incremental Prototypes of Embedded Systems](http://www.sciencedirect.com/science/article/pii/S1571066109001091)
Includes a formal speification for reactive systems, based on step-relations (relations between consecutive changes in program environment),
a component model with input/outputs, contracts composed of assume-guarantee constraints. And a simulation methodology which generates 'traces' (kinda symbolic execution) between such components.

## Relation to theorem provers

Many existing static verification tools translate contracts into a
[SMT problem](https://en.wikipedia.org/wiki/Satisfiability_modulo_theories), using a standard solvers to.
Some of these solver are again based on translating the problem into a
[SAT problem](https://en.wikipedia.org/wiki/Boolean_satisfiability_problem),
though these are often unefficient when applied to software verification.

(possibly) JavaScript-friendly solvers

* [Logictools](https://github.com/tammet/logictools). Standalone JS solver(s), including DPLL SAT solver
* [Boolector, compiled to JS](https://github.com/jgalenson/research.js/tree/master/boolector)
* [MiniSAT, compiled to JS](http://www.msoos.org/2013/09/minisat-in-your-browser/)
* [STP, compiled to JS](https://github.com/stp/stp/issues/191) (seemingly built on MiniSAT)
* [Z3](https://github.com/Z3Prover/z3), could probably be compiled to JS with Emscripten
* [CVC4](https://github.com/CVC4/CVC4), could probably be compiled to JS with Emscripten
* [MiniZinc](https://github.com/MiniZinc/libminizinc), medium-level constraint language with solver. Could probably compile to JS with Emscripten. [Large example list](http://www.hakank.org/minizinc/)
* [google or-tools](https://developers.google.com/optimization/), could probably compile to JS with Emscripten
* [gecode](http://www.gecode.org), has been [compiled to JS with Esmcripten before](http://www.gecode.org/pipermail/users/2015-April/004665.html)
* [backtrack](https://github.com/rf/backtrack), experiemental JavaScript CNF SAT solver
* [condensate](https://github.com/malie/condensate), experiemental JavaScript DPLL SAT solver, with basic CDCL
* [picoSAT](http://fmv.jku.at/picosat/), MIT-like, no-dependencies C code. Should be compilable to JavaScript using Emscripten

Verification languages

* [Boogie](https://github.com/boogie-org/boogie), intermediate verification language, used for C# etc.

Related

* [There are no CNF problems](http://sat2013.cs.helsinki.fi/slides/SAT2013-stuckey.pdf).
Talk about how CNF/SAT has problems compared to medium/high-level modelling approaches for constraint programming.
* [SAT tutorial](http://crest.cs.ucl.ac.uk/readingGroup/satSolvingTutorial-Justyna.pdf).
With focus on Conflict-Driven Clause Learning (CDCL)

## Relation to Hoare logic

Hoare logic 

References

* [A Hoare Logic for Rust](http://ticki.github.io/blog/a-hoare-logic-for-rust/).
Includes an introduction to Hoare logic, applying it for MIR intermediate representation in Rust compiler.

# Ideas

* Online integrated editor, allows to write JS w/Agree, automatically run check/test/doc tools.
Can one build it on one of the code-sharing sites?

# Thoughs by others

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


> Often I hear or read that just few tests covering a large portion of the code is not a valuable thing,
> since few tests contain few assertions and thus, there is a high chance for a bug to remain undetected.
> In other words, some pretend that high test coverage ratio of the code is not so much valuable.
> But if the large portion of the code contains a well-written set of code contracts assertions, the situation is completely different.
> During the few tests execution, tons of assertions (mainly Code Contracts assertions) have been checked.
> In this condition, chances that a bug remains undetected are pretty low.
[](http://codebetter.com/patricksmacchia/2010/07/26/code-contracts-and-automatic-testing-are-pretty-much-the-same-thing)

