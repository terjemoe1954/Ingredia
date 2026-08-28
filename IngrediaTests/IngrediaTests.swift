//
//  IngrediaTests.swift
//  IngrediaTests
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
    func safetyAnalyzerReturnsUnknownWhenProductDataIsMissing() {
        let profile = UserProfile(allergenIDs: ["milk"], rejectMayContain: true)
        let product = makeProduct()

        let result = SafetyAnalyzer.analyze(product: product, profile: profile)

        #expect(result.level == .unknown)
        #expect(result.findings.isEmpty)
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
    func alternativeProductServiceChoosesMostSpecificCategoriesFirst() {
        let product = makeProduct(
            categoryLabels: [
                "Snacks",
                "Chocolate bars",
                "Dark chocolate bars",
                "  ",
                "Chocolate bars"
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
    func alternativeProductServicePrefersMoreCompleteVersionOfDuplicateCandidate() {
        let source = makeProduct(
            barcode: "source",
            categoryLabels: ["Chocolate bars"]
        )
        let remote = makeProduct(
            barcode: "shared",
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
    func alternativeRankingMarksCandidatesThatExistInHistory() {
        let profile = UserProfile(allergenIDs: ["milk"], rejectMayContain: true)
        let source = makeProduct(
            barcode: "source",
            ingredientsText: "Milk chocolate",
            allergens: ["en:milk"],
            categoryLabels: ["Chocolate bars"]
        )
        let candidate = makeProduct(
            barcode: "history-match",
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
    func userProfileDisplayNameFallsBackToLocalizedDefaultWhenEmpty() {
        let profile = UserProfile(name: "   ")

        #expect(profile.displayName(language: .english) == "My profile")
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
        #expect(OpenFoodFactsService.mapHTTPStatus(429) == .badResponse)
    }

    private func makeProduct(
        barcode: String = UUID().uuidString,
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
