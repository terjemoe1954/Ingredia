//
//   IngrediaTests.swift
//   IngrediaTests
//
//  Created by Terje Moe on 27/08/2026.
//

import Foundation
import Testing
@testable import Ingredia

@MainActor
struct IngrediaTests {
    @Test
    func safetyAnalyzerReturnsAvoidForDirectAllergenConflict() {
        let profile = UserProfile(allergenIDs: ["milk"], rejectMayContain: true)
        let product = makeProduct(
            ingredientsText: "Sugar, milk powder, cocoa butter",
            allergens: ["en:milk"]
        )

        let result = SafetyAnalyzer.analyze(product: product, profile: profile)

        #expect(result.level == .avoid)
        #expect(result.findings.count == 1)
        #expect(result.findings.first?.severe == true)
    }

    @Test
    func safetyAnalyzerReturnsCautionForAllowedTraceWarning() {
        let profile = UserProfile(allergenIDs: ["peanuts"], rejectMayContain: false)
        let product = makeProduct(
            ingredientsText: "Corn, salt",
            traces: ["en:peanuts"]
        )

        let result = SafetyAnalyzer.analyze(product: product, profile: profile)

        #expect(result.level == .caution)
        #expect(result.findings.count == 1)
        #expect(result.findings.first?.severe == false)
    }

    @Test
    func safetyAnalyzerTrimsDirectAllergenTagsBeforeMatching() {
        let profile = UserProfile(allergenIDs: ["milk"], rejectMayContain: true)
        let product = makeProduct(
            ingredientsText: "Sugar, cocoa butter",
            allergens: [" EN:milk "]
        )

        let result = SafetyAnalyzer.analyze(product: product, profile: profile)

        #expect(result.level == .avoid)
        #expect(result.findings.first?.allergenName == "Melk")
    }

    @Test
    func safetyAnalyzerTrimsTraceTagsBeforeMatching() {
        let profile = UserProfile(allergenIDs: ["milk"], rejectMayContain: false)
        let product = makeProduct(
            ingredientsText: "Sugar, cocoa butter",
            traces: [" NO:melk "]
        )

        let result = SafetyAnalyzer.analyze(product: product, profile: profile)

        #expect(result.level == .caution)
        #expect(result.findings.first?.severe == false)
    }

    @Test
    func safetyAnalyzerReturnsUnknownWhenProductDataIsMissing() {
        let profile = UserProfile(allergenIDs: ["milk"], rejectMayContain: true)
        let product = makeProduct()

        let result = SafetyAnalyzer.analyze(product: product, profile: profile)

        #expect(result.level == .unknown)
        #expect(result.findings.isEmpty)
    }

    @Test
    func safetyAnalyzerTreatsWhitespaceOnlyIngredientsAsMissingData() {
        let profile = UserProfile(allergenIDs: ["milk"], rejectMayContain: true)
        let product = makeProduct(ingredientsText: "   \n\t  ")

        let result = SafetyAnalyzer.analyze(product: product, profile: profile)

        #expect(result.level == .unknown)
        #expect(result.findings.isEmpty)
    }

    @Test
    func safetyAnalyzerTreatsBlankWarningTagsAsMissingData() {
        let profile = UserProfile(allergenIDs: ["milk"], rejectMayContain: true)
        let product = makeProduct(
            allergens: [" ", "en:"],
            traces: ["\n", "NO:"]
        )

        let result = SafetyAnalyzer.analyze(product: product, profile: profile)

        #expect(result.level == .unknown)
        #expect(result.findings.isEmpty)
    }

    @Test
    func safetyAnalyzerMatchesIngredientKeywordsAsWholeTokens() {
        let profile = UserProfile(allergenIDs: ["eggs"], rejectMayContain: true)
        let compatible = makeProduct(ingredientsText: "Vegetable oil, salt")
        let avoid = makeProduct(ingredientsText: "Sugar, egg powder")

        let compatibleResult = SafetyAnalyzer.analyze(product: compatible, profile: profile)
        let avoidResult = SafetyAnalyzer.analyze(product: avoid, profile: profile)

        #expect(compatibleResult.level == .compatible)
        #expect(avoidResult.level == .avoid)
    }

    @Test
    func safetyAnalyzerDoesNotMatchGlutenFreeAsGlutenIngredient() {
        let profile = UserProfile(allergenIDs: ["gluten"], rejectMayContain: true)
        let product = makeProduct(ingredientsText: "Glutenfri hvetestivelse, vann, glutenfri maltekstrakt (bygg), fiber")

        let result = SafetyAnalyzer.analyze(product: product, profile: profile)

        #expect(result.level == .compatible)
        #expect(result.findings.isEmpty)
    }

    @Test
    func safetyAnalyzerUsesRequestedLanguageForFindingsAndNotes() {
        let profile = UserProfile(allergenIDs: ["milk"], rejectMayContain: true)
        let product = makeProduct(
            ingredientsText: "Sugar, milk powder",
            allergens: ["en:milk"]
        )

        let result = SafetyAnalyzer.analyze(product: product, profile: profile, language: .english)

        #expect(result.level == .avoid)
        #expect(result.findings.first?.allergenName == "Milk")
        #expect(result.findings.first?.reason == "Registered as an ingredient/allergen.")
        #expect(result.note == "Based on registered product data and your profile.")
    }

    @Test
    func alternativeRankingFiltersAvoidProductsAndPrefersCompatibleOnes() {
        let profile = UserProfile(allergenIDs: ["milk"], rejectMayContain: false)
        let source = makeProduct(
            barcode: "source",
            ingredientsText: "Milk chocolate",
            allergens: ["en:milk"],
            categoryLabels: ["Chocolate bars"]
        )
        let compatible = makeProduct(
            barcode: "compatible",
            name: "Dark Bar",
            ingredientsText: "Cocoa mass, sugar",
            allergens: ["en:soybeans"],
            categoryLabels: ["Chocolate bars"],
            lastModifiedAt: Date(timeIntervalSince1970: 200)
        )
        let caution = makeProduct(
            barcode: "caution",
            name: "Nut Bar",
            ingredientsText: "Cocoa mass, sugar",
            traces: ["en:milk"],
            categoryLabels: ["Chocolate bars"],
            lastModifiedAt: Date(timeIntervalSince1970: 300)
        )
        let avoid = makeProduct(
            barcode: "avoid",
            name: "Milk Bar",
            ingredientsText: "Milk, cocoa",
            allergens: ["en:milk"],
            categoryLabels: ["Chocolate bars"],
            lastModifiedAt: Date(timeIntervalSince1970: 400)
        )

        let ranked = AlternativeRankingService.rank(
            candidates: [caution, avoid, compatible],
            comparedTo: source,
            profile: profile
        )

        #expect(ranked.count == 2)
        #expect(ranked.map(\.product.barcode) == ["compatible", "caution"])
    }

    @Test
    func productAssessmentReportsUnknownWithoutProfileWhenProductDataIsMissing() {
        let product = makeProduct()

        let assessment = AlternativeRankingService.assessment(for: product, profile: nil)

        #expect(assessment.result.level == .unknown)
        #expect(assessment.dataQuality == .unknown)
        #expect(assessment.completenessScore == 0)
    }

    @Test
    func productAssessmentReportsHighConfidenceWithoutProfileWhenCoreDataExists() {
        let product = makeProduct(
            ingredientsText: "Cocoa mass, sugar",
            allergens: ["en:soybeans"],
            categoryLabels: ["Chocolate bars"]
        )

        let assessment = AlternativeRankingService.assessment(for: product, profile: nil)

        #expect(assessment.result.level == .unknown)
        #expect(assessment.dataQuality == .highConfidence)
        #expect(assessment.completenessScore == 3)
    }

    @Test
    func productAssessmentIgnoresBlankAllergenAndCategoryValues() {
        let product = makeProduct(
            ingredientsText: "Cocoa mass, sugar",
            allergens: ["  ", "en:"],
            traces: ["\n", "NO:"],
            categoryLabels: ["\t", "  \n  "]
        )

        let assessment = AlternativeRankingService.assessment(for: product, profile: nil)

        #expect(assessment.dataQuality == .limitedInformation)
        #expect(assessment.completenessScore == 1)
    }

    @Test
    func productAssessmentUsesRequestedLanguageForSafetyResult() {
        let profile = UserProfile(allergenIDs: ["milk"], rejectMayContain: true)
        let product = makeProduct(
            ingredientsText: "Sugar, milk powder",
            allergens: ["en:milk"],
            categoryLabels: ["Chocolate bars"]
        )

        let assessment = AlternativeRankingService.assessment(
            for: product,
            profile: profile,
            language: .english
        )

        #expect(assessment.result.level == .avoid)
        #expect(assessment.result.findings.first?.allergenName == "Milk")
        #expect(assessment.result.note == "Based on registered product data and your profile.")
        #expect(assessment.dataQuality == .highConfidence)
    }

