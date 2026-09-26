# Ingredia Multi-Source Product Lookup Plan

Date: 2026-09-01

## Goal

Improve product coverage, data quality, and alternative suggestions by allowing Ingredia to read from more than one product source.

The system must remain conservative:

- more data must not lead to overconfident safety claims
- conflicting source data must lower confidence, not be silently ignored
- missing data must still produce `unknown` or `caution` where appropriate

## Current State

Today, Ingredia uses one external source:

- `OpenFoodFactsService.swift`

That service currently handles:

- barcode lookup
- alternative candidate search by category
- normalization into `ScannedProduct`

This is simple, but it creates clear limits:

- one source can have missing products
- one source can have weak allergen data
- alternatives are limited by one source’s category quality
- source disagreement cannot currently be detected

## Proposed Direction

Introduce a provider-based architecture:

1. Each external data source implements the same interface.
2. A central aggregator asks one or more providers for product data.
3. The aggregator merges the results into a normalized internal model.
4. `SafetyAnalyzer` and `AlternativeProductService` continue to work on internal models, not raw provider responses.

## New Core Types

### `ProductDataProvider`

Protocol for a single product source.

Suggested responsibility:

- fetch a product by barcode
- fetch alternative candidates
- expose a provider identifier

Suggested shape:

```swift
protocol ProductDataProvider {
    var providerID: String { get }

    func fetchProduct(barcode: String) async throws -> ProviderProductRecord?

    func fetchAlternativeCandidates(
        categoryNames: [String],
        excludingBarcode barcode: String,
        limit: Int
    ) async throws -> [ProviderProductRecord]
}
```

### `ProviderProductRecord`

Normalized source-specific record before merging.

Suggested fields:

- `providerID`
- `barcode`
- `name`
- `brands`
- `ingredientsText`
- `allergens`
- `traces`
- `categoryLabels`
- `imageURLString`
- `lastModifiedAt`
- `sourceConfidence`

This should not be a SwiftData model. It should stay a lightweight transport type.

### `MergedProductRecord`

Internal merged data before conversion to `ScannedProduct`.

Suggested fields:

- merged product properties
- list of contributing providers
- field-level provenance
- merge warnings or disagreements
- merged confidence level

This can later feed both persistence and UI.

## New Services

### `ProductLookupAggregator`

Main orchestration layer for barcode lookups.

Responsibilities:

- call providers in order
- merge multiple responses
- detect disagreement between providers
- convert merged result to `ScannedProduct`
- expose confidence metadata for the UI

### `AlternativeCandidateAggregator`

Coordinates alternative search across providers.

Responsibilities:

- fetch candidates from multiple sources
- deduplicate by barcode
- merge duplicates
- pass merged candidates to the existing ranking logic

## Suggested Provider Order

Start simple and deterministic:

1. `OpenFoodFactsProvider`
2. future secondary providers
3. local cache/history as a supporting signal, not the primary truth

This allows a staged rollout without rewriting the app all at once.

## Merge Rules

Use conservative field-by-field rules.

### Product name

- prefer non-empty value from the highest-confidence source
- if multiple strong sources disagree, keep one visible value but reduce confidence

### Ingredients

- prefer the most complete non-empty ingredient string
- if strings differ materially, mark the record as having source disagreement

### Allergens and traces

- union is safer than intersection for warning purposes
- if one source reports an allergen and another omits it, do not remove the warning
- disagreement should lower confidence and may justify extra caution text

### Categories

- merge unique labels from all sources
- keep provider-specific category quality in mind when ranking alternatives

### Last updated

- keep the newest known timestamp
- also track which provider supplied it

### Images

- prefer a usable URL from the highest-confidence source

## Safety Rules For Conflicting Data

This is the most important part.

If two sources disagree about allergen-relevant data:

- do not choose the “safer” interpretation automatically
- prefer the more conservative interpretation
- lower the product confidence level
- consider showing a “source disagreement” note in the future UI

Example:

- source A says product contains milk
- source B has no milk allergen listed

The app should not conclude that milk is absent. It should treat the product conservatively.

## Alternative Product Strategy

For better alternatives, use the merged candidate pool, then keep the current ranking principles:

1. reject direct conflicts with the full user profile
2. respect `rejectMayContain`
3. prefer same-category products
4. prefer higher-confidence records
5. prefer more recent records

Additional rule for multi-source mode:

- prefer candidates confirmed by more than one provider when the data is consistent

But:

- never boost a candidate only because it exists in more sources if those sources are weak or conflicting

## Persistence Strategy

Do not persist raw provider payloads directly into `ScannedProduct`.

Instead:

- keep `ScannedProduct` as the app-facing persisted product
- optionally add provenance fields later if needed

Possible future additions to `ScannedProduct`:

- `sourceProviderIDs: [String]`
- `dataConfidenceLevelRaw: String`
- `hasSourceDisagreement: Bool`

Those fields are optional for phase 1.

## UI Impact

Phase 1 can keep UI changes minimal.

Current views can remain mostly unchanged if the merged result still produces `ScannedProduct`.

Later UI improvements could include:

- source count indicator
- stronger data confidence messaging
- source disagreement warning
- “based on multiple sources” detail text

## Recommended Implementation Phases

### Phase 1: Extract Provider Interface

- turn `OpenFoodFactsService` into `OpenFoodFactsProvider`
- keep current behavior through a one-provider aggregator
- ensure no visible regression

### Phase 2: Add Aggregator

- introduce `ProductLookupAggregator`
- introduce `AlternativeCandidateAggregator`
- keep Open Food Facts as the only live provider at first
- update `HomeView` and `ProductResultView` to call the aggregator, not the provider directly

### Phase 3: Add Second Provider

- integrate one additional source
- implement merge rules
- add confidence and disagreement handling

### Phase 4: Improve UI

- expose stronger confidence information
- add disagreement messaging where needed

### Phase 5: Expand Tests

- test merge behavior
- test conflicting allergen fields
- test duplicate candidate merge logic
- test ranking when provider data quality differs

## Minimal Refactor Path In This Codebase

Best low-risk order for this project:

1. Create `ProductDataProvider.swift`
2. Create `ProviderProductRecord.swift`
3. Rename or wrap `OpenFoodFactsService` behind the provider protocol
4. Create `ProductLookupAggregator.swift`
5. Update `HomeView.lookup(code:)` to use the aggregator
6. Update `AlternativeProductService` to request candidates from the aggregator
7. Add unit tests before adding a second live provider

## Testing Requirements

Before adding more providers, add tests for:

- provider fallback
- merge of duplicate barcode records
- allergen union behavior
- conservative handling of disagreement
- alternative ranking with mixed data completeness

## Recommendation

Do this, but in stages.

The right next engineering step is not “add many sources immediately”.
The right next step is:

- refactor to a provider interface
- put an aggregator in front of the current Open Food Facts code
- preserve the current app behavior
- then add one extra provider only after the merge rules are tested

## Suggested Next Prompt

`Implement phase 1 and phase 2 of MULTI_SOURCE_PRODUCT_LOOKUP_PLAN.md in the Ingredia app without adding a second provider yet.`
