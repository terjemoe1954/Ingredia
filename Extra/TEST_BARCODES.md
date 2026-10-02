# Ingredia Test Barcodes

Prepared on August 28, 2026.

## Purpose

This set is intended for printed scanner testing in Ingredia.

It includes:

- real `EAN-13` product barcodes verified against Open Food Facts on August 28, 2026
- valid synthetic barcodes for scanner and error-handling tests

## Page 1: Live Product Lookup Candidates

These barcodes returned product records from Open Food Facts during verification:

| Barcode | Format | Expected Product |
|---|---|---|
| 3017620422003 | EAN-13 | Nutella |
| 5449000000996 | EAN-13 | Coca-Cola |
| 7622210449283 | EAN-13 | Prince |
| 5000159484695 | EAN-13 | Twix glacé |
| 7613034626844 | EAN-13 | Céréales Chocapic |
| 5000159407236 | EAN-13 | Mars |
| 3017624010701 | EAN-13 | Nutella |
| 8712100516382 | EAN-13 | Pindakaas |

## Page 2: Scanner-Only And Error-Handling Candidates

These are valid barcode numbers intended for scanner testing. They may return `product not found`, which is useful for testing negative flows.

| Barcode | Format | Suggested Use |
|---|---|---|
| 12345670 | EAN-8 | Basic EAN-8 scanner test |
| 55123457 | EAN-8 | EAN-8 scanner test |
| 73513537 | EAN-8 | EAN-8 scanner test |
| 4006381333931 | EAN-13 | Valid EAN-13 not guaranteed to exist in Open Food Facts |
| 5901234123457 | EAN-13 | Valid EAN-13 not guaranteed to exist in Open Food Facts |
| 9780201379624 | EAN-13 | Valid EAN-13 not guaranteed to exist in Open Food Facts |
| 1234567890128 | EAN-13 | Valid EAN-13 not guaranteed to exist in Open Food Facts |
| 7351353760005 | EAN-13 | Valid EAN-13 not guaranteed to exist in Open Food Facts |

## Notes

- Printing quality matters. Use normal scale first and avoid “fit to page” reductions if scanning becomes unreliable.
- Test under both bright and moderate indoor lighting.
- Test from different distances and slight viewing angles.
- For real-world validation, also test with actual product packaging in addition to printed sheets.
