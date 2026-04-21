# Verus → Dafny → F# (Nu) Project Overview and Contributor Plan

## Purpose

This project extends `code2verus` into a more complete verification-language translation platform with two tightly connected goals:

1. translate Microsoft Research's large Verus corpus into Dafny in a form suitable for dataset creation, proof-oriented training, and specification mining;
2. add a Dafny → F# backend focused on the architectural and stylistic conventions of the Nu game engine, so the resulting Dafny specifications can drive game-development-oriented code generation.

The long-term objective is not merely language translation. The actual objective is to build a verified-data pipeline for game logic, gameplay state machines, world transitions, UI flows, inventory systems, combat rules, event routing, and content constraints, with Dafny as the specification language and F# / Nu as a primary executable target.

## Core Idea

The project should be understood as a pipeline with three semantic layers:

- **Verus layer**: rich proof-bearing verified Rust with ownership, borrowing, machine arithmetic, ghost code, proof functions, modules, traits, and ADTs.
- **Dafny layer**: specification-first intermediate representation for contracts, invariants, proof structure, heap framing, and mathematical modeling.
- **F# / Nu layer**: implementation-oriented target focused on idiomatic, game-engine-friendly F# that reflects Nu engine architecture and coding style.

This means Dafny is not treated as a final destination only. It is also the semantic normalization layer.

## Why Dafny Is the Middle Layer

Dafny is the right pivot language for this project because it naturally expresses the kinds of semantic structures we want to preserve for verified game logic:

- preconditions and postconditions for gameplay APIs;
- loop invariants for update loops and traversal logic;
- inductive datatypes for commands, events, and state transitions;
- sets, sequences, maps, and multisets for inventories, quests, triggers, and world facts;
- lemmas and ghost state for proof-carrying logic;
- framing (`reads` / `modifies`) for stateful world updates.

Dafny does **not** model ownership, borrowing, lifetimes, allocator behavior, stack-vs-heap placement, or machine-word overflow the way Verus does. That is a feature, not a bug, for this project. It means the translation can deliberately erase low-level Rust memory semantics and preserve the higher-level logical content that matters for specifications.

## Project Deliverables

The expanded project should deliver the following:

1. **A much stronger `verus-to-dafny` translator configuration** that covers most practical Verus semantic structures.
2. **A Verus-specific contributor and AI guidance document** explaining translation rules, erasure rules, and semantic priorities.
3. **A corpus-generation workflow** that targets `microsoft/Verus_Training_Data` and related Verus datasets.
4. **A Nu-focused Dafny style guide** so that translated Dafny files already reflect the shapes that will later lower well into F# and Nu.
5. **A Dafny → F# backend plan** aimed specifically at Nu engine conventions.
6. **A regression suite** with representative examples from game logic: finite state machines, ECS-like state updates, content invariants, inventories, quest progression, collision predicates, UI menu transitions, and event dispatch.

## Scope of the Verus → Dafny Translator

The translator should become reasonably complete across the following semantic categories.

### Must preserve directly

- `requires`, `ensures`, `invariant`, `decreases`;
- `spec fn`, `proof fn`, executable `fn` distinctions;
- quantifiers, implications, conjunctions, conditionals, pattern matches;
- algebraic data structures and their logical content;
- maps, sets, sequences, sequence-like reasoning, and collection invariants;
- recursive definitions and proof recursion;
- proof assertions and structured proof steps where representable.

### Must map carefully

- `Vec<T>` to `seq<T>` or `array<T>` depending on whether the translated artifact is meant to be purely logical or executable;
- `struct` to `datatype` or `class` depending on whether mutability and identity matter;
- `enum` to `datatype`;
- `impl` methods to module-level functions/methods or class/trait members;
- Verus traits to Dafny traits when meaningful, otherwise flatten to signatures plus comments;
- ghost views (`@`) into direct mathematical forms.

### Must erase or abstract

- borrowing and ownership;
- lifetime annotations;
- capacity-vs-length distinctions that do not matter to the specification;
- unsafe blocks and low-level memory effects;
- most verifier attributes that have no Dafny analogue;
- machine arithmetic details when the target spec should be mathematical.

