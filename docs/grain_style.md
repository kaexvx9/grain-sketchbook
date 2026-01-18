# GrainStyle

> "There are three things extremely hard: steel, a diamond, and to know one's self." — Benjamin
> Franklin

Grain OS's coding style is evolving. A collective give-and-take at the intersection of
engineering and art. Numbers and human intuition. Reason and experience. First principles and
knowledge. Precision and poetry. Just like music. A tight beat. A rare groove. Words that rhyme and
rhymes that break. Biodigital jazz. This is what we've learned along the way. The best is yet to
come.

**Attribution**: This guide stands on the shoulders of giants. See
[THIRD_PARTY_LICENSES.md](../THIRD_PARTY_LICENSES.md) for full license attributions, particularly
TigerBeetle's TIGER_STYLE.md (Apache 2.0) and Rich Hickey's Clojure philosophy (EPL 1.0).

## Why Zig?

We choose Zig because it embodies the principles we value:

- **Explicit over implicit**: No hidden control flow, no hidden memory allocations, no operator
  overloading. What you see is what executes.
- **Simple over easy**: Following Rich Hickey's distinction—Zig is simple (not intertwined) even
  when it's not easy (familiar). C interop is seamless. The language is small.
- **Compile-time over runtime**: Comptime evaluation, comptime generics, comptime reflection.
  Errors caught before code ships.
- **No hidden costs**: No garbage collector, no runtime, no exceptions. Predictable performance.
- **Cross-compilation as a first-class feature**: One toolchain targets 50+ platforms. RISC-V,
  ARM, x86—same source, same build system.