    @Test
    func productDataQualityUsesRequestedLanguage() {
        #expect(ProductDataQuality.highConfidence.title(language: .english) == "High data quality")
        #expect(ProductDataQuality.highConfidence.detail(language: .english) == "Ingredient and allergen data are relatively complete.")
        #expect(ProductDataQuality.unknown.title(language: .thai) == "ฐานข้อมูลไม่ชัดเจน")
        #expect(AppText.text(.dataSourceMergedDescription, language: .english) == "Product data is merged from multiple active sources.")
    }

    @Test
    func alternativeLookupOutcomeUsesRequestedLanguage() {
        #expect(AlternativeLookupOutcome.noProfile.message(language: .english) == "Create a profile to get suggestions evaluated against your allergens.")
        #expect(AlternativeLookupOutcome.noMatches.message(language: .thai) == "ไม่พบทางเลือกที่ดีกว่าอย่างชัดเจนจากข้อมูลสินค้าที่มีอยู่")
        #expect(AlternativeLookupOutcome.results([]).message(language: .english).isEmpty)
    }

    @Test
    func scannedProductUpdatesStoredProductData() {
        let existing = makeProduct(
            barcode: "12345678",
            name: "Old Product",
            brands: "Old Brand",
            ingredientsText: "Old ingredients",
            allergens: ["milk"],
            categoryLabels: ["Old category"],
            lastModifiedAt: Date(timeIntervalSince1970: 100),
            lastScanned: Date(timeIntervalSince1970: 200)
        )
        let fetched = ScannedProduct(
            barcode: "12345678",
            sourceProviderID: "food_repo",
            sourceProviderName: "Food Repo",
            sourceTrustLevelRawValue: ProductSourceTrustLevel.verified.rawValue,
            name: "Updated Product",
            brands: "Updated Brand",
            ingredientsText: "Updated ingredients",
            allergens: ["soybeans"],
            traces: ["nuts"],
            categoryLabels: ["Updated category"],
            imageURLString: " file:///tmp/product.jpg ",
            lastModifiedAt: Date(timeIntervalSince1970: 300),
            lastScanned: Date(timeIntervalSince1970: 400)
        )
        let updatedScanDate = Date(timeIntervalSince1970: 500)

        existing.updateProductData(from: fetched, lastScanned: updatedScanDate)

        #expect(existing.sourceProviderID == "food_repo")
        #expect(existing.sourceProviderName == "Food Repo")
        #expect(existing.sourceTrustLevel == .verified)
        #expect(existing.name == "Updated Product")
        #expect(existing.brands == "Updated Brand")
        #expect(existing.ingredientsText == "Updated ingredients")
        #expect(existing.allergens == ["soybeans"])
        #expect(existing.traces == ["nuts"])
        #expect(existing.categoryLabels == ["Updated category"])
        #expect(existing.imageURLString == nil)
        #expect(existing.lastModifiedAt == Date(timeIntervalSince1970: 300))
        #expect(existing.lastScanned == updatedScanDate)
    }

    @Test
    func scannedProductCopyForStoragePreservesProductDataWithNewScanDate() {
        let product = ScannedProduct(
            barcode: "12345678",
            sourceProviderID: "food_repo",
            sourceProviderName: "Food Repo",
            sourceTrustLevelRawValue: ProductSourceTrustLevel.verified.rawValue,
            name: "Product",
            brands: "Brand",
            ingredientsText: "Ingredients",
            allergens: ["soybeans"],
            traces: ["nuts"],
            categoryLabels: ["Category"],
            imageURLString: "https://example.com/product.jpg",
            lastModifiedAt: Date(timeIntervalSince1970: 300),
            lastScanned: Date(timeIntervalSince1970: 400)
        )
        let copiedScanDate = Date(timeIntervalSince1970: 500)

        let copy = product.copyForStorage(lastScanned: copiedScanDate)

        #expect(copy !== product)
        #expect(copy.barcode == product.barcode)
        #expect(copy.sourceProviderID == product.sourceProviderID)
        #expect(copy.sourceProviderName == product.sourceProviderName)
        #expect(copy.sourceTrustLevel == .verified)
        #expect(copy.name == product.name)
        #expect(copy.brands == product.brands)
        #expect(copy.ingredientsText == product.ingredientsText)
        #expect(copy.allergens == product.allergens)
        #expect(copy.traces == product.traces)
        #expect(copy.categoryLabels == product.categoryLabels)
        #expect(copy.imageURLString == product.imageURLString)
        #expect(copy.lastModifiedAt == product.lastModifiedAt)
        #expect(copy.lastScanned == copiedScanDate)
    }

    @Test
    func scannedProductProviderRecordFiltersInvalidImageURL() {
        let product = ScannedProduct(
            barcode: "12345678",
            sourceProviderID: "provider",
            sourceProviderName: "Provider",
            name: "Product",
            brands: "",
            ingredientsText: "Sugar",
            allergens: [],
            traces: [],
            categoryLabels: ["Snacks"],
            imageURLString: "file:///tmp/image.jpg"
        )

        #expect(product.imageURLString == nil)
        #expect(product.providerRecord().imageURLString == nil)
    }

    @Test
    func scannedProductDetectsMergedSourceProviders() {
        let singleSource = makeProduct(sourceProviderName: "Open Food Facts")
        let mergedSource = makeProduct(
            sourceProviderID: "open_food_facts + food_repo",
            sourceProviderName: "Open Food Facts + Food Repo"
        )

        #expect(singleSource.sourceProviderIDs == ["open_food_facts"])
        #expect(singleSource.sourceProviderNames == ["Open Food Facts"])
        #expect(singleSource.hasMergedSourceProviders == false)
        #expect(mergedSource.sourceProviderIDs == ["open_food_facts", "food_repo"])
        #expect(mergedSource.sourceProviderNames == ["Open Food Facts", "Food Repo"])
        #expect(mergedSource.hasMergedSourceProviders == true)
    }

    @Test
    func scannedProductDisplayNameLocalizesUnknownFallbackNames() {
        let norwegianUnknown = makeProduct(name: AppText.text(.unknownProduct, language: .norwegian))
        let blankName = makeProduct(name: "   ")

        #expect(norwegianUnknown.displayName(language: .english) == "Unknown product")
        #expect(norwegianUnknown.displayName(language: .thai) == "สินค้าไม่ทราบชื่อ")
        #expect(blankName.displayName(language: .english) == "Unknown product")
    }

    @Test
    func scannedProductDisplayNamePreservesKnownTrimmedName() {
        let product = makeProduct(name: "  Dark Chocolate  ")

        #expect(product.displayName(language: .thai) == "Dark Chocolate")
    }

    @Test
    func alternativeRankingPrefersMoreCompleteDataWhenSafetyLevelMatches() {
        let profile = UserProfile(allergenIDs: ["milk"], rejectMayContain: true)
        let source = makeProduct(
            barcode: "source",
            ingredientsText: "Milk chocolate",
            allergens: ["en:milk"],
            categoryLabels: ["Chocolate bars", "Snacks"]
        )
        let limited = makeProduct(
            barcode: "limited",
            name: "Candidate A",
            categoryLabels: ["Chocolate bars", "Snacks"],
            lastModifiedAt: Date(timeIntervalSince1970: 500)
        )
        let highConfidence = makeProduct(
            barcode: "high",
            name: "Candidate B",
            ingredientsText: "Cocoa mass, sugar",
            allergens: ["en:soybeans"],
            categoryLabels: ["Chocolate bars", "Snacks"],
            lastModifiedAt: Date(timeIntervalSince1970: 100)
        )

        let ranked = AlternativeRankingService.rank(
            candidates: [limited, highConfidence],
            comparedTo: source,
            profile: profile
        )

        #expect(ranked.map(\.product.barcode) == ["high", "limited"])
        #expect(ranked.first?.assessment.dataQuality == .highConfidence)
    }

    @Test
    func alternativeRankingPrefersStrongerCategoryMatchWhenSafetyLevelMatches() {
        let profile = UserProfile(allergenIDs: ["milk"], rejectMayContain: true)
        let source = makeProduct(
            barcode: "source",
            ingredientsText: "Milk chocolate",
            allergens: ["en:milk"],
            categoryLabels: ["Chocolate bars", "Snacks"]
        )
        let strongerMatch = makeProduct(
            barcode: "stronger",
            name: "Candidate A",
            ingredientsText: "Cocoa mass, sugar",
            allergens: ["en:soybeans"],
            categoryLabels: ["Chocolate bars", "Snacks"],
            lastModifiedAt: Date(timeIntervalSince1970: 100)
        )
        let weakerMatch = makeProduct(
            barcode: "weaker",
            name: "Candidate B",
            ingredientsText: "Cocoa mass, sugar",
            allergens: ["en:soybeans"],
            categoryLabels: ["Chocolate bars"],
            lastModifiedAt: Date(timeIntervalSince1970: 200)
        )

        let ranked = AlternativeRankingService.rank(
            candidates: [weakerMatch, strongerMatch],
            comparedTo: source,
            profile: profile
        )

        #expect(ranked.map(\.product.barcode) == ["stronger", "weaker"])
    }