### Must detect and annotate

Some translations cannot be made semantics-preserving without an explicit choice. The translator should not silently guess.

Examples:

- machine integer arithmetic versus Dafny `int`;
- wrapping arithmetic versus mathematical arithmetic;
- mutable aliasing assumptions that disappear after borrow erasure;
- trait-resolution behavior with no obvious Dafny counterpart.

For such cases, the translator should emit conservative comments and preferred normalization patterns.

## Dataset Strategy

The immediate dataset target is Microsoft's Verus training corpus on Hugging Face. The translator should support large-scale corpus processing with the following stages:

1. ingest Verus examples from Hugging Face or local mirrors;
2. classify examples by difficulty;
3. run structural normalization before LLM translation when possible;
4. translate into Dafny;
5. verify with Dafny;
6. store successful results with metadata explaining what was preserved, erased, and normalized;
7. retain failed examples with categorized errors for iterative improvement.

### Difficulty buckets

Recommended buckets:

- **Easy**: pure `spec fn`, simple proofs, quantifiers, sequences, sets, maps.
- **Medium**: recursive proofs, ADTs, moderate module structure, ordinary executable functions.
- **Hard**: traits, impl blocks, mutable state, proof-heavy executable code, overflow-specific semantics, attributes, ghost views.
- **Very hard**: ownership-sensitive correctness arguments, unsafe-adjacent code, advanced Verus proof idioms with no close Dafny analogue.

This bucketization matters because contributor expectations and AI prompts should differ by class.

## Nu-Oriented Dafny Style

The produced Dafny should not be generic academic Dafny. It should reflect the kinds of abstractions that lower naturally into Nu-style F#.

### Preferred modeling style

- Prefer **explicit datatypes** for gameplay commands, messages, screen transitions, entity events, and UI intents.
- Prefer **state-transforming methods/functions** that make pre/post-state relationships obvious.
- Prefer **small proof lemmas** over giant proof bodies.
- Prefer **module-organized specifications** that correspond to gameplay domains: `World`, `Screen`, `Entity`, `Inventory`, `Quest`, `Combat`, `Input`, `Navigation`, `EventRouting`.
- Prefer **pure helper functions** for derived values such as damage, reachability, menu availability, valid action sets, and quest readiness.
- Prefer **sequence / map / set-based domain modeling** over heap-heavy object graphs when identity is not essential.
- Prefer **explicit transition predicates** for state machines.

### Example domain shapes

- `datatype ScreenState = Title | MainMenu | Loading | InWorld(world: WorldState) | Paused(prev: ScreenState)`
- `datatype Command = Move(dir: Direction) | Attack(target: EntityId) | OpenMenu | Confirm | Cancel`
- `predicate CanTransition(from: ScreenState, cmd: Command, to: ScreenState)`
- `function ValidInventory(inv: Inventory): bool`
- `lemma AddItemPreservesInventoryValidity(...)`

The aim is to make the Dafny corpus useful both for training Dafny generation and for future lowering into idiomatic F#.

## F# Backend Vision

The Dafny → F# backend should be aimed at the Nu engine style, not generic .NET code generation.

### Nu-oriented target principles

- emit **pure functions first** where practical;
- model state transitions with explicit message / command / model patterns;
- prefer **discriminated unions** for domain events and commands;
- prefer **records** for immutable state aggregates;
- use module organization aligned with game subsystems;
- generate code that can sit comfortably next to Nu code rather than fighting it.

### Target output characteristics

- `datatype` → F# discriminated unions;
- immutable data aggregates → F# records;
- pure Dafny `function` / `predicate` → F# pure functions;
- proof-oriented artifacts either erased or retained as comments / documentation stubs;
- stateful Dafny `method`s lowered into explicit state-transition functions where feasible;
- domain modules that line up with Nu screens, entities, world logic, and message handling.

### Important note

The initial F# backend should prioritize **semantic traceability** over perfect idiomaticity. A contributor should be able to inspect generated F# and understand where it came from in Dafny. Once stable, the backend can become more Nu-idiomatic.

