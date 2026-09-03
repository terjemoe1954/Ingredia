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
        #expect(product.imageURLString == "https://example.com/image.png")
        #expect(product.lastModifiedAt == Date(timeIntervalSince1970: 200))
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
        #expect(candidates.first(where: { $0.barcode == "shared" })?.allergens == ["soybeans"])
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
    func foodRepoProductDecodesFromAttributesEnvelope() throws {
        let data = Data(
            """
            {
              "data": [
                {
                  "id": "1",
                  "type": "products",
                  "attributes": {
                    "barcode": "7612345678901",
                    "display_name_translations": {
                      "en": "Test Product"
                    },
                    "ingredients_translations": {
                      "en": "Sugar, cocoa mass"
                    },
                    "images": [
                      {
                        "medium": "https://example.com/image.jpg"
                      }
                    ],
                    "updated_at": "2026-08-31T12:00:00.000Z"
                  }
                }
              ]
            }
            """.utf8
        )

        let decoded = try JSONDecoder().decode(FoodRepoProductListResponse.self, from: data)

        #expect(decoded.data.count == 1)
        #expect(decoded.data.first?.barcode == "7612345678901")
        #expect(decoded.data.first?.displayNameTranslations["en"] == "Test Product")
        #expect(decoded.data.first?.ingredientsTranslations["en"] == "Sugar, cocoa mass")
        #expect(decoded.data.first?.images.first?.medium == "https://example.com/image.jpg")
    }

    @Test
    func foodRepoProductDecodesFromFlatProductShape() throws {
        let data = Data(
            """
            {
              "data": [
                {
                  "barcode": "7612345678901",
                  "display_name_translations": {
                    "en": "Flat Product"
                  },
                  "ingredients_translations": {
                    "en": "Oats, salt"
                  },
                  "images": [],
                  "updated_at": "2026-08-31T12:00:00.000Z"
                }
              ]
            }
            """.utf8
        )

        let decoded = try JSONDecoder().decode(FoodRepoProductListResponse.self, from: data)

        #expect(decoded.data.count == 1)
        #expect(decoded.data.first?.barcode == "7612345678901")
        #expect(decoded.data.first?.displayNameTranslations["en"] == "Flat Product")
        #expect(decoded.data.first?.ingredientsTranslations["en"] == "Oats, salt")
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

@MainActor
private struct MockProductDataProvider: ProductDataProvider {
    let providerID: String
    let displayName: String
    let isEnabled: Bool
    let supportsAlternativeSearch: Bool
    let sourceTrustLevel: ProductSourceTrustLevel
    let productRecord: ProviderProductRecord?
    let alternativeRecords: [ProviderProductRecord]
    let error: Error?

    init(
        providerID: String = UUID().uuidString,
        displayName: String = "Mock Provider",
        isEnabled: Bool = true,
        supportsAlternativeSearch: Bool = true,
        sourceTrustLevel: ProductSourceTrustLevel = .community,
        productRecord: ProviderProductRecord? = nil,
        alternativeRecords: [ProviderProductRecord] = [],
        error: Error? = nil
    ) {
        self.providerID = providerID
        self.displayName = displayName
        self.isEnabled = isEnabled
        self.supportsAlternativeSearch = supportsAlternativeSearch
        self.sourceTrustLevel = sourceTrustLevel
        self.productRecord = productRecord
        self.alternativeRecords = alternativeRecords
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
        if let error {
            throw error
        }

        return Array(alternativeRecords.prefix(maxResults))
    }
}
