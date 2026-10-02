# Ingredia User Manual

## Overview

Ingredia is an iPhone app that helps users check packaged food products against a personal allergy or intolerance profile. The app scans a barcode, looks up product information, compares that information with the active profile, and may suggest alternative products in the same category.

Ingredia is a decision-support tool only. It does not guarantee that a product is safe. Always check the packaging, ingredients list, allergen statement, and the manufacturer’s latest information.

## Main Tabs

Ingredia has four main tabs:

- `Skann` / `Scan`: Scan a product barcode and review the result.
- `Historikk` / `History`: Open previously scanned products.
- `Restaurantkort` / `Restaurant Card`: Show an allergy card based on the active profile.
- `Profil` / `Profile`: Manage allergy settings, cross-contamination preference, language, and notes.

## Before First Use

1. Open the `Profil` tab.
2. Review the default profile or create a new one.
3. Select the allergens or intolerances that apply.
4. Decide whether `may contain traces of` warnings should be treated as unacceptable.
5. Optionally add a restaurant note for staff.
6. Choose the app language.

The app creates a default profile automatically if none exists.

## Camera Permission

Ingredia uses the iPhone camera to scan barcodes. The app requires camera access the first time scanning is used.

If scanning does not open correctly:

1. Open iPhone `Settings`.
2. Find `Ingredia`.
3. Confirm that camera access is enabled.

## Supported Barcode Types

Ingredia currently scans these barcode formats:

- `EAN-8`
- `EAN-13`
- `UPC-E`
- `Code 128`

## How To Scan a Product

1. Open the `Skann` / `Scan` tab.
2. Tap the main scan button.
3. Place the barcode inside the camera frame.
4. Hold the phone steady until the app detects the code.
5. Wait while Ingredia fetches product information.

If a product is found, the result screen opens automatically.

If the product cannot be found or the request fails, Ingredia shows an error message.

## Understanding the Result Screen

The result screen is designed to answer six questions:

1. What product was scanned?
2. Is there a conflict with the active profile?
3. Why did the app reach that conclusion?
4. How complete is the available product data?
5. What should still be checked on the packaging?
6. Are there better alternatives?

### Product Summary

The top section shows:

- Product name
- Brand
- Barcode
- Product image when available

### Assessment Levels

Ingredia may show one of these result levels:

- `Ingen registrerte konflikter` / `No registered conflicts`
- `Kontroller produktet` / `Check the product`
- `Ikke anbefalt` / `Not recommended`
- `For lite informasjon` / `Too little information`

These levels are based on the active profile and the available product data.

### Why a Product Was Flagged

If Ingredia detects possible conflicts, it lists the matching allergens and whether they appear as:

- a registered ingredient or allergen
- a trace or cross-contamination warning

If the profile is set to reject trace warnings, a matching `may contain` warning can make the product `Not recommended`.

### Data Confidence

Ingredia also shows a `Datagrunnlag` / `Data confidence` section for the scanned product.

Possible values:

- `Høy datakvalitet` / `High data quality`
- `Begrenset informasjon` / `Limited information`
- `Ukjent datagrunnlag` / `Unknown data basis`

This section helps explain how complete the available ingredient, allergen, and category data appears to be. It may also show the latest known product update date when that information exists.

### Important Reminder

Even when Ingredia finds no registered conflict, users should still verify:

- the ingredients list
- allergen statements
- trace warnings
- recent packaging changes

## Better Alternatives

If the scanned product has a conflict or should be checked, Ingredia may show `Bedre alternativer` / `Better alternatives`.

Alternative suggestions are built from products in the same or a similar category and are evaluated against the full active profile, not only one allergen.

Ingredia prefers alternatives that:

- do not conflict with the active profile
- respect the trace-warning preference
- match the scanned product category
- have more complete product data
- have newer product data when available

Ingredia may label an alternative as:

- `Fra historikk` / `From history`
- `Fra Open Food Facts` / `From Open Food Facts`

Users can also hide unclear suggestions with the `Hide unknown suggestions` filter.

## History

The `Historikk` / `History` tab stores previously scanned products locally on the device.

From this screen, users can:

- review earlier scans
- reopen a product result
- see the last scanned date

If the same barcode is scanned again later, Ingredia fetches live product data again and updates the local record.

## Profiles

The `Profil` / `Profile` tab supports multiple profiles.

Users can:

- switch the active profile
- create a new profile
- duplicate a profile
- delete a profile when more than one exists
- rename a profile
- choose allergens and intolerances
- set cross-contamination preference
- add a restaurant note
- change the app language

Changes are saved automatically.

## Restaurant Card

The `Restaurantkort` / `Restaurant Card` tab creates a visual card based on the active profile.

It shows:

- the selected allergens
- a cross-contamination warning when enabled
- an optional restaurant note
- a reminder to verify ingredients and preparation

This card is meant to be shown to restaurant staff. It supports the current app languages:

- Norwegian
- English
- Thai

## Where the Product Information Comes From

Ingredia currently uses `Open Food Facts` as its product data source.

The app uses live network requests to:

- fetch the scanned product
- search for alternative products in similar categories

Ingredia also stores scanned and viewed products locally so they remain available in history.

## International Use

Ingredia uses the global Open Food Facts database, so it can work abroad.

Important limitations:

- product coverage varies by country
- some markets have more complete data than others
- category quality may vary
- missing or outdated records can affect results

International support should therefore be treated as useful but not equally reliable in every country.

## Offline and Network Behavior

Current behavior:

- scanning and fresh product lookup require internet access
- previously stored products remain available locally in history
- the app is not yet a full offline product database

If there is no connection, Ingredia may show an offline or timeout error instead of fresh results.

## Troubleshooting

### The scanner does not work

- Confirm camera permission is enabled in iPhone settings.
- Make sure the barcode is well lit and fully visible.
- Try moving the phone slightly closer or farther away.

### The product is not found

- The barcode may not exist in Open Food Facts.
- The code may be valid but not yet available in the database.
- Try scanning again with better focus.

### The result seems incomplete

- Some products have missing ingredient or allergen data.
- Open Food Facts is a public database and quality varies.
- Always compare the result with the package label.

### No alternatives appear

- The product may not have enough category data.
- Similar products may not exist in the available database.
- Candidate products may be rejected because they conflict with the active profile.

## Safety Notice

Ingredia must not be used as the only basis for a medical or dietary decision.

Always:

- read the package
- verify the manufacturer’s latest information
- treat unknown or limited data with caution
- use extra care for severe allergies and cross-contamination risk

## Version Scope

This manual describes the current MVP behavior in the project as of `August 28, 2026`.