## Workstreams

### Workstream A — Strengthen Verus → Dafny translation

Tasks:

1. expand prompt coverage to include ADTs, modules, impl blocks, traits, ghost views, quantifiers, triggers, machine arithmetic normalization, and executable-vs-spec distinctions;
2. add explicit erasure rules and fallback rules;
3. create a Verus guidance document for contributors and AI engines;
4. build a goldens suite.

### Workstream B — Dataset pipeline

Tasks:

1. add dataset-specific config for Microsoft Verus corpora;
2. add difficulty classification and metadata;
3. log preservation/erasure decisions;
4. add batch verification and result manifests.

### Workstream C — Nu-oriented Dafny conventions

Tasks:

1. define module layout for game specs;
2. define preferred datatypes and transition predicates;
3. define guidelines for inventories, quests, combat, UI, entity state, and screen flow;
4. add exemplar benchmark files.

### Workstream D — Dafny → F# Nu backend

Tasks:

1. specify target AST / lowering strategy;
2. define mapping tables from Dafny constructs to F#;
3. decide what proof artifacts become comments, docs, tests, or are erased;
4. create a first vertical slice on small examples.

## Recommended Repository Layout

```text
code2verus/
  CLAUDE_DAFNY.md
  CLAUDE_LEAN.md
  CLAUDE_VERUS.md
  docs/
    PROJECT_OVERVIEW.md
    NU_DAFNY_STYLE.md
    FSHARP_BACKEND_PLAN.md
    CONTRIBUTING_TRANSLATION.md
  config/
    verus-to-dafny.yml
    dafny-to-fsharp-nu.yml
    datasets/
      microsoft-verus-training-data.yml
  benches/
    game/
      inventory/
      combat/
      screen-flow/
      quests/
      navigation/
      event-routing/
  artifacts/
  src/code2verus/
```

This commit adds the high-level architecture and planning document first. Later commits can split this into sub-documents if desired.

## Translation Principles

All contributors and AI systems should follow these principles:

1. **Preserve logical meaning before preserving syntax.**
2. **Prefer explicitness over cleverness.**
3. **Do not silently preserve Rust-specific memory semantics that Dafny cannot express.**
4. **Do not silently erase proof-relevant distinctions without a note.**
5. **Bias translated Dafny toward game-specification usefulness.**
6. **When in doubt, choose the form that later lowers best into Nu-style F#.**

## Milestones

### Milestone 1 — Prompt completeness
- improved `verus-to-dafny.yml`
- `CLAUDE_VERUS.md`
- semantic gap checklist

### Milestone 2 — Dataset bootstrapping
- Microsoft Verus dataset config
- verification manifests
- first successful corpus slice

### Milestone 3 — Nu spec corpus
- benchmark suite for gameplay domains
- normalized Dafny style guide
- translated examples curated for training

### Milestone 4 — F# backend prototype
- Dafny subset lowering
- generated F# for game-state examples
- Nu-oriented output review

### Milestone 5 — End-to-end pipeline
- Verus corpus → Dafny corpus → F# / Nu prototype outputs
- dataset packaging for fine-tuning and evaluation

## Contributor Guidance

Potential new contributors should start in one of three ways:

- **Prompt contributors**: improve translation prompts and semantic coverage.
- **Verifier contributors**: improve normalization and post-translation repair loops.
- **Language/backend contributors**: work on Dafny → F# Nu lowering.

Potential AI engines should treat Dafny as the semantic pivot and should generate output that is conservative, verifiable, and aligned with game logic.

## Final Statement of Intent

This project is not just about translating formal languages. It is about building a verified content pipeline for games.

The Verus corpus provides scale and proof-bearing source material. Dafny provides the specification-centric semantic middle layer. F# and Nu provide the executable destination for real game development.

The system should therefore optimize for one long-term result:

**high-quality Dafny specifications and eventually F# / Nu code for game systems that are easier for humans and AI to generate, understand, verify, and evolve.**
