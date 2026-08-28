# Ingredia Next Session Context

Last updated: August 28, 2026

## Current State

Ingredia is an iOS allergy-support app built with SwiftUI and SwiftData.

Implemented:

- barcode scanning
- Open Food Facts product lookup
- profile-based allergen assessment
- alternative product suggestions
- local history
- restaurant card
- in-app help
- first-launch safety notice
- retry actions for failed lookups
- delete single history items
- clear all history

## Important Files

- App entry: `Ingredia/Ingredia/IngrediaApp.swift`
- Main home flow: `Ingredia/Ingredia/Views/HomeView.swift`
- Product results: `Ingredia/Ingredia/Views/ProductResultView.swift`
- History: `Ingredia/Ingredia/Views/HistoryView.swift`
- Profile: `Ingredia/Ingredia/Views/ProfileView.swift`
- Help: `Ingredia/Ingredia/Views/HelpView.swift`
- Safety notice: `Ingredia/Ingredia/Views/SafetyNoticeView.swift`
- Product lookup: `Ingredia/Ingredia/Services/OpenFoodFactsService.swift`
- Alternative ranking: `Ingredia/Ingredia/Services/AlternativeProductService.swift`
- Safety logic: `Ingredia/Ingredia/Services/SafetyAnalyzer.swift`
- Localization text: `Ingredia/Ingredia/Models/AppLanguage.swift`
- App metadata: `Ingredia/Ingredia/Models/AppMetadata.swift`

## Release Documents Already Created

- `USER_MANUAL.md`
- `Ingredia_User_Manual.pdf`
- `APP_STORE_READINESS_CHECKLIST.md`
- `APP_STORE_READINESS_CHECKLIST.pdf`
- `TEST_BARCODES.md`
- `Ingredia_Test_Barcodes.pdf`
- `PRIVACY_POLICY.md`
- `PRIVACY_POLICY.pdf`
- `SUPPORT.md`
- `SUPPORT.pdf`
- `APP_STORE_METADATA.md`
- `APP_STORE_METADATA.pdf`
- `SCREENSHOT_PLAN.md`
- `SCREENSHOT_PLAN.pdf`

## Important Notes

- The app uses live Open Food Facts data plus local cached scan history.
- `OpenFoodFactsService.swift` no longer uses a fake contact email in the `User-Agent`.
- `AppMetadata.swift` contains a placeholder `supportURLString` that still needs a real public support URL before App Store release.
- Safety wording must remain conservative. Do not imply that any product is guaranteed safe.

## Validation Status

Most recent status before pausing:

- project builds successfully
- unit tests pass

## Best Next Steps

1. Add a real public support URL or support contact and update `AppMetadata.swift`.
2. Decide App Store launch scope: countries, supported languages, and category positioning.
3. Prepare actual App Store screenshots based on `SCREENSHOT_PLAN.md`.
4. Test on real devices with printed and real product barcodes.
5. Expand tests for edge cases in allergen matching and failure recovery.
6. Consider a future free vs paid feature plan, but do not monetize before launch quality is proven.

## Suggested Restart Prompt

When resuming, start with:

`Read NEXT_SESSION.md and continue the highest-value App Store readiness work for Ingredia.`
