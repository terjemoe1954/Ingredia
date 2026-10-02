# Ingredia -- Codex Project Context

## Purpose

Ingredia is an iOS app for people with food allergies and intolerances.

The core value proposition is not merely warning users about allergens.
The app should help a user scan a food product, compare it against their
personal profile, explain potential conflicts, and eventually suggest
safer alternative products in the same category.

The product should be designed conservatively because incorrect allergen
information can have serious consequences. Ingredia must never claim
that a product is guaranteed safe.

## Platform and technology

-   Native iOS app
-   Swift
-   SwiftUI
-   SwiftData
-   Minimum deployment target: iOS 17+
-   Barcode scanning with AVFoundation
-   Product lookup through Open Food Facts API v2
-   Local storage/cache with SwiftData

Prefer native Apple frameworks unless there is a strong reason to add a
dependency.

## Current project structure

The project currently contains approximately this structure:

    Ingredia/
        IngrediaApp.swift

        Models/
            Allergen.swift
            UserProfile.swift
            ScannedProduct.swift

        Services/
            OpenFoodFactsService.swift
            SafetyAnalyzer.swift

        Scanner/
            BarcodeScannerView.swift

        Views/
            RootView.swift
            HomeView.swift
            ProductResultView.swift
            ProfileView.swift
            RestaurantCardView.swift
            HistoryView.swift

## Current functionality

The first MVP already implements:

1.  Personal allergen/intolerance profile.
2.  Toggle controlling whether "may contain traces of" should be treated
    as unacceptable.
3.  Barcode scanning.
4.  EAN-8, EAN-13, UPC-E and Code 128 recognition.
5.  Open Food Facts product lookup.
6.  Retrieval of:
    -   product name
    -   brand
    -   ingredients
    -   allergen tags
    -   trace tags
    -   product image
7.  Basic comparison between product information and the user's profile.
8.  Result states similar to:
    -   no registered conflict
    -   caution
    -   not recommended
    -   insufficient information
9.  Scan history stored with SwiftData.
10. Previously scanned products remain locally available.
11. A basic Norwegian restaurant allergy card.

## Camera permission

The Xcode target already contains:

Privacy - Camera Usage Description

with the Norwegian text:

Ingredia bruker kameraet til å skanne strekkoder på matvarer.

Do not remove this permission description.

## Open Food Facts

`OpenFoodFactsService.swift` performs product lookup using Open Food
Facts API v2.

The request retrieves only required fields to avoid unnecessary network
traffic.

Before App Store release, replace the placeholder contact information in
the User-Agent with the app's real contact address or website.

Open Food Facts data must be treated as external product information
that can be incomplete, outdated or incorrect.

Never interpret the presence of an Open Food Facts record as proof that
a food is medically safe.

## Important Swift concurrency fix already made

The original implementation contained a private String extension similar
to:

    private extension String {
        var nonEmpty: String? {
            isEmpty ? nil : self
        }
    }

With the project's actor-isolation settings, Xcode produced:

    Main actor-isolated property 'nonEmpty' cannot be accessed from outside of the actor

The extension was removed.

Product naming in `OpenFoodFactsService.swift` now uses logic equivalent
to:

    name: (product.productName?.isEmpty == false
           ? product.productName!
           : "Ukjent produkt")

Do not reintroduce the `nonEmpty` extension unless the
concurrency/isolation behavior has been deliberately addressed.

The project currently builds without errors after this change.

## Safety model

Ingredia must use conservative wording.

DO NOT display statements such as:

-   "This product is safe."
-   "Guaranteed allergy safe."
-   "You can safely eat this."

Prefer wording such as:

-   "Ingen registrerte allergener som kolliderer med profilen din ble
    funnet."
-   "No registered allergens conflicting with your profile were found."
-   "Kontroller alltid emballasjen og produsentens siste informasjon."

The app is an information and decision-support tool. It is not a
substitute for the food label, manufacturer information or professional
medical advice.

Unknown or incomplete data must result in an UNKNOWN/CAUTION state, not
a green safety guarantee.

## Allergen profile

The MVP supports common EU allergen categories including:

-   milk
-   gluten-containing cereals
-   peanuts
-   tree nuts
-   eggs
-   soy
-   sesame
-   fish
-   crustaceans
-   celery
-   mustard
-   lupin
-   molluscs
-   sulphur dioxide / sulphites

