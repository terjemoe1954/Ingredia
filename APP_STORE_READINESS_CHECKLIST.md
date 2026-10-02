# Ingredia App Store Readiness Checklist

Version scope: current project state as reviewed on August 30, 2026.

## Release Goal

Ship Ingredia as a conservative allergy-information utility for iPhone that helps users review packaged food products against a personal profile. The app must not imply medical certainty or guaranteed food safety.

## 1. Mandatory Safety And Trust Gates

- Replace any wording that could imply a guarantee of safety.
- Keep warning language conservative when product data is missing, incomplete, or unclear.
- Ensure every result view reminds the user to verify packaging and manufacturer information.
- Review all translations so safety wording keeps the same meaning in Norwegian, English, and Thai.
- Add a visible disclaimer in the App Store description and inside the app.
- Add a privacy policy and support URL before submission.

Release bar:

- No screen should state or imply “safe to eat”.
- Unknown data must stay `unknown` or `caution`, not green by default.
- Alternatives must never rank highly just because data is missing.

## 2. Product Data Quality

- Replace the placeholder contact value in the `User-Agent` header in [OpenFoodFactsService.swift](/Users/terjemoe/Desktop/MyApps/Ingredia/Ingredia/Services/OpenFoodFactsService.swift).
- Decide what country and market behavior should be documented for launch.
- Review how category labels from Open Food Facts behave across different markets.
- Add clearer handling for stale or low-confidence records if the source data is weak.
- Verify that barcodes from several countries return sensible results and do not break ranking.

Release bar:

- Barcode lookup works reliably on real devices over normal mobile data and Wi-Fi.
- The app handles `not found`, `offline`, `timeout`, and server issues with user-readable messages.
- Product data confidence is shown consistently on result screens.

## 3. Functional Completion

- Confirm the full core loop is complete:
- profile setup
- settings
- scan
- product assessment
- explanation of findings
- product data confidence
- alternative suggestions
- history
- restaurant card
- in-app help
- Tighten the alternative ranking logic with more edge-case tests.
- Decide whether users need manual retry controls after failed lookups.
- Decide whether history should support delete/clear actions before release.

Release bar:

- No dead ends in the main user flow.
- The app remains useful when no alternatives are available.
- Cached products remain readable offline.

## 4. Accessibility

- Test Dynamic Type across standard and large accessibility sizes.
- Test VoiceOver on all tabs and result sections.
- Test `SettingsView`, including appearance selection, language switching, help access, and version/build display.
- Confirm status is not communicated by color alone.
- Check contrast in caution, avoid, and data-quality states.
- Verify button sizes and tap targets.

Release bar:

- Main actions remain usable at large text sizes.
- VoiceOver can identify scan, profile, result, and help content clearly.

## 5. Privacy And Legal

- Draft a privacy policy covering camera use, network requests, and local storage.
- Draft support contact information and a support page.
- Confirm no sensitive user profile data is transmitted to external services beyond product lookup requirements.
- Document that product information comes from Open Food Facts and can be incomplete or outdated.
- Check App Store review guidance for health-related or safety-adjacent wording.

Release bar:

- Privacy policy URL is ready.
- Support URL is ready.
- Marketing copy stays within what the app can actually guarantee.

## 6. QA And Testing

- Expand unit tests for allergen matching edge cases:
- false positives from ingredient keyword matching
- localized ingredient naming
- trace handling with `rejectMayContain` on and off
- multiple allergen conflicts in one product
- ambiguous or incomplete data
- Add UI tests for:
- first-run profile setup
- scan flow
- failed lookup flow
- history reopen flow
- language switching
- help screen access
- restaurant card rendering
- Test on multiple device sizes.
- Test with low bandwidth and airplane-mode scenarios.

Release bar:

- Green build.
- Automated tests cover core logic and key user flows.
- Real-device test pass with printed barcodes and real product packaging.

## 7. App Store Packaging

- Create app icon set for all required sizes.
- Create launch-ready screenshots for supported devices.
- Write App Store subtitle, promotional text, keywords, and description.
- Prepare privacy nutrition labels in App Store Connect.
- Decide initial availability countries.
- Confirm age rating inputs.

Release bar:

- Store metadata is complete and consistent with the actual app behavior.
- Screenshots do not overpromise medical safety.

## 8. Recommended Pre-Launch Improvements

- Add onboarding for first-time users.
- Add a retry action for lookup failures.
- Add a way to delete individual history items.
- Consider a dedicated disclaimer screen on first launch.
- Improve category normalization for alternative matching.
- Add more visible timestamps or freshness signals for cached product data.

## 9. Nice-To-Have After MVP Release

- Favorites
- better offline product support
- country-aware product prioritization
- additional restaurant card languages
- manufacturer verification or trust tiers
- family profiles and multi-user workflows
- subscription or premium tier only after reliability is proven

## Suggested Release Sequence

1. Finish safety, privacy, and error-handling gaps.
2. Improve tests and real-device validation.
3. Prepare App Store assets and legal pages.
4. Run a small private beta with allergy-aware testers.
5. Fix beta findings before App Store submission.