    @Test
    func alternativeRankingPrefersMoreRecentDataWhenOtherSignalsMatch() {
        let profile = UserProfile(allergenIDs: ["milk"], rejectMayContain: true)
        let source = makeProduct(
            barcode: "source",
            ingredientsText: "Milk chocolate",
            allergens: ["en:milk"],
            categoryLabels: ["Chocolate bars"]
        )
        let older = makeProduct(
            barcode: "older",
            name: "Candidate A",
            ingredientsText: "Cocoa mass, sugar",
            allergens: ["en:soybeans"],
            categoryLabels: ["Chocolate bars"],
            lastModifiedAt: Date(timeIntervalSince1970: 100)
        )
        let newer = makeProduct(
            barcode: "newer",
            name: "Candidate B",
            ingredientsText: "Cocoa mass, sugar",
            allergens: ["en:soybeans"],
            categoryLabels: ["Chocolate bars"],
            lastModifiedAt: Date(timeIntervalSince1970: 200)
        )

        let ranked = AlternativeRankingService.rank(
            candidates: [older, newer],
            comparedTo: source,
            profile: profile
        )

        #expect(ranked.map(\.product.barcode) == ["newer", "older"])
    }

    @Test
    func alternativeRankingTrimsNamesForFinalTieBreaker() {
        let profile = UserProfile(allergenIDs: ["milk"], rejectMayContain: true)
        let source = makeProduct(
            barcode: "source",
            ingredientsText: "Milk chocolate",
            allergens: ["en:milk"],
            categoryLabels: ["Chocolate bars"]
        )
        let first = makeProduct(
            barcode: "first",
            name: " Banana bar ",
            ingredientsText: "Cocoa mass, sugar",
            allergens: ["en:soybeans"],
            categoryLabels: ["Chocolate bars"]
        )
        let second = makeProduct(
            barcode: "second",
            name: "Apple bar",
            ingredientsText: "Cocoa mass, sugar",
            allergens: ["en:soybeans"],
            categoryLabels: ["Chocolate bars"]
        )

        let ranked = AlternativeRankingService.rank(
            candidates: [first, second],
            comparedTo: source,
            profile: profile
        )

        #expect(ranked.map(\.product.barcode) == ["second", "first"])
    }

    @Test
    func alternativeProductServiceChoosesMostSpecificCategoriesFirst() {
        let product = makeProduct(
            categoryLabels: [
                "Snacks",
                "Chocolate bars",
                "Dark chocolate bars",
                "Long  spaced",
                "  ",
                "Chocolate bars",
                " chocolate bars "
            ]
        )

        let categories = AlternativeProductService.categoryCandidates(for: product)

        #expect(categories == ["Dark chocolate bars", "Chocolate bars", "Snacks"])
    }

    @Test
    func alternativeProductServiceFiltersOutUnknownDataCandidates() {
        let profile = UserProfile(allergenIDs: ["milk"], rejectMayContain: true)
        let unknown = makeProduct(
            barcode: "unknown",
            categoryLabels: ["Chocolate bars"]
        )
        let limited = makeProduct(
            barcode: "limited",
            ingredientsText: "Cocoa mass, sugar",
            categoryLabels: ["Chocolate bars"]
        )
        let highConfidence = makeProduct(
            barcode: "high",
            ingredientsText: "Cocoa mass, sugar",
            allergens: ["en:soybeans"],
            categoryLabels: ["Chocolate bars"]
        )

        let filtered = AlternativeProductService.filteredCandidates(
            [unknown, limited, highConfidence],
            for: profile
        )

        #expect(filtered.map(\.barcode) == ["limited", "high"])
    }

    @Test
    func alternativeProductServiceFiltersOutCandidatesWithOnlyBlankMetadata() {
        let profile = UserProfile(allergenIDs: ["milk"], rejectMayContain: true)
        let blankMetadata = makeProduct(
            barcode: "blank",
            ingredientsText: "Cocoa mass, sugar",
            allergens: [" "],
            categoryLabels: [" "]
        )

        let filtered = AlternativeProductService.filteredCandidates(
            [blankMetadata],
            for: profile
        )

        #expect(filtered.isEmpty)
    }

    @Test
    func alternativeProductServiceMergesRelevantCachedCandidates() {
        let source = makeProduct(
            barcode: "source",
            categoryLabels: ["Chocolate bars", "Snacks"]
        )
        let cachedMatch = makeProduct(
            barcode: "cached-match",
            ingredientsText: "Cocoa mass, sugar",
            allergens: ["en:soybeans"],
            categoryLabels: ["Chocolate bars"]
        )
        let cachedMismatch = makeProduct(
            barcode: "cached-mismatch",
            ingredientsText: "Tomatoes, salt",
            allergens: ["en:soybeans"],
            categoryLabels: ["Sauces"]
        )
        let remote = makeProduct(
            barcode: "remote",
            ingredientsText: "Cocoa mass, sugar",
            allergens: ["en:soybeans"],
            categoryLabels: ["Snacks"]
        )

        let merged = AlternativeProductService.mergedCandidates(
            localCandidates: [cachedMatch, cachedMismatch],
            remoteCandidates: [remote],
            comparedTo: source
        )

        #expect(Set(merged.map(\.barcode)) == ["cached-match", "remote"])
    }

    @Test
    func alternativeProductServiceKeepsUsableCachedCandidatesWhenSourceHasNoCategory() {
        let source = makeProduct(
            barcode: "7041610031117",
            ingredientsText: "Hvetemel, vann, gjær",
            allergens: ["en:gluten"]
        )
        let glutenFree = makeProduct(
            barcode: "7330242760558",
            ingredientsText: "Glutenfri hvetestivelse, vann, fiber",
            allergens: ["en:soybeans"]
        )

        let merged = AlternativeProductService.mergedCandidates(
            localCandidates: [glutenFree],
            remoteCandidates: [],
            comparedTo: source
        )

        #expect(merged.map(\.barcode) == ["7330242760558"])
    }

    @Test
    func alternativeProductServiceMatchesCachedCategoriesIgnoringCaseAndWhitespace() {
        let source = makeProduct(
            barcode: "source",
            categoryLabels: ["Chocolate bars"]
        )
        let cachedMatch = makeProduct(
            barcode: "cached-match",
            ingredientsText: "Cocoa mass, sugar",
            allergens: ["en:soybeans"],
            categoryLabels: [" chocolate bars "]
        )
        let cachedCaseMatch = makeProduct(
            barcode: "cached-case-match",
            ingredientsText: "Cocoa mass, sugar",
            allergens: ["en:soybeans"],
            categoryLabels: ["chocolate bars"]
        )
        let cachedMismatch = makeProduct(
            barcode: "cached-mismatch",
            ingredientsText: "Tomatoes, salt",
            allergens: ["en:soybeans"],
            categoryLabels: ["Sauces"]
        )

        let merged = AlternativeProductService.mergedCandidates(
            localCandidates: [cachedMatch, cachedCaseMatch, cachedMismatch],
            remoteCandidates: [],
            comparedTo: source
        )

        #expect(Set(merged.map(\.barcode)) == ["cached-match", "cached-case-match"])
    }

    @Test
    func alternativeProductServicePrefersMoreCompleteVersionOfDuplicateCandidate() {
        let source = makeProduct(
            barcode: "source",
            categoryLabels: ["Chocolate bars"]
        )
        let remote = makeProduct(
            barcode: " shared ",
            ingredientsText: "Cocoa mass, sugar",
            categoryLabels: ["Chocolate bars"],
            lastModifiedAt: Date(timeIntervalSince1970: 100)
        )
        let cached = makeProduct(
            barcode: "shared",
            ingredientsText: "Cocoa mass, sugar",
            allergens: ["en:soybeans"],
            categoryLabels: ["Chocolate bars"],
            lastModifiedAt: Date(timeIntervalSince1970: 200)
        )

        let merged = AlternativeProductService.mergedCandidates(
            localCandidates: [cached],
            remoteCandidates: [remote],
            comparedTo: source
        )

        #expect(merged.count == 1)
        #expect(merged.first?.allergens == ["en:soybeans"])
        #expect(merged.first?.lastModifiedAt == Date(timeIntervalSince1970: 200))
    }