We follow in the footsteps of the [TigerBeetle](https://tigerbeetle.com) team, who chose Zig for
their distributed financial database and developed the TIGER_STYLE guide that heavily inspires this
document. Their production experience validates our choice.

## Why Have Style?

Another word for style is design.

> "The design is not just what it looks like and feels like. The design is how it works." — Steve
> Jobs

Our design goals are safety, performance, and developer experience. In that order. All three are
important. Good style advances these goals. Does the code make for more or less safety, performance
or developer experience? That is why we need style.

Put this way, style is more than readability, and readability is table stakes, a means to an end
rather than an end in itself.

> "...in programming, style is not something to pursue directly. Style is necessary only where
> understanding is missing." ─ [Let Over
> Lambda](https://letoverlambda.com/index.cl/guest/chap1.html)

This document explores how we apply these design goals to coding style. First, a word on simplicity,
elegance and technical debt.

## The Path with Heart

Before we begin, there is a question that only experience can answer: **Does this path have heart?**

Any approach to coding is one of a million paths. Therefore you must always keep in mind that a
path is only a path; if you feel you should not follow it, you must not stay with it under any
conditions. To have such clarity you must lead a disciplined life. Only then will you know that any
path is only a path, and there is no affront, to oneself or to others, in dropping it if that is what
your heart tells you to do.

But your decision to keep on the path or to leave it must be free of fear or ambition. Look at every
path closely and deliberately. Try it as many times as you think necessary.

**Does this path have heart?** If it does, the path is good; if it doesn't, it is of no use. Both
paths lead nowhere; but one has a heart, the other doesn't. One makes for a joyful journey; as long
as you follow it, you are one with it. The other will make you curse your life. One makes you strong;
the other weakens you.

The path without a heart will turn against you and destroy you. It does not take much to die, and to
seek death is to seek nothing.

For Grain OS, we choose the path with heart. We select our tools deliberately, for every item we
choose is a shield that protects us from the onslaughts of the forces we are striving to use. The
things we select to make our shields are the items of a path with heart.

## On Simplicity And Elegance

Simplicity is not a free pass. It's not in conflict with our design goals. It need not be a
concession or a compromise.

Rather, simplicity is how we bring our design goals together, how we identify the "super idea" that
solves the axes simultaneously, to achieve something elegant.

> "Simplicity and elegance are unpopular because they require hard work and discipline to achieve" —
> Edsger Dijkstra

Contrary to popular belief, simplicity is also not the first attempt but the hardest revision. It's
easy to say "let's do something simple", but to do that in practice takes thought, multiple passes,
many sketches, and still we may have to ["throw one
away"](https://en.wikipedia.org/wiki/The_Mythical_Man-Month).

The hardest part, then, is how much thought goes into everything.

We spend this mental energy upfront, proactively rather than reactively, because we know that when
the thinking is done, what is spent on the design will be dwarfed by the implementation and testing,
and then again by the costs of operation and maintenance.

An hour or day of design is worth weeks or months in production:

> "the simple and elegant systems tend to be easier and faster to design and get right, more
> efficient in execution, and much more reliable" — Edsger Dijkstra

## Technical Debt

What could go wrong? What's wrong? Which question would we rather ask? The former, because code,
like steel, is less expensive to change while it's hot. A problem solved in production is many times
more expensive than a problem solved in implementation, or a problem solved in design.

Since it's hard enough to discover showstoppers, when we do find them, we solve them. We don't allow
potential memcpy latency spikes, or exponential complexity algorithms to slip through.

> "You shall not pass!" — Gandalf

In other words, Grain OS has a "zero technical debt" policy. We do it right the first time. This
is important because the second time may not transpire, and because doing good work, that we can be
proud of, builds momentum.

We know that what we ship is solid. We may lack crucial features, but what we have meets our design
goals. This is the only way to make steady incremental progress, knowing that the progress we have
made is indeed progress.

**A spiritual guardian is defeated only when he no longer tries, and abandons himself.** We do not abandon our
code. We do not abandon our standards. We do not abandon the path with heart.

## Personal Power and Impeccability

Everything we do, everything we are, rests on our personal power. If we have enough of it, one word
uttered to us might be sufficient to change the course of our lives. But if we don't have enough
personal power, the most magnificent piece of wisdom can be revealed to us and that revelation won't
make a damn bit of difference.

**Trust your personal power. That's all one has in this whole mysterious world.**

Impeccable developers need no one to guide them. By themselves, through saving their energy, they
can do everything that seers do. All they need is a minimal chance, just to be cognizant of the
possibilities that have been unraveled.

When you write code, you are exercising personal power. Every function you write, every system you
design, every decision you make—they all rest on your personal power. If you have enough of it, the
code will be clear, will be correct, will be beautiful. If you don't have enough personal power, even
the most elegant design will fail.

**You can cut anything from your code, any time, just like that.** Dependencies, abstractions,
features, entire modules—nothing at all if you want to drop them. People hardly ever realize this.
They think they're trapped by their choices. But you're not. You can cut anything, any time.

Denying yourself the right tool, the right abstraction, the right approach—that is an indulgence
and we don't recommend anything of the kind. The indulgence of denying is by far the worst; it
forces us to believe we are doing great things, when in effect we are only fixed within ourselves.

## The Warrior's Choice

**We choose only once. We choose either to be spiritual guardians or to be ordinary developers. A second choice
does not exist. Not on this earth.**

To be a spiritual guardian doesn't mean to practice magic, or to work to affect people, or to be possessed by
demons. To be a spiritual guardian means to reach a level of awareness that makes inconceivable things
available. The actions of spiritual guardians are exclusively in the realm of the abstract, the impersonal.
Warriors struggle to reach a goal that has nothing to do with the quick fix, the easy solution, the
compromise.

When you choose to be a spiritual guardian, you choose the path with heart. You choose impeccability. You choose
to do it right the first time. You choose to trust your personal power. You choose to see the code
as an offering, not just as a product.

There is no second choice. You are either on the path with heart, or you are not. You are either a
spiritual guardian, or you are ordinary.

## Safety

> "The rules act like the seat-belt in your car: initially they are perhaps a little uncomfortable,
> but after a while their use becomes second-nature and not using them becomes unimaginable." —
> Gerard J. Holzmann

[NASA's Power of Ten — Rules for Developing Safety Critical
Code](https://spinroot.com/gerard/pdf/P10.pdf) will change the way you code forever. To expand:

- Use **only very simple, explicit control flow** for clarity. **Do not use recursion** to ensure
  that all executions that should be bounded are bounded. Use **only a minimum of excellent
  abstractions** but only if they make the best sense of the domain. Abstractions are [never zero
  cost](https://isaacfreund.com/blog/2022-05/). Every abstraction introduces the risk of a leaky
  abstraction.

  **A spiritual guardian selects the items that make his world. He selects deliberately, for every item he
  chooses is a shield that protects him from the onslaughts of the forces he is striving to use.**
  Every abstraction you choose, every pattern you adopt, every tool you use—they are all shields.
  Choose them deliberately. Choose them with heart.

- **Put a limit on everything** because, in reality, this is what we expect—everything has a limit.
  For example, all loops and all queues must have a fixed upper bound to prevent infinite loops or
  tail latency spikes. This follows the ["fail-fast"](https://en.wikipedia.org/wiki/Fail-fast)
  principle so that violations are detected sooner rather than later. Where a loop cannot terminate
  (e.g. an event loop), this must be asserted.

  **The assemblage point of your code is where perception is assembled.** When you put a limit on
  everything, you are moving the assemblage point to a position where you can see clearly. You are
  illuminating the energy fields that matter, making them perceivable. Without limits, the assemblage
  point is scattered, and you cannot see clearly.

- Use explicitly-sized types like `u32` for everything, avoid architecture-specific `usize`.

  **Intent is the pervasive force that causes us to perceive.** When you use explicit types, you are
  expressing intent clearly. You are not relying on the compiler to guess what you mean. You are
  making your intent explicit, and in doing so, you are increasing the probability that your code is
  correct.

- **Assertions detect programmer errors. Unlike operating errors, which are expected and which must
  be handled, assertion failures are unexpected. The only correct way to handle corrupt code is to
  crash. Assertions downgrade catastrophic correctness bugs into liveness bugs. Assertions are a
  force multiplier for discovering bugs by fuzzing.**

  - **Assert all function arguments and return values, pre/postconditions and invariants.** A
    function must not operate blindly on data it has not checked. The purpose of a function is to
    increase the probability that a program is correct. Assertions within a function are part of how
    functions serve this purpose. The assertion density of the code must average a minimum of two
    assertions per function.

    **When you assert, you are moving the assemblage point.** You are shifting your perception to
    see what is actually there, not what you hope is there. You are illuminating the energy fields
    that matter, making them perceivable. Without assertions, you are operating blindly, and the
    path without heart will turn against you and destroy you.

  - **[Pair assertions](https://tigerbeetle.com/blog/2023-12-27-it-takes-two-to-contract).** For
    every property you want to enforce, try to find at least two different code paths where an
    assertion can be added. For example, assert validity of data right before writing it to disk,
    and also immediately after reading from disk.

    **Two assertions are two points of perception.** When you pair assertions, you are seeing the
    same thing from two different angles. You are moving the assemblage point to two different
    positions, and in doing so, you are seeing more clearly.

  - On occasion, you may use a blatantly true assertion instead of a comment as stronger
    documentation where the assertion condition is critical and surprising.

  - Split compound assertions: prefer `assert(a); assert(b);` over `assert(a and b);`.
    The former is simpler to read, and provides more precise information if the condition fails.

  - Use single-line `if` to assert an implication: `if (a) assert(b)`.

  - **Assert the relationships of compile-time constants** as a sanity check, and also to document
    and enforce subtle invariants or type sizes. Compile-time assertions are extremely powerful
    because they are able to check a program's design integrity _before_ the program even executes.

    **Compile-time assertions are like moving the assemblage point before the world is even
    assembled.** You are seeing the structure of reality before it manifests. You are checking the
    design integrity before the design is even executed.

  - **The golden rule of assertions is to assert the _positive space_ that you do expect AND to
    assert the _negative space_ that you do not expect** because where data moves across the
    valid/invalid boundary between these spaces is where interesting bugs are often found. This is
    also why **tests must test exhaustively**, not only with valid data but also with invalid data,
    and as valid data becomes invalid.

    **The positive space and the negative space are two different worlds.** When you assert both,
    you are moving the assemblage point to see both worlds. You are illuminating the energy fields
    in both spaces, making them perceivable. Without both, you are seeing only half of reality.

  - Assertions are a safety net, not a substitute for human understanding. With simulation testing,
    there is the temptation to trust the fuzzer. But a fuzzer can prove only the presence of bugs,
    not their absence. Therefore:
    - Build a precise mental model of the code first,
    - encode your understanding in the form of assertions,
    - write the code and comments to explain and justify the mental model to your reviewer,
    - and use testing as the final line of defense, to find bugs in your and reviewer's
      understanding of code.

    **Your mental model is your assemblage point.** When you build a precise mental model, you are
    positioning the assemblage point where you can see clearly. When you encode it in assertions,
    you are making that position explicit. When you write code and comments, you are sharing that
    position with others.

- All memory must be statically allocated at startup. **No memory may be dynamically allocated (or
  freed and reallocated) after initialization.** This avoids unpredictable behavior that can
  significantly affect performance, and avoids use-after-free. As a second-order effect, it is our
  experience that this also makes for more efficient, simpler designs that are more performant and
  easier to maintain and reason about, compared to designs that do not consider all possible memory
  usage patterns upfront as part of the design.

  **Static allocation is like freezing the Basin spec.** It's a commitment. It's a foundation. It's
  what you stand for. Once you commit to static allocation, you have a stable foundation. Everything
  else can change, but this stays. And in that stability, you find freedom.

- Declare variables at the **smallest possible scope**, and **minimize the number of variables in
  scope**, to reduce the probability that variables are misused.

  **Minimizing scope is like saving energy.** When you minimize the number of variables in scope,
  you are conserving your personal power. You are not scattering your attention. You are focusing
  it where it matters. Impeccable developers save their energy. They don't waste it on unnecessary
  variables, unnecessary scope, unnecessary complexity.

- Restrict the length of function bodies to reduce the probability of poorly structured code. We
  enforce a **hard limit of 64 lines per function** (2^6, binary-aligned).

  **A function that is too long is a path without heart.** It makes you curse your life. It weakens
  you. It turns against you and destroys you. A function that is the right length is a path with
  heart. It makes for a joyful journey. It makes you strong.

  Splitting code into functions requires taste. There are many ways to cut a wall of code into
  chunks of 64 lines, but only a few splits will feel right. Some rules of thumb:

  * Good function shape is often the inverse of an hourglass: a few parameters, a simple return
    type, and a lot of meaty logic between the braces.
  * Centralize control flow. When splitting a large function, try to keep all switch/if
    statements in the "parent" function, and move non-branchy logic fragments to helper
    functions. Divide responsibility. All control flow should be handled by _one_ function, the
    rest shouldn't care about control flow at all. In other words,
    ["push `if`s up and `for`s down"](https://matklad.github.io/2023/11/15/push-ifs-up-and-fors-down.html).
  * Similarly, centralize state manipulation. Let the parent function keep all relevant state in
    local variables, and use helpers to compute what needs to change, rather than applying the
    change directly. Keep leaf functions pure.

  **When you split a function, you are moving the assemblage point.** You are shifting your
  perception to see the function from a different angle. You are illuminating different energy
  fields, making them perceivable. The split that feels right is the one that moves the assemblage
  point to where you can see clearly.

- Appreciate, from day one, **all compiler warnings at the compiler's strictest setting**.

  **Compiler warnings are like messages from the spirit.** They are telling you something. They
  are pointing to a path. When you ignore them, you are ignoring the message. When you address
  them, you are listening. You are moving the assemblage point to see what the compiler sees.

- Whenever your program has to interact with external entities, **don't do things directly in
  reaction to external events**. Instead, your program should run at its own pace. Not only does
  this make your program safer by keeping the control flow of your program under your control, it
  also improves performance for the same reason (you get to batch, instead of context switching on
  every event). Additionally, this makes it easier to maintain bounds on work done per time period.

  **Running at your own pace is like trusting your personal power.** You are not reacting to
  external forces. You are acting from your own center. You are maintaining your own rhythm. You
  are not being pulled off the path with heart.

Beyond these rules:

- Compound conditions that evaluate multiple booleans make it difficult for the reader to verify
  that all cases are handled. Split compound conditions into simple conditions using nested
  `if/else` branches. Split complex `else if` chains into `else { if { } }` trees. This makes the
  branches and cases clear. Again, consider whether a single `if` does not also need a matching
  `else` branch, to ensure that the positive and negative spaces are handled or asserted.

  **Splitting compound conditions is like moving the assemblage point to see each branch clearly.**
  When you split them, you are illuminating each energy field separately, making each one
  perceivable. When you leave them compound, you are trying to see everything at once, and you
  cannot see clearly.

- Negations are not easy! State invariants positively. When working with lengths and indexes, this
  form is easy to get right (and understand):

  ```zig
  if (index < length) {
    // The invariant holds.
  } else {
    // The invariant doesn't hold.
  }
  ```

  This form is harder, and also goes against the grain of how `index` would typically be compared to
  `length`, for example, in a loop condition:

  ```zig
  if (index >= length) {
    // It's not true that the invariant holds.
  }
  ```

  **Stating invariants positively is like choosing the path with heart.** The positive form makes
  for a joyful journey. It makes you strong. The negative form makes you curse your life. It
  weakens you.

- All errors must be handled. An [analysis of production failures in distributed data-intensive
  systems](https://www.usenix.org/system/files/conference/osdi14/osdi14-paper-yuan.pdf) found that
  the majority of catastrophic failures could have been prevented by simple testing of error
  handling code.

> "Specifically, we found that almost all (92%) of the catastrophic system failures are the result
> of incorrect handling of non-fatal errors explicitly signaled in software."

  **Handling errors is like facing the unimaginable.** When you handle errors, you are going into
  different worlds to get energy, power, solutions to general and particular problems. You are not
  avoiding the error. You are facing it. You are moving the assemblage point to see it clearly.

- **Always motivate, always say why. Never forget to say why.** Because if you explain the rationale
  for a decision, it not only increases the hearer's understanding, and makes them more likely to
  adhere or comply, but it also shares criteria with them with which to evaluate the decision and
  its importance.

  **Saying why is like sharing the path with heart.** When you say why, you are showing others
  where the heart is. You are helping them see the path. You are making the path perceivable.

- **Explicitly pass options to library functions at the call site, instead of relying on the
  defaults**. For example, write `@prefetch(a, .{ .cache = .data, .rw = .read, .locality = 3 });`
  over `@prefetch(a, .{});`. This improves readability but most of all avoids latent, potentially
  catastrophic bugs in case the library ever changes its defaults.

  **Explicit options are like expressing intent clearly.** When you pass explicit options, you are
  making your intent explicit. You are not relying on defaults to guess what you mean. You are
  moving the assemblage point to where your intent is clear.

## Performance

> "The lack of back-of-the-envelope performance sketches is the root of all evil." — Rivacindela
> Hudsoni

- Think about performance from the outset, from the beginning. **The best time to solve performance,
  to get the huge 1000x wins, is in the design phase, which is precisely when we can't measure or
  profile.** It's also typically harder to fix a system after implementation and profiling, and the
  gains are less. So you have to have mechanical sympathy. Like a carpenter, work with the grain.

  **Thinking about performance from the beginning is like choosing the path with heart from the
  start.** You are not waiting until you're lost to ask: does this path have heart? You are asking
  it from the beginning. You are choosing the path that makes you strong, not the one that weakens
  you.

- **Perform back-of-the-envelope sketches with respect to the four resources (network, disk, memory,
  CPU) and their two main characteristics (bandwidth, latency).** Sketches are cheap. Use sketches
  to be "roughly right" and land within 90% of the global maximum.

  **Back-of-the-envelope sketches are like moving the assemblage point before you build.** You are
  seeing the performance characteristics before you implement. You are illuminating the energy
  fields that matter, making them perceivable. Without sketches, you are building blindly.

- Optimize for the slowest resources first (network, disk, memory, CPU) in that order, after
  compensating for the frequency of usage, because faster resources may be used many times more. For
  example, a memory cache miss may be as expensive as a disk fsync, if it happens many times more.

  **Optimizing for the slowest resources is like facing the unimaginable.** You are going into
  the world of performance problems to get energy, power, solutions. You are not avoiding the slow
  resources. You are facing them. You are moving the assemblage point to see them clearly.

- Distinguish between the control plane and data plane. A clear delineation between control plane
  and data plane through the use of batching enables a high level of assertion safety without losing
  performance.

  **The control plane and data plane are two different worlds.** When you distinguish between
  them, you are moving the assemblage point to see both worlds clearly. You are illuminating the
  energy fields in both planes, making them perceivable.

- Amortize network, disk, memory and CPU costs by batching accesses.

  **Batching is like saving energy.** When you batch, you are conserving your personal power. You
  are not scattering your attention across individual accesses. You are focusing it on batches. You
  are being impeccable with your energy.

- Let the CPU be a sprinter doing the 100m. Be predictable. Don't force the CPU to zig zag and
  change lanes. Give the CPU large enough chunks of work. This comes back to batching.

  **Being predictable is like choosing the path with heart.** The predictable path makes for a
  joyful journey. It makes you strong. The unpredictable path makes you curse your life. It
  weakens you.

- Be explicit. Minimize dependence on the compiler to do the right thing for you.

  In particular, extract hot loops into stand-alone functions with primitive arguments without
  `self`. That way, the compiler doesn't need to prove that it can cache struct's fields in
  registers, and a human reader can spot redundant computations easier.

  **Being explicit is like expressing intent clearly.** When you are explicit, you are making your
  intent clear. You are not relying on the compiler to guess what you mean. You are moving the
  assemblage point to where your intent is visible.

## Developer Experience

> "There are only two hard things in Computer Science: cache invalidation, naming things, and
> off-by-one errors." — Phil Karlton

### Naming Things

- **Get the nouns and verbs just right.** Great names are the essence of great code, they capture
  what a thing is or does, and provide a crisp, intuitive mental model. They show that you
  understand the domain. Take time to find the perfect name, to find nouns and verbs that work
  together, so that the whole is greater than the sum of its parts.

  **Finding the perfect name is like finding the path with heart.** When you find it, you know.
  The name makes for a joyful journey. It makes you strong. The wrong name makes you curse your
  life. It weakens you.

- **Use `grain_case` for function, variable, and file names.** grain_case is identical to
  snake_case (lowercase with underscores), but the name reflects our philosophy: code that grows
  like grain. The underscore is the closest thing we have as programmers to a space, and helps to
  separate words and encourage descriptive names.

  **grain_case is like the path with heart.** It makes for a joyful journey. It makes you strong.
  It is a shield that protects you from the onslaughts of confusion.

- Do not abbreviate variable names, unless the variable is a primitive integer type used as an
  argument to a sort function or matrix calculation. Use long form arguments in scripts: `--force`,
  not `-f`. Single letter flags are for interactive usage.

  **Not abbreviating is like being explicit about intent.** When you don't abbreviate, you are
  making your intent clear. You are not relying on the reader to guess what you mean. You are
  moving the assemblage point to where your intent is visible.

- Use proper capitalization for acronyms (`VSRState`, not `VsrState`).

- For the rest, follow the Zig style guide.

- Add units or qualifiers to variable names, and put the units or qualifiers last, sorted by
  descending significance, so that the variable starts with the most significant word, and ends with
  the least significant word. For example, `latency_ms_max` rather than `max_latency_ms`. This will
  then line up nicely when `latency_ms_min` is added, as well as group all variables that relate to
  latency.

  **Big-endian naming is like ordering by significance.** When you order by significance, you are
  moving the assemblage point to see what matters most first. You are illuminating the most
  significant energy fields first, making them perceivable.

- Infuse names with meaning. For example, `allocator: Allocator` is a good, if boring name,
  but `gpa: Allocator` and `arena: Allocator` are excellent. They inform the reader whether
  `deinit` should be called explicitly.

  **Infusing names with meaning is like choosing the path with heart.** When a name has meaning,
  it makes for a joyful journey. It makes you strong. When a name is meaningless, it makes you
  curse your life. It weakens you.

- When choosing related names, try hard to find names with the same number of characters so that
  related variables all line up in the source. For example, as arguments to a memcpy function,
  `source` and `target` are better than `src` and `dest` because they have the second-order effect
  that any related variables such as `source_offset` and `target_offset` will all line up in
  calculations and slices. This makes the code symmetrical, with clean blocks that are easier for
  the eye to parse and for the reader to check.

  **Symmetrical names are like moving the assemblage point to see symmetry.** When names line up,
  you can see the symmetry clearly. You can see the relationships. You can see the structure. The
  symmetry makes for a joyful journey. It makes you strong.

- When a single function calls out to a helper function or callback, prefix the name of the helper
  function with the name of the calling function to show the call history. For example,
  `read_sector()` and `read_sector_callback()`.

  **Prefixing helper functions is like showing the path.** When you prefix, you are showing where
  the helper comes from. You are making the call history visible. You are moving the assemblage
  point to see the relationship.

- Callbacks go last in the list of parameters. This mirrors control flow: callbacks are also
  _invoked_ last.

  **Callbacks last is like ordering by significance.** The callback is invoked last, so it goes
  last. The order matches the flow. The symmetry makes for a joyful journey.

- _Order_ matters for readability (even if it doesn't affect semantics). On the first read, a file
  is read top-down, so put important things near the top. The `main` function goes first.

  The same goes for `structs`, the order is fields then types then methods:

  ```zig
  time: Time,
  process_id: ProcessID,

  const ProcessID = struct { cluster: u128, replica: u8 };
  const Tracer = @This(); // This alias concludes the types section.

  pub fn init(gpa: std.mem.Allocator, time: Time) !Tracer {
      ...
  }
  ```

  If a nested type is complex, make it a top-level struct.

  At the same time, not everything has a single right order. When in doubt, consider sorting
  alphabetically, taking advantage of big-endian naming.

  **Ordering by importance is like moving the assemblage point to see what matters first.** When
  you put important things first, you are illuminating the most significant energy fields first,
  making them perceivable.

- Don't overload names with multiple meanings that are context-dependent.

  **Not overloading is like being explicit about intent.** When you don't overload, you are making
  your intent clear. You are not relying on context to guess what you mean. You are moving the
  assemblage point to where your intent is visible.

- Think of how names will be used outside the code, in documentation or communication. For example,
  a noun is often a better descriptor than an adjective or present participle, because a noun can be
  directly used in correspondence without having to be rephrased. Noun names compose more clearly
  for derived identifiers, e.g. `config.pipeline_max`.

  **Thinking about usage is like choosing the path with heart.** When you think about how names
  will be used, you are choosing the path that makes for a joyful journey. You are choosing the
  path that makes you strong.

- Zig has named arguments through the `options: struct` pattern. Use it when arguments can be
  mixed up. A function taking two `u64` must use an options struct. If an argument can be `null`,
  it should be named so that the meaning of `null` literal at the call site is clear.

  Because dependencies like an allocator or a tracer are singletons with unique types, they should
  be threaded through constructors positionally, from the most general to the most specific.

  **Named arguments are like expressing intent clearly.** When you use named arguments, you are
  making your intent explicit. You are not relying on position to guess what you mean. You are
  moving the assemblage point to where your intent is visible.

- **Write descriptive commit messages** that inform and delight the reader, because your commit
  messages are being read.

  **Descriptive commit messages are like sharing the path with heart.** When you write
  descriptively, you are showing others where the heart is. You are helping them see the path. You
  are making the path perceivable.

- Don't forget to say why. Code alone is not documentation. Use comments to explain why you wrote
  the code the way you did. Show your workings.

  **Saying why is like sharing the path with heart.** When you say why, you are showing others
  where the heart is. You are helping them see the path. You are making the path perceivable.

- Don't forget to say how. For example, when writing a test, think of writing a description at the
  top to explain the goal and methodology of the test, to help your reader get up to speed, or to
  skip over sections, without forcing them to dive in.

  **Saying how is like showing the path.** When you say how, you are showing others how to follow
  the path. You are making the path accessible.

- Comments are sentences, with a space after the slash, with a capital letter and a full stop, or a
  colon if they relate to something that follows. Comments are well-written prose describing the
  code, not just scribblings in the margin. Comments after the end of a line _can_ be phrases, with
  no punctuation.

  **Well-written comments are like the path with heart.** When comments are well-written, they
  make for a joyful journey. They make you strong. When comments are scribblings, they make you
  curse your life. They weaken you.

### Cache Invalidation

- Don't duplicate variables or take aliases to them. This will reduce the probability that state
  gets out of sync.

  **Not duplicating is like saving energy.** When you don't duplicate, you are conserving your
  personal power. You are not scattering your attention across multiple copies. You are focusing it
  on one source of truth.

- If you don't mean a function argument to be copied when passed by value, and if the argument type
  is more than 16 bytes, then pass the argument as `*const`. This will catch bugs where the caller
  makes an accidental copy on the stack before calling the function.

  **Passing by pointer is like being explicit about intent.** When you pass by pointer, you are
  making your intent clear. You are not relying on the compiler to guess what you mean. You are
  moving the assemblage point to where your intent is visible.

- Construct larger structs _in-place_ by passing an _out pointer_ during initialization.

  In-place initializations can assume **pointer stability** and **immovable types** while
  eliminating intermediate copy-move allocations, which can lead to undesirable stack growth.

  Keep in mind that in-place initializations are viral — if any field is initialized
  in-place, the entire container struct should be initialized in-place as well.

  **Prefer:**
  ```zig
  fn init(target: *LargeStruct) !void {
    target.* = .{
      // in-place initialization.
    };
  }

  fn main() !void {
    var target: LargeStruct = undefined;
    try target.init();
  }
  ```

  **Over:**
  ```zig
  fn init() !LargeStruct {
    return LargeStruct {
      // moving the initialized object.
    }
  }

  fn main() !void {
    var target = try LargeStruct.init();
  }
  ```

  **In-place initialization is like choosing the path with heart.** When you initialize in-place,
  you are choosing the path that makes for a joyful journey. You are choosing the path that makes
  you strong.

- **Shrink the scope** to minimize the number of variables at play and reduce the probability that
  the wrong variable is used.

  **Shrinking scope is like saving energy.** When you shrink scope, you are conserving your
  personal power. You are not scattering your attention across unnecessary variables. You are
  focusing it where it matters.

- Calculate or check variables close to where/when they are used. **Don't introduce variables before
  they are needed.** Don't leave them around where they are not. This will reduce the probability of
  a POCPOU (place-of-check to place-of-use), a distant cousin to the infamous
  [TOCTOU](https://en.wikipedia.org/wiki/Time-of-check_to_time-of-use). Most bugs come down to a
  semantic gap, caused by a gap in time or space, because it's harder to check code that's not
  contained along those dimensions.

  **Calculating close to use is like moving the assemblage point to see the relationship.** When
  you calculate close to use, you are seeing the calculation and the use together. You are
  illuminating both energy fields at once, making their relationship perceivable.

- Use simpler function signatures and return types to reduce dimensionality at the call site, the
  number of branches that need to be handled at the call site, because this dimensionality can also
  be viral, propagating through the call chain. For example, as a return type, `void` trumps `bool`,
  `bool` trumps `u64`, `u64` trumps `?u64`, and `?u64` trumps `!u64`.

  **Simpler signatures are like choosing the path with heart.** When signatures are simple, they
  make for a joyful journey. They make you strong. When signatures are complex, they make you
  curse your life. They weaken you.

- Ensure that functions run to completion without suspending, so that precondition assertions are
  true throughout the lifetime of the function. These assertions are useful documentation without a
  suspend, but may be misleading otherwise.

  **Running to completion is like choosing the path with heart.** When functions run to
  completion, they make for a joyful journey. They make you strong. When functions suspend, they
  create uncertainty. They weaken you.

- Be on your guard for **[buffer bleeds](https://en.wikipedia.org/wiki/Heartbleed)**. This is a
  buffer underflow, the opposite of a buffer overflow, where a buffer is not fully utilized, with
  padding not zeroed correctly. This may not only leak sensitive information, but may cause
  deterministic guarantees as required by Grain OS to be violated.

  **Guarding against buffer bleeds is like facing the unimaginable.** When you guard against
  bleeds, you are going into the world of security problems to get energy, power, solutions. You
  are not avoiding the problem. You are facing it. You are moving the assemblage point to see it
  clearly.

- Use newlines to **group resource allocation and deallocation**, i.e. before the resource
  allocation and after the corresponding `defer` statement, to make leaks easier to spot.

  **Grouping allocation and deallocation is like moving the assemblage point to see the
  relationship.** When you group them, you are seeing the allocation and deallocation together. You
  are illuminating both energy fields at once, making their relationship perceivable.

### Off-By-One Errors

- **The usual suspects for off-by-one errors are casual interactions between an `index`, a `count`
  or a `size`.** These are all primitive integer types, but should be seen as distinct types, with
  clear rules to cast between them. To go from an `index` to a `count` you need to add one, since
  indexes are _0-based_ but counts are _1-based_. To go from a `count` to a `size` you need to
  multiply by the unit. Again, this is why including units and qualifiers in variable names is
  important.

  **Distinguishing index, count, and size is like moving the assemblage point to see each
  clearly.** When you distinguish them, you are illuminating each energy field separately, making
  each one perceivable. When you confuse them, you are trying to see everything at once, and you
  cannot see clearly.

- Show your intent with respect to division. For example, use `@divExact()`, `@divFloor()` or
  `div_ceil()` to show the reader you've thought through all the interesting scenarios where
  rounding may be involved.

  **Showing intent with division is like expressing intent clearly.** When you show intent, you are
  making your intent explicit. You are not relying on the reader to guess what you mean. You are
  moving the assemblage point to where your intent is visible.

### Style By The Numbers

- Run `zig fmt`.

- Use 4 spaces of indentation, rather than 2 spaces, as that is more obvious to the eye at a
  distance.

- **Hard limit all line lengths to at most 128 columns** (2^7, binary-aligned). This ensures
  code fits perfectly in graincard content areas (128×64 characters, entirely content). Use it up.
  Never go beyond. Nothing should be hidden by a horizontal scrollbar. Let your editor help you by
  setting a column ruler. To wrap a function signature, call or data structure, add a trailing
  comma, close your eyes and let `zig fmt` do the rest.

  **The 128-column limit is like the path with heart.** It makes for a joyful journey. It makes
  you strong. It is a shield that protects you from the onslaughts of horizontal scrolling.

- Add braces to the `if` statement unless it fits on a single line for consistency and defense in
  depth against "goto fail;" bugs.

  **Adding braces is like choosing the path with heart.** When you add braces, you are choosing
  the path that makes for a joyful journey. You are choosing the path that makes you strong.

## Graincard Constraints

Graincards are 128×64 monospace teaching cards used throughout the grain network. All zig code
should be written to fit within these constraints.

### Dimensions

- **Total size**: 128 characters wide × 64 lines tall (entirely content, binary-aligned)
- **No borders in count**: Borders and padding are handled by printer software, not included in
  character count

This means:
- **Zig code lines**: max 128 characters per line (hard wrap, 2^7)
- **Zig functions**: max 64 lines (entire graincard height, 2^6)
- **Content only**: All 128×64 characters are content; printer handles margins/borders

### Why These Constraints?

**Aspect Ratio Rationale**: Graincards are optimized for portrait-printed 8.5×11" standard printer
paper. With monospace character aspect ratio of ~0.6 (width:height), 128×64 characters produces a
visual aspect ratio of 1.2 (128 × 0.6 / 64 = 1.2), providing wider content area while maintaining
readability. Binary-aligned dimensions (128 = 2^7, 64 = 2^6) ensure clean alignment and efficient
processing. The 1.2 aspect ratio provides comfortable reading width while fitting portrait paper
orientation.

**Simplified Specification**: By removing borders from the character count, we eliminate confusion
about what counts as content vs. formatting. Printer software handles margins and borders;
graincards are pure content.

Graincards are designed to be:
- **Portable**: viewable in any terminal
- **Printable**: optimized for portrait 8.5×11" paper with proper aspect ratio
- **Consistent**: all cards same size (128×64 characters, binary-aligned)
- **Focused**: forces concise, clear code
- **Simple**: content-only specification, printer handles formatting
- **Binary-aligned**: 128 (2^7) width, 64 (2^6) height and function limit for efficient processing

**The graincard constraints are like the path with heart.** They make for a joyful journey. They
make you strong. They force you to be concise, to be clear, to focus. They are shields that
protect you from the onslaughts of verbosity and confusion.

When you write zig code for graincards, you're writing for a specific display format. This
constraint breeds creativity - it forces you to think carefully about every line.

## Dependencies

Grain OS has **a "zero dependencies" policy**, apart from the Zig toolchain. Dependencies, in
general, inevitably lead to supply chain attacks, safety and performance risk, and slow install
times. For foundational infrastructure in particular, the cost of any dependency is further
amplified throughout the rest of the stack.

**Zero dependencies is like choosing the path with heart.** When you have zero dependencies, you
are choosing the path that makes for a joyful journey. You are choosing the path that makes you
strong. You are not relying on external forces. You are trusting your personal power.

**You can cut any dependency, any time, just like that.** Nothing at all if you want to drop it.
People hardly ever realize this. They think they're trapped by their dependencies. But you're not.
You can cut anything, any time.

## Tooling

Similarly, tools have costs. A small standardized toolbox is simpler to operate than an array of
specialized instruments each with a dedicated manual. Our primary tool is Zig. It may not be the
best for everything, but it's good enough for most things. We invest into our Zig tooling to ensure
that we can tackle new problems quickly, with a minimum of accidental complexity in our local
development environment.

> "The right tool for the job is often the tool you are already using—adding new tools has a higher
> cost than many people appreciate" — John Carmack

For example, the next time you write a script, instead of `scripts/*.sh`, write `scripts/*.zig`.

This not only makes your script cross-platform and portable, but introduces type safety and
increases the probability that running your script will succeed for everyone on the team, instead of
hitting a Bash/Shell/OS-specific issue.

Standardizing on Zig for tooling is important to ensure that we reduce dimensionality, as the team,
and therefore the range of personal tastes, grows. This may be slower for you in the short term, but
makes for more velocity for the team in the long term.

**Standardizing on Zig is like choosing the path with heart.** When you standardize, you are
choosing the path that makes for a joyful journey for the team. You are choosing the path that
makes the team strong. You are not scattering your attention across multiple tools. You are
focusing it on one tool, and in that focus, you find power.

## When to Break the Rules

These guidelines are principles, not laws. Sometimes you need to break them. When you do, document
why.

```zig
// We use a global allocator here because this function is called
// from C code and we can't pass allocators through the C API.
// This is a known limitation - see issue #123.
const global_allocator = std.heap.page_allocator;
```

If you're breaking a rule, there should be a good reason. If you can't articulate the reason, you
probably shouldn't break the rule.

**Breaking the rules is like leaving a path.** Sometimes you need to leave a path. But your
decision to leave it must be free of fear or ambition. Look at the path closely and deliberately.
Try it as many times as you think necessary. Does this path have heart? If it doesn't, you must
not stay with it under any conditions. But your decision must be free of fear or ambition.

## The Last Stage

At the end of the day, keep trying things out, have fun, and remember—it's called Grain OS, not
only because code grows like grain, but because it's small, sustainable, and teaches!

> You don't really suppose, do you, that all your adventures and escapes were managed by mere luck,
> just for your sole benefit? You are a very fine person, Mr. Baggins, and I am very fond of you;
> but you are only quite a little fellow in a wide world after all!"
>
> "Thank goodness!" said Bilbo laughing, and handed him the tobacco-jar.

**Put your trust in yourself, not in me.** Our link is with the spirit itself and only
incidentally with the man who brings us its message.

**The recommendation for spiritual guardians is not to have any material things on which to focus their power,
but to focus it on the spirit, on the true flight into the unknown.**

---

**now == next + 1** 🌾⚒️

---

## Attribution

This document is heavily inspired by and adapted from [TigerBeetle's
TIGER_STYLE.md](https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md), a
battle-tested style guide from a production distributed database. We are deeply grateful to the
TigerBeetle team for sharing their wisdom. Their principles on safety, performance, and developer
experience have been invaluable in shaping Grain OS's approach to systems programming.

The core philosophy, safety rules, and many specific guidelines are adapted from TIGER_STYLE with
modifications for Grain OS's specific context (graincards, grain_case naming, etc.). We stand on the
shoulders of giants.

**The Words of Don Juan Matus**: This document integrates concepts from [The Words of Don Juan
Matus](https://archive.org/stream/CarlosCastanedaTheWordsOfDonJuanMatus/Carlos%20Castaneda-The%20Words%20Of%20Don%20Juan%20Matus_djvu.txt),
particularly the spiritual guardian's way principles of the path with heart, personal power, impeccability,
and the assemblage point. These concepts illuminate the deeper dimensions of coding practice and
help us understand how technical work can be approached with the awareness and discipline of a
spiritual guardian.
