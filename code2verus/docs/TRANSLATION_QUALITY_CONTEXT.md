# Translation Quality Context

This document contextualizes what the upstream translation analysis report means for this project.

## What the Report Tells Us

The upstream [translation analysis report](./translation_analysis_report.md) measured semantic equivalence across **643 Verus/Dafny file pairs** already present in the vericoding benchmark suite, sampling 200 in detail. [cite:121]

Key numbers that matter for planning:

| Metric | Value | Implication |
|---|---|---|
| Overall similarity | 84.8% ± 2.7% | Good baseline; not perfect |
| Excellent matches (≥95%) | 12% | These are ready to use as-is |
| Good matches (≥85%) | 28.5% | Usable with light review |
| Poor matches (<70%) | 53% | Need repair loop or manual work |
| Discrepancies that are syntax-only | 91% | Most failures are fixable mechanically |
| Discrepancies needing manual review | 9% | Genuinely hard semantic gaps |

## What This Means for the Verus → Dafny Pipeline

### The 40.5% high-quality stratum

The 40.5% of translations scoring ≥85% are largely ready to be added to a training corpus after Dafny verification. These correspond mainly to the **easy** and **medium** difficulty buckets defined in the dataset config.

### The 53% poor-match stratum

These are not failures — 91% of all discrepancies are syntax-only (naming, operator spelling, sequence syntax). The translator prompt improvements in `verus-to-dafny.yml` are specifically aimed at closing these gaps systematically:

- `snake_case` → `PascalCase` remapping
- `seq@` / `.len()` / `.contains()` normalization
- `forall|x|` → `forall x ::` rewriting
- string literal `@` stripping

### The 9% genuinely hard cases

These require the iterative LLM + Dafny verifier loop. The `max_translation_iterations: 5` setting in the dataset config is appropriate for this class.

## Implications for the Nu F# Backend

The 84.8% baseline also tells us something about the **Dafny → F#** direction. If Verus → Dafny is already achieving this fidelity on specification content, then the logical content that will flow into the F# backend is high quality. The main F# backend risks are therefore not in the specification content but in:

- how cleanly `datatype` ADTs lower to discriminated unions;
- how framing information (`reads`/`modifies`) is expressed or dropped;
- how proof artifacts (lemmas, ghost vars) are handled — test stubs vs. erasure.

These are all addressed in `dafny-to-fsharp.yml`.

## Recommended Action Per Stratum

| Stratum | Recommended action |
|---|---|
| Excellent (12%) | Use directly after Dafny verification |
| Good (28.5%) | Light normalization pass, then verify |
| Fair (6.5%) | One repair iteration, then verify |
| Poor (53%) | Full LLM repair loop up to 5 iterations |
| Still failing | Log, categorize, skip for now |