The current implementation uses both Open Food Facts tags and keyword
matching in ingredient text.

This matching system is an MVP and should be improved rather than
treated as authoritative.

## Cross-contamination

`UserProfile` contains a setting equivalent to:

    rejectMayContain

When enabled, trace/cross-contamination warnings matching the user's
allergens should make the product unacceptable/not recommended.

When disabled, they may result in a caution state rather than an
automatic rejection.

Do not silently change this behavior.

## Restaurant card

Ingredia includes a basic restaurant allergy card.

Current version: - Norwegian - displays allergens from the personal
profile - indicates cross-contamination requirements when relevant

Future versions should support multiple languages and a large,
easy-to-read presentation suitable for showing restaurant staff.

Translations must preserve the meaning of allergy warnings and should
not casually paraphrase medically important statements.

## Offline design

Offline functionality is an important product requirement, especially
for travel.

The MVP stores previously scanned products locally.

Longer term, Ingredia should support downloadable regional/country
product data.

Do not attempt to download the entire global Open Food Facts database to
the device.

A future offline system should favor: - selected countries/regions -
incremental updates - compressed product records - user-relevant
categories where appropriate - clear "last updated" information

## Primary next feature: Safer Alternatives

This is the next major feature to build.

Goal:

After scanning a product that conflicts with the user's profile,
Ingredia should suggest products in the same or a closely related
category that appear more compatible with that profile.

Example:

A user with milk allergy scans a chocolate product containing milk.

Ingredia might show:

    Ikke anbefalt
    Inneholder: Melk

    Bedre alternativer

    Product A
    No registered milk allergen
    No registered milk traces
    High data completeness

    Product B
    Milk-free according to available data
    May contain nuts

Alternatives must be evaluated against the ENTIRE user profile, not only
the allergen that caused the original product to fail.

For example, replacing a milk-containing product with a milk-free
product that contains peanuts is not useful for a user who also has a
peanut allergy.

## Recommended alternative-product architecture

Do not put all alternative-selection logic directly in SwiftUI views.

Prefer introducing models/services similar to:

    ProductSafetyAssessment
    AlternativeProduct
    AlternativeProductService
    AlternativeRankingService

The UI should consume already-evaluated alternatives.

A possible ranking approach:

1.  Reject direct conflicts with profile allergens.
2.  Respect `rejectMayContain`.
3.  Prefer the same product category.
4.  Prefer products with more complete ingredient/allergen data.
5.  Prefer recently updated product records where that information
    exists.
6.  Prefer products available in the user's relevant country/market when
    possible.
7.  Clearly label unknown data.

Never rank an alternative highly merely because it lacks allergen
information. Missing information should reduce confidence.

## Product trust/data-quality concept

Ingredia should eventually display a confidence/data-quality indicator.

Possible levels:

### Manufacturer verified

Product information confirmed through a trusted manufacturer source.

### High data confidence

Complete ingredient and allergen information with reasonably recent
data.

### Limited information

Some relevant fields are missing or potentially stale.

### Unknown

Insufficient data for a meaningful assessment.

Do not imply manufacturer verification unless the data really comes from
a verified manufacturer process.

## Future roadmap

After Safer Alternatives, likely priorities are:

1.  Favorites.
2.  Better product-category handling.
3.  Multiple family/user profiles.
4.  Multilingual restaurant cards.
5.  Improved allergen-tag normalization.
6.  Product data confidence indicators.
7.  Country-specific offline downloads.
8.  Manufacturer verification.
9.  StoreKit 2 subscription.
10. Accessibility improvements.
11. Unit/UI tests.
12. Optional Apple Watch companion experience.

## FODMAP

Low-FODMAP support is a possible future feature but should NOT be
implemented by copying proprietary databases.

If FODMAP functionality is added, verify that every data source can
legally be used in a commercial application.

FODMAP assessment is also more complex than simple allergen presence
because serving size and quantity can matter.

Keep FODMAP separate from the binary allergen engine unless the model
has deliberately been designed to handle those differences.

## Subscription concept

Do not implement monetization until the core scanning and alternative
recommendation experience is reliable.

Possible future free tier: - limited scans - one profile - basic
allergen analysis

