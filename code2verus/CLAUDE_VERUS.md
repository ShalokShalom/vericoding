# CLAUDE_VERUS.md

This file provides guidance to Claude Code and other AI coding agents when translating Verus into Dafny for this repository.

## Mission

Translate Verus programs into Dafny while preserving the logical and verification-relevant meaning that Dafny can actually express.

The translation target is not arbitrary Dafny. The target Dafny should be useful as:

1. a verifier-checked intermediate corpus;
2. a specification corpus for game-development domains;
3. an input language for a future Dafny → F# backend tailored to the Nu engine.

## Primary Priority Order

When trade-offs arise, follow this order:

1. preserve proof-relevant semantics;
2. preserve contracts and state-transition meaning;
3. produce Dafny that verifies or is close to verifiable;
4. prefer forms that later lower cleanly to F# / Nu;
5. preserve surface syntax only when it does not interfere with 1–4.

## Verus → Dafny Semantic Mapping

### Direct mappings

- `requires` → `requires`
- `ensures` → `ensures`
- `invariant` → `invariant`
- `decreases` → `decreases`
- `proof fn` → `lemma`
- `spec fn` → `function` or `predicate`
- executable `fn` → `method` or `function` depending on purity
- `assert(...)` → `assert ...;`
- `forall|x| P` → `forall x :: P`
- `exists|x| P` → `exists x :: P`
- Verus enum-like data → Dafny `datatype`

### Conditional mappings

- `Vec<T>` → `seq<T>` when reasoning is purely mathematical; use `array<T>` only when mutable executable structure matters.
- `struct` → `datatype` when immutable and value-like; use `class` only when identity or mutation matters.
- `impl` methods → module-level methods/functions unless there is a compelling reason to introduce classes/traits.
- trait-heavy code → Dafny `trait` only when the abstraction matters semantically.

### Erasures / abstractions

These usually do not survive into Dafny as first-class semantics:

- ownership and moves
- borrowing (`&`, `&mut`)
- lifetimes
- capacity bookkeeping of vectors
- unsafe blocks as such
- Rust allocator concerns
- low-level memory alias structure not representable in Dafny

When erasing these, preserve the logical consequence if one exists.

## Numeric Semantics

Dafny uses mathematical integers by default. Verus often reasons about machine integers.

### Rules

- map Rust integer types (`u8`, `u32`, `i32`, `usize`, etc.) to `int` unless there is a specific bounded-range reason to emit a constrained form;
- if overflow behavior matters, add a comment explaining that the translation normalized machine arithmetic to mathematical arithmetic;
- `wrapping_add`, `wrapping_sub`, `wrapping_mul`, and similar operations must not be translated silently as ordinary `+`, `-`, `*` without comment;
- if boundedness is semantically important, prefer explicit preconditions or helper predicates.

## Ghost / Proof Structures

Dafny can express a large amount of proof structure. Preserve it where meaningful.

### Preserve when possible

- lemmas
- recursive proof structure
- quantifiers
- helper predicates and helper functions
- proof assertions
- specification-only variables as `ghost var`
- proof-only helper methods

### Normalize carefully

- Verus trigger annotations may need to be dropped or translated to Dafny trigger attributes if useful;
- ghost views such as `@` should become direct mathematical sequence/set/map expressions;
- opaque/reveal patterns should be approximated with comments and explicit helper lemmas if direct Dafny equivalents are awkward.

## Modules and ADTs

- `mod` should normally become `module`.
- nested modules should remain nested when they carry domain meaning.
- `enum` should become `datatype`.
- algebraic state is preferred over ad hoc booleans.
- use names that read well in Dafny and later in F#.

## Nu-Oriented Translation Style

Because this project targets game-development specifications, translated Dafny should lean toward the following forms where the source permits:

- explicit command / message datatypes;
- explicit state datatypes for screens, menus, entities, and combat phases;
- transition predicates and state-transforming methods;
- small helper functions for derived state;
- modular organization by gameplay domain.

If a Verus example is generic, translate it faithfully. If multiple equivalent Dafny encodings are possible, prefer the one that later lowers well to F# and Nu.

## Body Translation Policy

The repository may use different policies depending on the dataset objective.

### Spec-only mode

Use placeholder bodies when the goal is verification challenges, specification mining, or contract-focused corpora.

### Full-translation mode

Translate implementations when the goal is dataset creation for program synthesis, Dafny training, or future F# lowering.

Do not assume one mode universally. Respect the config and task.

## Things Not To Do

- do not silently preserve Rust ownership syntax in comments as if it still had formal force in Dafny;
- do not invent imperative heap structure when a simpler mathematical model preserves the semantics better;
- do not map everything to `array<T>` by default;
- do not erase proof structure that can be represented in Dafny;
- do not choose object-oriented encodings when a datatype/module encoding is cleaner;
- do not forget the eventual F# / Nu backend.

## Preferred Output Qualities

Good output is:

- logically conservative;
- explicit about semantic normalization;
- structurally readable;
- verifier-friendly;
- useful for downstream game-specification work.