    @Test
    func alternativeRankingTrimsNamesWhenChoosingPreferredDuplicateProduct() {
        let scanDate = Date(timeIntervalSince1970: 300)
        let banana = makeProduct(
            barcode: "shared",
            name: " Banana bar ",
            ingredientsText: "Cocoa mass, sugar",
            allergens: ["en:soybeans"],
            categoryLabels: ["Chocolate bars"],
            lastScanned: scanDate
        )
        let apple = makeProduct(
            barcode: "shared",
            name: "Apple bar",
            ingredientsText: "Cocoa mass, sugar",
            allergens: ["en:soybeans"],
            categoryLabels: ["Chocolate bars"],
            lastScanned: scanDate
        )

        let preferred = AlternativeRankingService.preferredProduct(between: banana, and: apple)

        #expect(preferred.barcode == "shared")
        #expect(preferred.name == "Apple bar")
    }

    @Test
    func alternativeProductServiceFiltersSourceBarcodeIgnoringWhitespace() {
        let source = makeProduct(
            barcode: "source",
            categoryLabels: ["Chocolate bars"]
        )
        let cachedSource = makeProduct(
            barcode: " source ",
            ingredientsText: "Cocoa mass, sugar",
            allergens: ["en:soybeans"],
            categoryLabels: ["Chocolate bars"]
        )
        let remoteSource = makeProduct(
            barcode: "source",
            ingredientsText: "Cocoa mass, sugar",
            allergens: ["en:soybeans"],
            categoryLabels: ["Chocolate bars"]
        )
        let alternative = makeProduct(
            barcode: "alternative",
            ingredientsText: "Cocoa mass, sugar",
            allergens: ["en:soybeans"],
            categoryLabels: ["Chocolate bars"]
        )

        let merged = AlternativeProductService.mergedCandidates(
            localCandidates: [cachedSource],
            remoteCandidates: [remoteSource, alternative],
            comparedTo: source
        )

        #expect(merged.map(\.barcode) == ["alternative"])
    }

    @Test
    func alternativeRankingMarksCandidatesThatExistInHistory() {
        let profile = UserProfile(allergenIDs: ["milk"], rejectMayContain: true)
        let source = makeProduct(
            barcode: "source",
            ingredientsText: "Milk chocolate",
            allergens: ["en:milk"],
            categoryLabels: ["Chocolate bars"]
        )
        let candidate = makeProduct(
            barcode: " history-match ",
            ingredientsText: "Cocoa mass, sugar",
            allergens: ["en:soybeans"],
            categoryLabels: ["Chocolate bars"]
        )

        let ranked = AlternativeRankingService.rank(
            candidates: [candidate],
            comparedTo: source,
            profile: profile,
            localBarcodes: ["history-match"]
        )

        #expect(ranked.count == 1)
        #expect(ranked.first?.isFromHistory == true)
    }

