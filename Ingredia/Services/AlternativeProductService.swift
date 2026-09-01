import Foundation

enum ProductDataQuality {
    case highConfidence
    case limitedInformation
    case unknown

    var title: String {
        switch self {
        case .highConfidence:
            return AppText.text(.dataQualityHigh)
        case .limitedInformation:
            return AppText.text(.dataQualityLimited)
        case .unknown:
            return AppText.text(.dataQualityUnknown)
        }
    }

    var detail: String {
        switch self {
        case .highConfidence:
            return AppText.text(.dataQualityHighDetail)
        case .limitedInformation:
            return AppText.text(.dataQualityLimitedDetail)
        case .unknown:
            return AppText.text(.dataQualityUnknownDetail)
        }
    }
}

struct ProductSafetyAssessment {
    let result: SafetyResult
    let dataQuality: ProductDataQuality
    let completenessScore: Int
}

struct AlternativeProduct: Identifiable {
    let product: ScannedProduct
    let assessment: ProductSafetyAssessment
    let categoryMatchDepth: Int
    let isFromHistory: Bool
    let recommendationReasons: [AppTextKey]

    var id: String { product.barcode }
}

enum AlternativeLookupOutcome {
    case noProfile
    case sourceProductCompatible
    case insufficientCategoryData
    case noMatches
    case results([AlternativeProduct])

    var message: String {
        switch self {
        case .noProfile:
            return AppText.text(.alternativeNeedsProfile)
        case .sourceProductCompatible:
            return AppText.text(.alternativeOnlyForConflicts)
        case .insufficientCategoryData:
            return AppText.text(.alternativeMissingCategoryData)
        case .noMatches:
            return AppText.text(.alternativeNoMatches)
        case .results:
            return ""
        }
    }
}

@MainActor
final class AlternativeProductService {
    static let shared = AlternativeProductService()

    func alternatives(
        for product: ScannedProduct,
        profile: UserProfile?,
        cachedProducts: [ScannedProduct] = []
    ) async throws -> AlternativeLookupOutcome {
        guard let profile else {
            return .noProfile
        }

        let sourceAssessment = AlternativeRankingService.assessment(for: product, profile: profile)
        guard sourceAssessment.result.level == .avoid || sourceAssessment.result.level == .caution else {
            return .sourceProductCompatible
        }

        let categoryNames = Self.categoryCandidates(for: product)
        guard !categoryNames.isEmpty else {
            return .insufficientCategoryData
        }

        let remoteCandidates = try await ProductLookupAggregator.shared.fetchAlternativeCandidates(
            categoryNames: categoryNames,
            excludingBarcode: product.barcode
        )
        let candidates = Self.mergedCandidates(
            localCandidates: cachedProducts,
            remoteCandidates: remoteCandidates,
            comparedTo: product
        )
        let localBarcodes = Set(
            cachedProducts
                .filter { $0.barcode != product.barcode }
                .map(\.barcode)
        )
        let filteredCandidates = Self.filteredCandidates(candidates, for: profile)

        let ranked = AlternativeRankingService.rank(
            candidates: filteredCandidates,
            comparedTo: product,
            profile: profile,
            localBarcodes: localBarcodes
        )

        guard !ranked.isEmpty else {
            return .noMatches
        }

        return .results(Array(ranked.prefix(3)))
    }

    static func categoryCandidates(for product: ScannedProduct) -> [String] {
        let cleaned = Array(
            NSOrderedSet(array: product.categoryLabels
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty })
        ) as? [String] ?? []

        let prioritized = cleaned.sorted { lhs, rhs in
            if lhs.components(separatedBy: " ").count != rhs.components(separatedBy: " ").count {
                return lhs.components(separatedBy: " ").count > rhs.components(separatedBy: " ").count
            }

            return lhs.count > rhs.count
        }

        return Array(prioritized.prefix(3))
    }

    static func filteredCandidates(_ candidates: [ScannedProduct], for profile: UserProfile) -> [ScannedProduct] {
        candidates.filter { candidate in
            let assessment = AlternativeRankingService.assessment(for: candidate, profile: profile)
            return assessment.completenessScore >= 2
        }
    }

    static func mergedCandidates(
        localCandidates: [ScannedProduct],
        remoteCandidates: [ScannedProduct],
        comparedTo sourceProduct: ScannedProduct
    ) -> [ScannedProduct] {
        let relevantLocalCandidates = localCandidates.filter { candidate in
            candidate.barcode != sourceProduct.barcode
            && !candidate.categoryLabels.isEmpty
            && !Set(candidate.categoryLabels).intersection(sourceProduct.categoryLabels).isEmpty
        }

        var mergedByBarcode: [String: ScannedProduct] = [:]

        for candidate in remoteCandidates + relevantLocalCandidates {
            guard let existing = mergedByBarcode[candidate.barcode] else {
                mergedByBarcode[candidate.barcode] = candidate
                continue
            }

            if AlternativeRankingService.preferredProduct(between: existing, and: candidate) == candidate {
                mergedByBarcode[candidate.barcode] = candidate
            }
        }

        return Array(mergedByBarcode.values)
    }
}