Possible Premium tier: - unlimited scans - multiple profiles -
downloadable offline databases - expanded restaurant-card languages -
advanced alternative recommendations

Use StoreKit 2 when monetization is implemented.

## UI direction

Keep Ingredia simple and reassuring without implying medical certainty.

Main navigation currently follows approximately:

    Skann
    Historikk
    Restaurantkort
    Profil

The scan action should remain the most prominent action.

Product results should make these questions answerable at a glance:

1.  What product did I scan?
2.  Is there a conflict with my profile?
3.  Why?
4.  Is the underlying data complete enough to trust the assessment?
5.  What should I check on the package?
6.  Are there better alternatives?

Use Apple's accessibility APIs, Dynamic Type and VoiceOver-friendly
labels.

Do not rely solely on red/green color to communicate status. Always
include text and/or symbols.

## Coding instructions for Codex

When continuing this project:

-   Inspect the existing project before editing.
-   Preserve working functionality.
-   Prefer small, testable changes.
-   Keep networking outside SwiftUI views.
-   Keep allergen/safety logic outside SwiftUI views.
-   Keep SwiftData models focused on persistence.
-   Avoid unnecessary third-party dependencies.
-   Use async/await for networking.
-   Respect Swift concurrency and actor isolation.
-   Do not force unwrap values from external API responses unless
    correctness is already established; improve existing forced unwraps
    when convenient.
-   Treat all external product data as potentially incomplete.
-   Compile after meaningful changes when the environment allows it.
-   Fix compiler warnings introduced by new code.
-   Add tests for safety/ranking logic as that logic becomes more
    sophisticated.
-   Preserve Norwegian as the initial UI language unless explicitly
    asked to add localization.

## Current session status

Last updated: August 27, 2026

The original Safer Alternatives task has been implemented and expanded
substantially.

### Implemented since the original context

-   `ScannedProduct` now includes category labels and source recency
    metadata used for ranking.
-   `OpenFoodFactsService` now supports:
    -   category retrieval
    -   alternative candidate lookup
    -   better request-error mapping
-   A dedicated alternative layer now exists:
    -   `ProductSafetyAssessment`
    -   `AlternativeProduct`
    -   `AlternativeProductService`
    -   `AlternativeRankingService`
-   `ProductResultView` now shows:
    -   alternative products
    -   source badges such as history/Open Food Facts
    -   recommendation reasons
    -   safety-status chips
    -   a persisted filter for hiding unknown suggestions
-   Alternative products can be opened directly from the result screen.
-   Opening an alternative also stores or updates it in local history.
-   Local previously scanned products are used as a cache/source for
    alternative suggestions.
-   The app now supports Norwegian, English and Thai through
    `AppLanguage.swift`.
-   `HistoryView`, `HomeView`, `ProductResultView`, `ProfileView` and
    `RestaurantCardView` have all been improved visually and for
    accessibility.

### Profile and restaurant-card status

-   `UserProfile` now supports:
    -   profile name
    -   restaurant note
    -   active-profile selection
    -   multiple profiles
-   Profiles can now be:
    -   created
    -   activated
    -   duplicated
    -   deleted, with safe fallback to another active profile
-   `RestaurantCardView` now shows the active profile name and optional
    restaurant note.
-   `HomeView`, `HistoryView` and `RestaurantCardView` all use the
    active profile consistently.

### Profile UX note

`ProfileView` now saves changes automatically.

There is no separate save button by design.

To address keyboard usability:

-   the keyboard can be dismissed with a `Ferdig` button
-   the list supports interactive keyboard dismissal while scrolling
-   explanatory text now states that changes are auto-saved

### App icon status

A new medical-grade style app icon has been added at:

`Ingredia/Ingredia/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`

The asset catalog `Contents.json` has been updated to reference it.

### Test/build status

Latest verified state in Xcode:

-   project builds successfully
-   all tests pass
-   current test count: `22/22`

### Suggested next steps

The most sensible next areas are now:

1.  Better profile management UX, such as clearer editing affordances or
    reordering.
2.  Restaurant-card presentation improvements such as full-screen mode
    or sharing/export.
3.  Further improvement of category normalization and alternative search
    quality in `OpenFoodFactsService`.
4.  More UI-level tests around profile flows and alternative filters.