    @Test
    func alternativeRankingIncludesRecommendationReasons() {
        let profile = UserProfile(allergenIDs: ["milk"], rejectMayContain: true)
        let source = makeProduct(
            barcode: "source",
            ingredientsText: "Milk chocolate",
            allergens: ["en:milk"],
            categoryLabels: ["Chocolate bars"]
        )
        let candidate = makeProduct(
            barcode: "candidate",
            ingredientsText: "Cocoa mass, sugar",
            allergens: ["en:soybeans"],
            categoryLabels: ["Chocolate bars"]
        )

        let ranked = AlternativeRankingService.rank(
            candidates: [candidate],
            comparedTo: source,
            profile: profile
        )

        #expect(ranked.count == 1)
        #expect(ranked.first?.recommendationReasons == [
            .alternativeReasonSameCategory,
            .alternativeReasonBetterData,
            .alternativeReasonNoConflicts
        ])
    }

    @Test
    func alternativeRankingUsesRequestedLanguageForCandidateAssessments() {
        let profile = UserProfile(allergenIDs: ["milk"], rejectMayContain: false)
        let source = makeProduct(
            barcode: "source",
            ingredientsText: "Milk chocolate",
            allergens: ["en:milk"],
            categoryLabels: ["Chocolate bars"]
        )
        let candidate = makeProduct(
            barcode: "candidate",
            ingredientsText: "Sugar, cocoa",
            traces: ["en:milk"],
            categoryLabels: ["Chocolate bars"]
        )

        let ranked = AlternativeRankingService.rank(
            candidates: [candidate],
            comparedTo: source,
            profile: profile,
            language: .english
        )

        #expect(ranked.count == 1)
        #expect(ranked.first?.assessment.result.findings.first?.allergenName == "Milk")
        #expect(ranked.first?.assessment.result.findings.first?.reason == "Registered as a possible trace/cross-contamination warning.")
    }

    @Test
    func userProfileDisplayNameFallsBackToLocalizedDefaultWhenEmpty() {
        let profile = UserProfile(name: "   ")

        #expect(profile.displayName(language: .english) == "My profile")
    }

    @Test
    func userProfileDisplayNameLocalizesStoredDefaultName() {
        let profile = UserProfile(name: "Min profil")

        #expect(profile.displayName(language: .english) == "My profile")
        #expect(profile.displayName(language: .thai) == "โปรไฟล์ของฉัน")
    }

    @Test
    func userProfileDetectsDiningNoteContent() {
        let profile = UserProfile(diningNote: "Severe allergy. Please confirm with the kitchen.")

        #expect(profile.hasDiningNote == true)
    }

    @Test
    func userProfileReturnsActiveProfileWhenPresent() {
        let first = UserProfile(name: "First", isActive: false)
        let second = UserProfile(name: "Second", isActive: true)

        let active = UserProfile.activeProfile(from: [first, second])

        #expect(active === second)
    }

    @Test
    func userProfileFallsBackToFirstProfileWhenNoActiveProfileExists() {
        let first = UserProfile(name: "First", isActive: false)
        let second = UserProfile(name: "Second", isActive: false)

        let active = UserProfile.activeProfile(from: [first, second])

        #expect(active === first)
    }

    @Test
    func userProfileSelectsFallbackWhenActiveProfileIsRemoved() {
        let first = UserProfile(name: "First", isActive: true)
        let second = UserProfile(name: "Second", isActive: false)

        let fallback = UserProfile.fallbackActiveProfileAfterRemoving(profile: first, from: [first, second])

        #expect(fallback === second)
    }

    @Test
    func userProfileKeepsExistingActiveProfileWhenDifferentProfileIsRemoved() {
        let first = UserProfile(name: "First", isActive: true)
        let second = UserProfile(name: "Second", isActive: false)

        let fallback = UserProfile.fallbackActiveProfileAfterRemoving(profile: second, from: [first, second])

        #expect(fallback === first)
    }

    @Test
    func productLookupMapsOfflineErrorsSeparately() {
        let mapped = OpenFoodFactsService.mapRequestError(URLError(.notConnectedToInternet))

        #expect(mapped == .offline)
    }

    @Test
    func productLookupMapsTimeoutErrorsSeparately() {
        let mapped = OpenFoodFactsService.mapRequestError(URLError(.timedOut))

        #expect(mapped == .timedOut)
    }

    @Test
    func productLookupMapsServerStatusesSeparately() {
        #expect(OpenFoodFactsService.mapHTTPStatus(500) == .serverIssue)
        #expect(OpenFoodFactsService.mapHTTPStatus(404) == .productNotFound)
        #expect(OpenFoodFactsService.mapHTTPStatus(408) == .timedOut)
        #expect(OpenFoodFactsService.mapHTTPStatus(429) == .serverIssue)
    }

    @Test
    func openFoodFactsNormalizesTagsFromProviderData() {
        let tags = OpenFoodFactsService.normalizedTags([
            " EN:Milk ",
            "no:melk",
            " ",
            "SOY"
        ])

        #expect(tags == ["milk", "melk", "soy"])
    }

    @Test
    func openFoodFactsNormalizesCategoriesFromProviderData() {
        let categories = OpenFoodFactsService.normalizedCategories([
            " Chocolate bars ",
            "chocolate bars",
            " ",
            "Snacks"
        ])

        #expect(categories == ["Chocolate bars", "Snacks"])
    }

    @Test
    func providerProductRecordFiltersInvalidImageURLWhenConverted() {
        let record = ProviderProductRecord(
            providerID: "provider",
            barcode: "12345678",
            name: "Product",
            brands: "",
            ingredientsText: "Sugar",
            allergens: [],
            traces: [],
            categoryLabels: ["Snacks"],
            imageURLString: "file:///tmp/image.jpg",
            lastModifiedAt: nil
        )

        #expect(record.asScannedProduct().imageURLString == nil)
    }

    @Test
    func openFoodFactsBuildsSearchTermsFromNormalizedCategories() {
        #expect(OpenFoodFactsService.searchTerms(for: " Dark-chocolate bars  snacks ") == "Dark chocolate bars snacks")
        #expect(OpenFoodFactsService.searchTerms(for: "  a b cd  ") == "")
    }

    @Test
    func openFoodFactsNormalizesProductNamesFromProviderData() {
        #expect(OpenFoodFactsService.normalizedProductName(" Chocolate Bar ") == "Chocolate Bar")
        #expect(OpenFoodFactsService.normalizedProductName(" \n\t ") == AppText.text(.unknownProduct))
        #expect(OpenFoodFactsService.normalizedProductName(nil) == AppText.text(.unknownProduct))
    }

    @Test
    func openFoodFactsNormalizesTextFieldsFromProviderData() {
        #expect(OpenFoodFactsService.normalizedText(" Brand ") == "Brand")
        #expect(OpenFoodFactsService.normalizedText(" \n\t ") == "")
        #expect(OpenFoodFactsService.normalizedText(nil) == "")
    }

    @Test
    func openFoodFactsNormalizesBarcodeAndOptionalTextFromProviderData() {
        #expect(OpenFoodFactsService.normalizedBarcode(" 12345 ", fallback: " 67890 ") == "12345")
        #expect(OpenFoodFactsService.normalizedBarcode(" ", fallback: " 67890 ") == "67890")
        #expect(OpenFoodFactsService.normalizedBarcode(" 12345 ") == "12345")
        #expect(OpenFoodFactsService.normalizedOptionalText(" https://example.com/image.png ") == "https://example.com/image.png")
        #expect(OpenFoodFactsService.normalizedOptionalText(" ") == nil)
    }

    @Test
    func openFoodFactsIgnoresNegativeTimestamps() {
        #expect(OpenFoodFactsService.date(fromUnixTimestamp: 0) == Date(timeIntervalSince1970: 0))
        #expect(OpenFoodFactsService.date(fromUnixTimestamp: -1) == nil)
        #expect(OpenFoodFactsService.date(fromUnixTimestamp: nil) == nil)
    }

    @Test
    func productCategoryMatchingNormalizesInternalWhitespace() {
        let categories = ProductCategoryMatching.uniqueLabels([
            "Dark  chocolate bars",
            "dark chocolate bars",
            "Snacks"
        ])

        #expect(categories == ["Dark chocolate bars", "Snacks"])
        #expect(ProductCategoryMatching.hasOverlap(["Dark  chocolate bars"], ["dark chocolate bars"]))
    }

    @Test
    func productDataSourceFormattingSplitsAndJoinsMergedSources() {
        let sources = ProductDataSourceFormatting.splitMergedSources(" first + second + first +   ")

        #expect(sources == ["first", "second"])
        #expect(ProductDataSourceFormatting.joinedMergedSources([" first ", "second", "first", " "]) == "first + second")
    }

    @Test
    func productTagFormattingNormalizesProviderTags() {
        let tags = ProductTagFormatting.normalizedTags([
            " EN:Milk ",
            "milk",
            "no:melk",
            "en:",
            "NO:",
            " ",
            "SOY"
        ])

        #expect(tags == ["milk", "melk", "soy"])
    }

    @Test
    func productDataCompletenessDetectsNonBlankValues() {
        #expect(ProductDataCompleteness.normalizedText(" sugar ") == "sugar")
        #expect(ProductDataCompleteness.normalizedText(" \n\t ") == nil)
        #expect(ProductDataCompleteness.normalizedHTTPURLString(" https://example.com/image.png ") == "https://example.com/image.png")
        #expect(ProductDataCompleteness.normalizedHTTPURLString("ftp://example.com/image.png") == nil)
        #expect(ProductDataCompleteness.normalizedHTTPURLString("not a url") == nil)
        #expect(ProductDataCompleteness.hasText(" sugar "))
        #expect(!ProductDataCompleteness.hasText(" \n\t "))
        #expect(ProductDataCompleteness.containsNonBlankValue([" ", "milk"]))
        #expect(!ProductDataCompleteness.containsNonBlankValue([" ", "\n"]))
    }

    @Test
    func productLookupErrorUsesRequestedLanguage() {
        #expect(ProductLookupError.productNotFound.description(language: .english) == "The product was not found in the database.")
        #expect(ProductLookupError.invalidBarcode.description(language: .thai) == "บาร์โค้ดไม่ถูกต้อง")
        #expect(ProductLookupError.dataSourceUnauthorized.description(language: .norwegian) == "Datakilden godtar ikke forespørselen akkurat nå.")
    }

    @Test
    func appMetadataMasksAPIKey() {
        #expect(AppMetadata.maskedAPIKey("abcd1234wxyz") == "abcd…wxyz")
        #expect(AppMetadata.maskedAPIKey("short") == "•••••")
        #expect(AppMetadata.maskedAPIKey("   ") == "••••")
    }

    @Test
    func productLookupAggregatorReturnsFirstAvailableProviderResult() async throws {
        let expected = ProviderProductRecord(
            providerID: "mock",
            barcode: "12345678",
            name: "Mock Product",
            brands: "Mock Brand",
            ingredientsText: "Sugar",
            allergens: [],
            traces: [],
            categoryLabels: ["Snacks"],
            imageURLString: nil,
            lastModifiedAt: nil
        )
        let aggregator = ProductLookupAggregator(
            providers: [
                MockProductDataProvider(productRecord: nil),
                MockProductDataProvider(productRecord: expected)
            ]
        )

        let product = try await aggregator.fetchProduct(barcode: "12345678")

        #expect(product.barcode == expected.barcode)
        #expect(product.name == expected.name)
        #expect(product.categoryLabels == expected.categoryLabels)
    }

    @Test
    func productLookupAggregatorFallsBackWhenProviderAuthorizationFails() async throws {
        let expected = ProviderProductRecord(
            providerID: "open_food_facts",
            providerName: "Open Food Facts",
            barcode: "12345678",
            name: "Fallback Product",
            brands: "Fallback Brand",
            ingredientsText: "Sugar",
            allergens: [],
            traces: [],
            categoryLabels: ["Snacks"],
            imageURLString: nil,
            lastModifiedAt: nil
        )
        let aggregator = ProductLookupAggregator(
            providers: [
                MockProductDataProvider(error: ProductLookupError.dataSourceUnauthorized),
                MockProductDataProvider(productRecord: expected)
            ]
        )

        let product = try await aggregator.fetchProduct(barcode: "12345678")

        #expect(product.sourceProviderName == "Open Food Facts")
        #expect(product.name == "Fallback Product")
    }

    @Test
    func productLookupAggregatorPrefersActionableErrorsOverNotFound() async {
        let aggregator = ProductLookupAggregator(
            providers: [
                MockProductDataProvider(error: ProductLookupError.dataSourceUnauthorized),
                MockProductDataProvider(error: ProductLookupError.productNotFound)
            ]
        )

        do {
            _ = try await aggregator.fetchProduct(barcode: "12345678")
            Issue.record("Expected lookup to fail")
        } catch let error as ProductLookupError {
            #expect(error == .dataSourceUnauthorized)
        } catch {
            Issue.record("Expected ProductLookupError, got \(error)")
        }
    }

    @Test
    func productLookupAggregatorPrefersOfflineErrorsOverServerIssues() async {
        let aggregator = ProductLookupAggregator(
            providers: [
                MockProductDataProvider(error: ProductLookupError.serverIssue),
                MockProductDataProvider(error: ProductLookupError.offline)
            ]
        )

        do {
            _ = try await aggregator.fetchProduct(barcode: "12345678")
            Issue.record("Expected lookup to fail")
        } catch let error as ProductLookupError {
            #expect(error == .offline)
        } catch {
            Issue.record("Expected ProductLookupError, got \(error)")
        }
    }

    @Test
    func productLookupAggregatorPrefersInvalidBarcodeOverNetworkErrors() async {
        let aggregator = ProductLookupAggregator(
            providers: [
                MockProductDataProvider(error: ProductLookupError.offline),
                MockProductDataProvider(error: ProductLookupError.invalidBarcode)
            ]
        )

        do {
            _ = try await aggregator.fetchProduct(barcode: "abc")
            Issue.record("Expected lookup to fail")
        } catch let error as ProductLookupError {
            #expect(error == .invalidBarcode)
        } catch {
            Issue.record("Expected ProductLookupError, got \(error)")
        }
    }

    @Test
    func productLookupAggregatorMergesDuplicateProductRecordsConservatively() async throws {
        let first = ProviderProductRecord(
            providerID: "first",
            barcode: "12345678",
            name: "Chocolate Bar",
            brands: "",
            ingredientsText: "Sugar, cocoa mass",
            allergens: ["milk"],
            traces: [],
            categoryLabels: ["Chocolate bars"],
            imageURLString: nil,
            lastModifiedAt: Date(timeIntervalSince1970: 100)
        )
        let second = ProviderProductRecord(
            providerID: "second",
            barcode: "12345678",
            name: "Chocolate Bar",
            brands: "Brand Name",
            ingredientsText: "Sugar, cocoa mass, cocoa butter",
            allergens: [],
            traces: ["nuts"],
            categoryLabels: ["Snacks"],
            imageURLString: "https://example.com/image.png",
            lastModifiedAt: Date(timeIntervalSince1970: 200)
        )
        let aggregator = ProductLookupAggregator(
            providers: [
                MockProductDataProvider(productRecord: first),
                MockProductDataProvider(productRecord: second)
            ]
        )

        let product = try await aggregator.fetchProduct(barcode: "12345678")

        #expect(product.name == "Chocolate Bar")
        #expect(product.brands == "Brand Name")
        #expect(product.ingredientsText == "Sugar, cocoa mass, cocoa butter")
        #expect(product.allergens == ["milk"])
        #expect(product.traces == ["nuts"])
        #expect(product.categoryLabels == ["Chocolate bars", "Snacks"])
        #expect(product.sourceProviderID == "first + second")
        #expect(product.sourceProviderName == "first + second")
        #expect(product.imageURLString == "https://example.com/image.png")
        #expect(product.lastModifiedAt == Date(timeIntervalSince1970: 200))
    }

    @Test
    func productLookupAggregatorTrimsMergedProductBarcode() async throws {
        let first = ProviderProductRecord(
            providerID: "first",
            barcode: " 12345678 ",
            name: "Chocolate Bar",
            brands: "",
            ingredientsText: "Sugar",
            allergens: [],
            traces: [],
            categoryLabels: ["Chocolate bars"],
            imageURLString: nil,
            lastModifiedAt: nil
        )
        let second = ProviderProductRecord(
            providerID: "second",
            barcode: "12345678",
            name: "Chocolate Bar",
            brands: "Brand",
            ingredientsText: "Sugar",
            allergens: [],
            traces: [],
            categoryLabels: ["Chocolate bars"],
            imageURLString: nil,
            lastModifiedAt: nil
        )
        let aggregator = ProductLookupAggregator(
            providers: [
                MockProductDataProvider(productRecord: first),
                MockProductDataProvider(productRecord: second)
            ]
        )

        let product = try await aggregator.fetchProduct(barcode: "12345678")

        #expect(product.barcode == "12345678")
    }

    @Test
    func productLookupAggregatorTrimsNamesWhenChoosingPreferredRecord() async throws {
        let first = ProviderProductRecord(
            providerID: "first",
            barcode: "12345678",
            name: " Banana Bar ",
            brands: "",
            ingredientsText: "Sugar",
            allergens: [],
            traces: [],
            categoryLabels: [],
            imageURLString: nil,
            lastModifiedAt: nil
        )
        let second = ProviderProductRecord(
            providerID: "second",
            barcode: "12345678",
            name: "Apple Bar",
            brands: "",
            ingredientsText: "Sugar",
            allergens: [],
            traces: [],
            categoryLabels: [],
            imageURLString: nil,
            lastModifiedAt: nil
        )
        let aggregator = ProductLookupAggregator(
            providers: [
                MockProductDataProvider(productRecord: first),
                MockProductDataProvider(productRecord: second)
            ]
        )

        let product = try await aggregator.fetchProduct(barcode: "12345678")

        #expect(product.name == "Apple Bar")
    }

    @Test
    func productLookupAggregatorIgnoresBlankValuesWhenChoosingPreferredRecord() async throws {
        let blankMetadata = ProviderProductRecord(
            providerID: "blank",
            barcode: "12345678",
            name: "Blank Metadata",
            brands: "",
            ingredientsText: "Sugar",
            allergens: [" ", "en:"],
            traces: ["NO:"],
            categoryLabels: [" ", " \n "],
            imageURLString: nil,
            lastModifiedAt: nil
        )
        let realMetadata = ProviderProductRecord(
            providerID: "real",
            barcode: "12345678",
            name: "Real Metadata",
            brands: "",
            ingredientsText: "Sugar",
            allergens: ["milk"],
            traces: [],
            categoryLabels: ["Chocolate bars"],
            imageURLString: nil,
            lastModifiedAt: nil
        )
        let aggregator = ProductLookupAggregator(
            providers: [
                MockProductDataProvider(productRecord: blankMetadata),
                MockProductDataProvider(productRecord: realMetadata)
            ]
        )

        let product = try await aggregator.fetchProduct(barcode: "12345678")

        #expect(product.name == "Real Metadata")
        #expect(product.allergens == ["milk"])
        #expect(product.categoryLabels == ["Chocolate bars"])
    }

    @Test
    func productLookupAggregatorTrimsPreferredMergedTextFields() async throws {
        let first = ProviderProductRecord(
            providerID: "first",
            barcode: "12345678",
            name: " Chocolate Bar ",
            brands: " ",
            ingredientsText: " Sugar ",
            allergens: [],
            traces: [],
            categoryLabels: ["Chocolate bars"],
            imageURLString: nil,
            lastModifiedAt: nil
        )
        let second = ProviderProductRecord(
            providerID: "second",
            barcode: "12345678",
            name: "Chocolate Bar",
            brands: " Brand Name ",
            ingredientsText: " Sugar, cocoa mass ",
            allergens: [],
            traces: [],
            categoryLabels: ["Chocolate bars"],
            imageURLString: nil,
            lastModifiedAt: nil
        )
        let aggregator = ProductLookupAggregator(
            providers: [
                MockProductDataProvider(productRecord: first),
                MockProductDataProvider(productRecord: second)
            ]
        )

        let product = try await aggregator.fetchProduct(barcode: "12345678")

        #expect(product.name == "Chocolate Bar")
        #expect(product.brands == "Brand Name")
        #expect(product.ingredientsText == "Sugar, cocoa mass")
    }

    @Test
    func productLookupAggregatorTrimsMergedWarningValues() async throws {
        let first = ProviderProductRecord(
            providerID: "first",
            barcode: "12345678",
            name: "Chocolate Bar",
            brands: "",
            ingredientsText: "Sugar",
            allergens: ["milk", " milk ", " "],
            traces: [],
            categoryLabels: ["Chocolate bars"],
            imageURLString: nil,
            lastModifiedAt: nil
        )
        let second = ProviderProductRecord(
            providerID: "second",
            barcode: "12345678",
            name: "Chocolate Bar",
            brands: "",
            ingredientsText: "Sugar",
            allergens: [],
            traces: [" nuts "],
            categoryLabels: ["Chocolate bars"],
            imageURLString: nil,
            lastModifiedAt: nil
        )
        let aggregator = ProductLookupAggregator(
            providers: [
                MockProductDataProvider(productRecord: first),
                MockProductDataProvider(productRecord: second)
            ]
        )

        let product = try await aggregator.fetchProduct(barcode: "12345678")

        #expect(product.allergens == ["milk"])
        #expect(product.traces == ["nuts"])
    }

    @Test
    func productLookupAggregatorDeduplicatesMergedCategoriesIgnoringCaseAndWhitespace() async throws {
        let first = ProviderProductRecord(
            providerID: "first",
            barcode: "12345678",
            name: "Chocolate Bar",
            brands: "",
            ingredientsText: "Cocoa mass",
            allergens: [],
            traces: [],
            categoryLabels: ["Chocolate bars", "Snacks"],
            imageURLString: nil,
            lastModifiedAt: nil
        )
        let second = ProviderProductRecord(
            providerID: "second",
            barcode: "12345678",
            name: "Chocolate Bar",
            brands: "",
            ingredientsText: "Cocoa mass, sugar",
            allergens: [],
            traces: [],
            categoryLabels: [" chocolate bars ", "snacks", "Organic"],
            imageURLString: nil,
            lastModifiedAt: nil
        )
        let aggregator = ProductLookupAggregator(
            providers: [
                MockProductDataProvider(productRecord: first),
                MockProductDataProvider(productRecord: second)
            ]
        )

        let product = try await aggregator.fetchProduct(barcode: "12345678")

        #expect(product.categoryLabels == ["Chocolate bars", "Snacks", "Organic"])
    }

    @Test
    func productLookupAggregatorIgnoresInvalidImageURLsWhenMergingRecords() async throws {
        let invalidImage = ProviderProductRecord(
            providerID: "first",
            barcode: "12345678",
            name: "Chocolate Bar",
            brands: "",
            ingredientsText: "Cocoa mass",
            allergens: [],
            traces: [],
            categoryLabels: ["Chocolate bars"],
            imageURLString: "file:///tmp/image.jpg",
            lastModifiedAt: nil
        )
        let validImage = ProviderProductRecord(
            providerID: "second",
            barcode: "12345678",
            name: "Chocolate Bar",
            brands: "",
            ingredientsText: "Cocoa mass",
            allergens: [],
            traces: [],
            categoryLabels: ["Chocolate bars"],
            imageURLString: " https://example.com/image.jpg ",
            lastModifiedAt: nil
        )
        let aggregator = ProductLookupAggregator(
            providers: [
                MockProductDataProvider(productRecord: invalidImage),
                MockProductDataProvider(productRecord: validImage)
            ]
        )

        let product = try await aggregator.fetchProduct(barcode: "12345678")

        #expect(product.imageURLString == "https://example.com/image.jpg")
    }

    @Test
    func productLookupAggregatorKeepsHighestTrustLevelWhenMergingRecords() async throws {
        let community = ProviderProductRecord(
            providerID: "community",
            providerName: "Community Source",
            sourceTrustLevel: .community,
            barcode: "12345678",
            name: "Chocolate Bar",
            brands: "",
            ingredientsText: "Sugar, cocoa mass",
            allergens: [],
            traces: [],
            categoryLabels: ["Chocolate bars"],
            imageURLString: nil,
            lastModifiedAt: nil
        )
        let verified = ProviderProductRecord(
            providerID: "verified",
            providerName: "Verified Source",
            sourceTrustLevel: .verified,
            barcode: "12345678",
            name: "Chocolate Bar",
            brands: "",
            ingredientsText: "Sugar, cocoa mass",
            allergens: [],
            traces: [],
            categoryLabels: ["Chocolate bars"],
            imageURLString: nil,
            lastModifiedAt: nil
        )
        let aggregator = ProductLookupAggregator(
            providers: [
                MockProductDataProvider(productRecord: community),
                MockProductDataProvider(productRecord: verified)
            ]
        )

        let product = try await aggregator.fetchProduct(barcode: "12345678")

        #expect(product.sourceTrustLevel == .verified)
        #expect(product.sourceProviderName == "Community Source + Verified Source")
    }

    @Test
    func productLookupAggregatorNormalizesMergedProviderSources() async throws {
        let first = ProviderProductRecord(
            providerID: " first ",
            providerName: " First Source ",
            barcode: "12345678",
            name: "Chocolate Bar",
            brands: "",
            ingredientsText: "Sugar",
            allergens: [],
            traces: [],
            categoryLabels: ["Chocolate bars"],
            imageURLString: nil,
            lastModifiedAt: nil
        )
        let second = ProviderProductRecord(
            providerID: "first",
            providerName: " ",
            barcode: "12345678",
            name: "Chocolate Bar",
            brands: "",
            ingredientsText: "Sugar",
            allergens: [],
            traces: [],
            categoryLabels: ["Chocolate bars"],
            imageURLString: nil,
            lastModifiedAt: nil
        )
        let aggregator = ProductLookupAggregator(
            providers: [
                MockProductDataProvider(productRecord: first),
                MockProductDataProvider(productRecord: second)
            ]
        )

        let product = try await aggregator.fetchProduct(barcode: "12345678")

        #expect(product.sourceProviderID == "first")
        #expect(product.sourceProviderName == "First Source")
    }

    @Test
    func productLookupAggregatorMergesDuplicateAlternativeCandidatesByPreferredRecord() async throws {
        let older = ProviderProductRecord(
            providerID: "first",
            barcode: "shared",
            name: "Candidate",
            brands: "Brand",
            ingredientsText: "Cocoa mass, sugar",
            allergens: [],
            traces: [],
            categoryLabels: ["Chocolate bars"],
            imageURLString: nil,
            lastModifiedAt: Date(timeIntervalSince1970: 100)
        )
        let richer = ProviderProductRecord(
            providerID: "second",
            barcode: "shared",
            name: "Candidate",
            brands: "Brand",
            ingredientsText: "Cocoa mass, sugar",
            allergens: ["soybeans"],
            traces: [],
            categoryLabels: ["Chocolate bars"],
            imageURLString: nil,
            lastModifiedAt: Date(timeIntervalSince1970: 200)
        )
        let unique = ProviderProductRecord(
            providerID: "second",
            barcode: "unique",
            name: "Unique",
            brands: "Brand",
            ingredientsText: "Corn",
            allergens: [],
            traces: [],
            categoryLabels: ["Chocolate bars"],
            imageURLString: nil,
            lastModifiedAt: nil
        )
        let aggregator = ProductLookupAggregator(
            providers: [
                MockProductDataProvider(alternativeRecords: [older]),
                MockProductDataProvider(alternativeRecords: [richer, unique])
            ]
        )

        let candidates = try await aggregator.fetchAlternativeCandidates(
            categoryNames: ["Chocolate bars"],
            excludingBarcode: "source"
        )

        #expect(candidates.count == 2)
        let shared = candidates.first { $0.barcode == "shared" }
        #expect(shared?.sourceProviderID == "first + second")
        #expect(shared?.sourceProviderName == "first + second")
        #expect(shared?.allergens == ["soybeans"])
        #expect(candidates.contains(where: { $0.barcode == "unique" }))
    }

    @Test
    func productLookupAggregatorMergesAlternativeCandidatesWithUnionOfWarnings() async throws {
        let first = ProviderProductRecord(
            providerID: "first",
            barcode: "shared",
            name: "Candidate",
            brands: "",
            ingredientsText: "Corn",
            allergens: ["milk"],
            traces: [],
            categoryLabels: ["Snacks"],
            imageURLString: nil,
            lastModifiedAt: Date(timeIntervalSince1970: 100)
        )
        let second = ProviderProductRecord(
            providerID: "second",
            barcode: "shared",
            name: "Candidate",
            brands: "Brand",
            ingredientsText: "Corn, salt",
            allergens: [],
            traces: ["peanuts"],
            categoryLabels: ["Chips"],
            imageURLString: nil,
            lastModifiedAt: Date(timeIntervalSince1970: 150)
        )
        let aggregator = ProductLookupAggregator(
            providers: [
                MockProductDataProvider(alternativeRecords: [first]),
                MockProductDataProvider(alternativeRecords: [second])
            ]
        )

        let candidates = try await aggregator.fetchAlternativeCandidates(
            categoryNames: ["Snacks"],
            excludingBarcode: "source"
        )

        #expect(candidates.count == 1)
        #expect(candidates.first?.ingredientsText == "Corn, salt")
        #expect(candidates.first?.brands == "Brand")
        #expect(candidates.first?.allergens == ["milk"])
        #expect(candidates.first?.traces == ["peanuts"])
        #expect(candidates.first?.categoryLabels == ["Snacks", "Chips"])
    }

    @Test
    func productLookupAggregatorNormalizesAlternativeCategoriesBeforeProviderLookup() async throws {
        let candidate = ProviderProductRecord(
            providerID: "mock",
            barcode: "candidate",
            name: "Candidate",
            brands: "",
            ingredientsText: "Corn",
            allergens: [],
            traces: [],
            categoryLabels: ["Chocolate bars"],
            imageURLString: nil,
            lastModifiedAt: nil
        )
        let aggregator = ProductLookupAggregator(
            providers: [
                MockProductDataProvider(
                    alternativeRecords: [candidate],
                    expectedAlternativeCategoryNames: ["Chocolate bars", "Snacks"]
                )
            ]
        )

        let candidates = try await aggregator.fetchAlternativeCandidates(
            categoryNames: [" Chocolate bars ", "chocolate bars", " ", "Snacks"],
            excludingBarcode: "source"
        )

        #expect(candidates.map(\.barcode) == ["candidate"])
    }

    @Test
    func productLookupAggregatorReturnsNoAlternativesWhenMaxResultsIsZero() async throws {
        let aggregator = ProductLookupAggregator(
            providers: [
                MockProductDataProvider(error: ProductLookupError.serverIssue)
            ]
        )

        let candidates = try await aggregator.fetchAlternativeCandidates(
            categoryNames: ["Chocolate bars"],
            excludingBarcode: "source",
            maxResults: 0
        )

        #expect(candidates.isEmpty)
    }

    @Test
    func productLookupAggregatorClampsAlternativeLimitPerCategory() async throws {
        let candidate = ProviderProductRecord(
            providerID: "provider",
            barcode: "candidate",
            name: "Candidate",
            brands: "",
            ingredientsText: "Sugar",
            allergens: [],
            traces: [],
            categoryLabels: ["Chocolate bars"],
            imageURLString: nil,
            lastModifiedAt: nil
        )
        let aggregator = ProductLookupAggregator(
            providers: [
                MockProductDataProvider(
                    alternativeRecords: [candidate],
                    expectedAlternativeLimitPerCategory: 1
                )
            ]
        )

        let candidates = try await aggregator.fetchAlternativeCandidates(
            categoryNames: ["Chocolate bars"],
            excludingBarcode: "source",
            limitPerCategory: -4,
            maxResults: 3
        )

        #expect(candidates.map(\.barcode) == ["candidate"])
    }

    @Test
    func productLookupAggregatorCapsMergedAlternativeResults() async throws {
        func candidate(_ barcode: String, providerID: String) -> ProviderProductRecord {
            ProviderProductRecord(
                providerID: providerID,
                barcode: barcode,
                name: "Candidate \(barcode)",
                brands: "",
                ingredientsText: "Sugar",
                allergens: [],
                traces: [],
                categoryLabels: ["Chocolate bars"],
                imageURLString: nil,
                lastModifiedAt: nil
            )
        }

        let aggregator = ProductLookupAggregator(
            providers: [
                MockProductDataProvider(alternativeRecords: [
                    candidate("first", providerID: "first-provider"),
                    candidate("second", providerID: "first-provider")
                ]),
                MockProductDataProvider(alternativeRecords: [
                    candidate("third", providerID: "second-provider"),
                    candidate("fourth", providerID: "second-provider")
                ])
            ]
        )

        let candidates = try await aggregator.fetchAlternativeCandidates(
            categoryNames: ["Chocolate bars"],
            excludingBarcode: "source",
            maxResults: 2
        )

        #expect(candidates.map(\.barcode) == ["first", "second"])
    }

    @Test
    func productLookupAggregatorFiltersExcludedAlternativeBarcode() async throws {
        func candidate(_ barcode: String) -> ProviderProductRecord {
            ProviderProductRecord(
                providerID: "provider",
                barcode: barcode,
                name: "Candidate \(barcode)",
                brands: "",
                ingredientsText: "Sugar",
                allergens: [],
                traces: [],
                categoryLabels: ["Chocolate bars"],
                imageURLString: nil,
                lastModifiedAt: nil
            )
        }

        let aggregator = ProductLookupAggregator(
            providers: [
                MockProductDataProvider(alternativeRecords: [
                    candidate(" source "),
                    candidate("alternative")
                ])
            ]
        )

        let candidates = try await aggregator.fetchAlternativeCandidates(
            categoryNames: ["Chocolate bars"],
            excludingBarcode: "source"
        )

        #expect(candidates.map(\.barcode) == ["alternative"])
    }

    @Test
    func productLookupAggregatorMergesAlternativeBarcodesIgnoringWhitespace() async throws {
        let first = ProviderProductRecord(
            providerID: "first",
            barcode: " shared ",
            name: "Candidate",
            brands: "",
            ingredientsText: "Sugar",
            allergens: ["milk"],
            traces: [],
            categoryLabels: ["Chocolate bars"],
            imageURLString: nil,
            lastModifiedAt: nil
        )
        let second = ProviderProductRecord(
            providerID: "second",
            barcode: "shared",
            name: "Candidate",
            brands: "",
            ingredientsText: "Sugar",
            allergens: [],
            traces: ["nuts"],
            categoryLabels: ["Chocolate bars"],
            imageURLString: nil,
            lastModifiedAt: nil
        )
        let aggregator = ProductLookupAggregator(
            providers: [
                MockProductDataProvider(alternativeRecords: [first]),
                MockProductDataProvider(alternativeRecords: [second])
            ]
        )

        let candidates = try await aggregator.fetchAlternativeCandidates(
            categoryNames: ["Chocolate bars"],
            excludingBarcode: "source"
        )

        #expect(candidates.count == 1)
        #expect(candidates.first?.allergens == ["milk"])
        #expect(candidates.first?.traces == ["nuts"])
    }

    @Test
    func productLookupAggregatorPrefersActionableAlternativeErrorsOverNotFound() async {
        let aggregator = ProductLookupAggregator(
            providers: [
                MockProductDataProvider(error: ProductLookupError.productNotFound),
                MockProductDataProvider(error: ProductLookupError.dataSourceUnauthorized)
            ]
        )

        do {
            _ = try await aggregator.fetchAlternativeCandidates(
                categoryNames: ["Chocolate bars"],
                excludingBarcode: "source"
            )
            Issue.record("Expected alternative lookup to fail")
        } catch let error as ProductLookupError {
            #expect(error == .dataSourceUnauthorized)
        } catch {
            Issue.record("Expected ProductLookupError, got \(error)")
        }
    }

    @Test
    func productLookupAggregatorReportsOnlyOpenFoodFactsSourceStatus() {
        let statuses = ProductLookupAggregator.sourceStatuses()
        let openFoodFacts = statuses.first { $0.id == OpenFoodFactsService.shared.providerID }
        let foodRepo = statuses.first { $0.id == FoodRepoService.shared.providerID }

        #expect(statuses.count == 1)
        #expect(openFoodFacts?.isEnabled == true)
        #expect(openFoodFacts?.supportsAlternativeSearch == true)
        #expect(foodRepo == nil)
    }

    @Test
    func foodRepoServiceIsDisabledCompatibilityStub() async throws {
        #expect(FoodRepoService.shared.isEnabled == false)
        #expect(FoodRepoService.shared.supportsAlternativeSearch == false)
        #expect(await FoodRepoService.shared.validateAPIKey() == false)
        #expect(try await FoodRepoService.shared.fetchProductRecord(barcode: "7612345678901") == nil)
        #expect(try await FoodRepoService.shared.fetchAlternativeCandidateRecords(
            categoryNames: ["Chocolate bars"],
            excludingBarcode: "7612345678901",
            limitPerCategory: 12,
            maxResults: 24
        ).isEmpty)
    }

    private func makeProduct(
        barcode: String = UUID().uuidString,
        sourceProviderID: String = "open_food_facts",
        sourceProviderName: String = "Open Food Facts",
        name: String = "Test Product",
        brands: String = "Test Brand",
        ingredientsText: String = "",
        allergens: [String] = [],
        traces: [String] = [],
        categoryLabels: [String] = [],
        lastModifiedAt: Date? = nil,
        lastScanned: Date = .now
    ) -> ScannedProduct {
        ScannedProduct(
            barcode: barcode,
            sourceProviderID: sourceProviderID,
            sourceProviderName: sourceProviderName,
            name: name,
            brands: brands,
            ingredientsText: ingredientsText,
            allergens: allergens,
            traces: traces,
            categoryLabels: categoryLabels,
            imageURLString: nil,
            lastModifiedAt: lastModifiedAt,
            lastScanned: lastScanned
        )
    }
}