enum AlternativeRankingService {
    static func rank(
        candidates: [ScannedProduct],
        comparedTo sourceProduct: ScannedProduct,
        profile: UserProfile,
        localBarcodes: Set<String> = []
    ) -> [AlternativeProduct] {
        let sourceCategories = Set(sourceProduct.categoryLabels)

        return candidates.compactMap { candidate in
            let assessment = assessment(for: candidate, profile: profile)

            guard assessment.result.level != .avoid else {
                return nil
            }

            return AlternativeProduct(
                product: candidate,
                assessment: assessment,
                categoryMatchDepth: Set(candidate.categoryLabels).intersection(sourceCategories).count,
                isFromHistory: localBarcodes.contains(candidate.barcode),
                recommendationReasons: recommendationReasons(
                    for: candidate,
                    assessment: assessment,
                    sourceProduct: sourceProduct
                )
            )
        }
        .sorted { lhs, rhs in
            let lhsPriority = priority(for: lhs.assessment.result.level)
            let rhsPriority = priority(for: rhs.assessment.result.level)
            if lhsPriority != rhsPriority {
                return lhsPriority < rhsPriority
            }

            if lhs.categoryMatchDepth != rhs.categoryMatchDepth {
                return lhs.categoryMatchDepth > rhs.categoryMatchDepth
            }

            if lhs.assessment.completenessScore != rhs.assessment.completenessScore {
                return lhs.assessment.completenessScore > rhs.assessment.completenessScore
            }

            let lhsDate = lhs.product.lastModifiedAt ?? .distantPast
            let rhsDate = rhs.product.lastModifiedAt ?? .distantPast
            if lhsDate != rhsDate {
                return lhsDate > rhsDate
            }

            return lhs.product.name.localizedCaseInsensitiveCompare(rhs.product.name) == .orderedAscending
        }
    }

    static func assessment(for product: ScannedProduct, profile: UserProfile?) -> ProductSafetyAssessment {
        let safetyResult = SafetyAnalyzer.analyze(product: product, profile: profile)

        let hasIngredients = !product.ingredientsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasAllergenData = !product.allergens.isEmpty || !product.traces.isEmpty
        let hasCategoryData = !product.categoryLabels.isEmpty

        let completenessScore = [hasIngredients, hasAllergenData, hasCategoryData].filter { $0 }.count

        let dataQuality: ProductDataQuality
        if hasIngredients && hasAllergenData {
            dataQuality = .highConfidence
        } else if completenessScore > 0 {
            dataQuality = .limitedInformation
        } else {
            dataQuality = .unknown
        }

        return ProductSafetyAssessment(
            result: safetyResult,
            dataQuality: dataQuality,
            completenessScore: completenessScore
        )
    }

    static func preferredProduct(between lhs: ScannedProduct, and rhs: ScannedProduct) -> ScannedProduct {
        let lhsScore = completenessScore(for: lhs)
        let rhsScore = completenessScore(for: rhs)
        if lhsScore != rhsScore {
            return lhsScore > rhsScore ? lhs : rhs
        }

        let lhsDate = lhs.lastModifiedAt ?? .distantPast
        let rhsDate = rhs.lastModifiedAt ?? .distantPast
        if lhsDate != rhsDate {
            return lhsDate > rhsDate ? lhs : rhs
        }

        let lhsLastScanned = lhs.lastScanned
        let rhsLastScanned = rhs.lastScanned
        if lhsLastScanned != rhsLastScanned {
            return lhsLastScanned > rhsLastScanned ? lhs : rhs
        }

        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedDescending ? rhs : lhs
    }

    static func completenessScore(for product: ScannedProduct) -> Int {
        let hasIngredients = !product.ingredientsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasAllergenData = !product.allergens.isEmpty || !product.traces.isEmpty
        let hasCategoryData = !product.categoryLabels.isEmpty

        return [hasIngredients, hasAllergenData, hasCategoryData].filter { $0 }.count
    }

    static func recommendationReasons(
        for product: ScannedProduct,
        assessment: ProductSafetyAssessment,
        sourceProduct: ScannedProduct
    ) -> [AppTextKey] {
        var reasons: [AppTextKey] = []

        if !Set(product.categoryLabels).intersection(sourceProduct.categoryLabels).isEmpty {
            reasons.append(.alternativeReasonSameCategory)
        }

        if assessment.dataQuality == .highConfidence {
            reasons.append(.alternativeReasonBetterData)
        }

        if assessment.result.level == .compatible {
            reasons.append(.alternativeReasonNoConflicts)
        }

        return reasons
    }

    private static func priority(for level: SafetyLevel) -> Int {
        switch level {
        case .compatible:
            return 0
        case .caution:
            return 1
        case .unknown:
            return 2
        case .avoid:
            return 3
        }
    }
}
