# Ingredia Release Checklist

Date: 2026-08-30

This checklist is intentionally strict. It should contain only items that should be complete before submitting Ingredia to the App Store.

## Must Be Done Before Release

- [ ] Real public support URL or support contact is set in `AppMetadata.swift`
- [ ] Privacy policy is finalized and ready to publish
- [ ] Support page is finalized and ready to publish
- [ ] App Store description and metadata are finalized
- [ ] App Store screenshots are created from the final app UI
- [ ] App icon set is complete for App Store submission

## Safety And Messaging

- [ ] No screen implies that a product is guaranteed safe
- [ ] Safety notice appears correctly on first launch
- [ ] Product result always reminds users to verify packaging and manufacturer information
- [ ] Unknown or incomplete product data never appears as a guaranteed positive result
- [ ] Help text and App Store text use conservative wording

## Core Product Flow

- [ ] User can create and use an allergy profile
- [ ] Barcode scanning works on real devices
- [ ] Product lookup works for real test products
- [ ] Product result shows assessment, findings, and data confidence
- [ ] Alternative products load when category data exists
- [ ] History saves and reopens scanned products
- [ ] Restaurant card works with active profile data

## Failure Handling

- [ ] Offline state shows a clear message
- [ ] Timeout state shows a clear message
- [ ] Product not found state shows a clear message
- [ ] Retry flow works for product lookup
- [ ] Retry flow works for alternative lookup

## Language And Content

- [ ] Norwegian UI is reviewed end-to-end
- [ ] English UI is reviewed end-to-end
- [ ] Thai UI is reviewed end-to-end
- [ ] `SettingsView` is checked in all supported languages
- [ ] Appearance switching works in `System`, `Dark`, and `Light`
- [ ] Version and build values shown in `SettingsView` match the app bundle
- [ ] Help view is checked in all supported languages
- [ ] Safety notice is checked in all supported languages
- [ ] Restaurant card is checked in all supported languages

## Data And External Service Readiness

- [ ] Open Food Facts requests work with the final `User-Agent`
- [ ] Real sample barcodes are tested against live Open Food Facts data
- [ ] International use limitations are clearly documented
- [ ] Missing or weak product data is handled conservatively

## History And Local Data

- [ ] Single-item delete works in History
- [ ] Clear-all history works with confirmation
- [ ] Previously saved products remain readable locally

## Quality Gate

- [ ] Project builds successfully in Release-ready state
- [ ] Automated tests pass
- [ ] Real-device testing is completed
- [ ] Printed barcode testing is completed
- [ ] At least one manual regression pass is completed across all main tabs

## Submission Gate

Submit only when every item above is complete.