@MainActor
private struct MockProductDataProvider: ProductDataProvider {
    let providerID: String
    let displayName: String
    let isEnabled: Bool
    let supportsAlternativeSearch: Bool
    let sourceTrustLevel: ProductSourceTrustLevel
    let productRecord: ProviderProductRecord?
    let alternativeRecords: [ProviderProductRecord]
    let expectedAlternativeCategoryNames: [String]?
    let expectedAlternativeLimitPerCategory: Int?
    let expectedAlternativeMaxResults: Int?
    let error: Error?

    init(
        providerID: String = UUID().uuidString,
        displayName: String = "Mock Provider",
        isEnabled: Bool = true,
        supportsAlternativeSearch: Bool = true,
        sourceTrustLevel: ProductSourceTrustLevel = .community,
        productRecord: ProviderProductRecord? = nil,
        alternativeRecords: [ProviderProductRecord] = [],
        expectedAlternativeCategoryNames: [String]? = nil,
        expectedAlternativeLimitPerCategory: Int? = nil,
        expectedAlternativeMaxResults: Int? = nil,
        error: Error? = nil
    ) {
        self.providerID = providerID
        self.displayName = displayName
        self.isEnabled = isEnabled
        self.supportsAlternativeSearch = supportsAlternativeSearch
        self.sourceTrustLevel = sourceTrustLevel
        self.productRecord = productRecord
        self.alternativeRecords = alternativeRecords
        self.expectedAlternativeCategoryNames = expectedAlternativeCategoryNames
        self.expectedAlternativeLimitPerCategory = expectedAlternativeLimitPerCategory
        self.expectedAlternativeMaxResults = expectedAlternativeMaxResults
        self.error = error
    }

    func fetchProductRecord(barcode: String) async throws -> ProviderProductRecord? {
        if let error {
            throw error
        }

        return productRecord
    }

    func fetchAlternativeCandidateRecords(
        categoryNames: [String],
        excludingBarcode barcode: String,
        limitPerCategory: Int,
        maxResults: Int
    ) async throws -> [ProviderProductRecord] {
        if let expectedAlternativeCategoryNames {
            #expect(categoryNames == expectedAlternativeCategoryNames)
        }
        if let expectedAlternativeLimitPerCategory {
            #expect(limitPerCategory == expectedAlternativeLimitPerCategory)
        }
        if let expectedAlternativeMaxResults {
            #expect(maxResults == expectedAlternativeMaxResults)
        }

        if let error {
            throw error
        }

        return Array(alternativeRecords.prefix(maxResults))
    }
}
