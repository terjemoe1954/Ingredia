import Foundation

enum ProductDataQuality {
    case highConfidence
    case limitedInformation
    case unknown

    var title: String {
        title(language: .current)
    }

    func title(language: AppLanguage) -> String {
        switch self {
        case .highConfidence:
            return AppText.text(.dataQualityHigh, language: language)
        case .limitedInformation:
            return AppText.text(.dataQualityLimited, language: language)
        case .unknown:
            return AppText.text(.dataQualityUnknown, language: language)
        }
    }

    var detail: String {
        detail(language: .current)
    }

    func detail(language: AppLanguage) -> String {
        switch self {
        case .highConfidence:
            return AppText.text(.dataQualityHighDetail, language: language)
        case .limitedInformation:
            return AppText.text(.dataQualityLimitedDetail, language: language)
        case .unknown:
            return AppText.text(.dataQualityUnknownDetail, language: language)
        }
    }
}

extension ProductSourceTrustLevel {
    func title(language: AppLanguage = .current) -> String {
        switch self {
        case .community:
            return AppText.text(.sourceTrustCommunity, language: language)
        case .verified:
            return AppText.text(.sourceTrustVerified, language: language)
        case .limited:
            return AppText.text(.sourceTrustLimited, language: language)
        }
    }

    func detail(language: AppLanguage = .current) -> String {
        switch self {
        case .community:
            return AppText.text(.sourceTrustCommunityDetail, language: language)
        case .verified:
            return AppText.text(.sourceTrustVerifiedDetail, language: language)
        case .limited:
            return AppText.text(.sourceTrustLimitedDetail, language: language)
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
        message(language: .current)
    }

    func message(language: AppLanguage) -> String {
        switch self {
        case .noProfile:
            return AppText.text(.alternativeNeedsProfile, language: language)
        case .sourceProductCompatible:
            return AppText.text(.alternativeOnlyForConflicts, language: language)
        case .insufficientCategoryData:
            return AppText.text(.alternativeMissingCategoryData, language: language)
        case .noMatches:
            return AppText.text(.alternativeNoMatches, language: language)
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
        cachedProducts: [ScannedProduct] = [],
        language: AppLanguage? = nil
    ) async throws -> AlternativeLookupOutcome {
        let language = language ?? .current

        guard let profile else {
            return .noProfile
        }

        let sourceAssessment = AlternativeRankingService.assessment(for: product, profile: profile, language: language)
        guard sourceAssessment.result.level == .avoid || sourceAssessment.result.level == .caution else {
            return .sourceProductCompatible
        }

        let categoryNames = Self.categoryCandidates(for: product)
        let remoteCandidates: [ScannedProduct]
        if categoryNames.isEmpty {
            remoteCandidates = []
        } else {
            remoteCandidates = try await ProductLookupAggregator.shared.fetchAlternativeCandidates(
                categoryNames: categoryNames,
                excludingBarcode: product.barcode
            )
        }
        let candidates = Self.mergedCandidates(
            localCandidates: cachedProducts,
            remoteCandidates: remoteCandidates,
            comparedTo: product
        )
        let sourceBarcode = ProductDataCompleteness.normalizedText(product.barcode) ?? product.barcode
        let localBarcodes = Set(
            cachedProducts
                .compactMap { cachedProduct -> String? in
                    let barcode = ProductDataCompleteness.normalizedText(cachedProduct.barcode) ?? cachedProduct.barcode
                    return barcode == sourceBarcode ? nil : barcode
                }
        )
        let filteredCandidates = Self.filteredCandidates(candidates, for: profile)

        let ranked = AlternativeRankingService.rank(
            candidates: filteredCandidates,
            comparedTo: product,
            profile: profile,
            localBarcodes: localBarcodes,
            language: language
        )

        guard !ranked.isEmpty else {
            return .noMatches
        }

        return .results(Array(ranked.prefix(3)))
    }

    static func categoryCandidates(for product: ScannedProduct) -> [String] {
        let cleaned = ProductCategoryMatching.uniqueLabels(product.categoryLabels)

        let prioritized = cleaned.sorted { lhs, rhs in
            let lhsWordCount = wordCount(in: lhs)
            let rhsWordCount = wordCount(in: rhs)
            if lhsWordCount != rhsWordCount {
                return lhsWordCount > rhsWordCount
            }

            return lhs.count > rhs.count
        }

        return Array(prioritized.prefix(3))
    }

    private static func wordCount(in value: String) -> Int {
        value.split(whereSeparator: \.isWhitespace).count
    }

    static func filteredCandidates(_ candidates: [ScannedProduct], for profile: UserProfile) -> [ScannedProduct] {
        candidates.filter { candidate in
            AlternativeRankingService.completenessScore(for: candidate) >= 2
        }
    }

    static func mergedCandidates(
        localCandidates: [ScannedProduct],
        remoteCandidates: [ScannedProduct],
        comparedTo sourceProduct: ScannedProduct
    ) -> [ScannedProduct] {
        let sourceBarcode = ProductDataCompleteness.normalizedText(sourceProduct.barcode) ?? sourceProduct.barcode
        let sourceCategories = ProductCategoryMatching.uniqueLabels(sourceProduct.categoryLabels)
        let relevantLocalCandidates = localCandidates.filter { candidate in
            let candidateBarcode = ProductDataCompleteness.normalizedText(candidate.barcode) ?? candidate.barcode
            guard candidateBarcode != sourceBarcode else { return false }

            if sourceCategories.isEmpty {
                return AlternativeRankingService.completenessScore(for: candidate) >= 2
            }

            return ProductCategoryMatching.hasOverlap(candidate.categoryLabels, sourceCategories)
        }

        var mergedByBarcode: [String: ScannedProduct] = [:]
        var orderedBarcodes: [String] = []

        for candidate in remoteCandidates + relevantLocalCandidates {
            let candidateBarcode = ProductDataCompleteness.normalizedText(candidate.barcode) ?? candidate.barcode
            guard candidateBarcode != sourceBarcode else { continue }

            guard let existing = mergedByBarcode[candidateBarcode] else {
                mergedByBarcode[candidateBarcode] = candidate
                orderedBarcodes.append(candidateBarcode)
                continue
            }

            if AlternativeRankingService.preferredProduct(between: existing, and: candidate) == candidate {
                mergedByBarcode[candidateBarcode] = candidate
            }
        }

        return orderedBarcodes.compactMap { mergedByBarcode[$0] }
    }
}

enum AlternativeRankingService {
    static func rank(
        candidates: [ScannedProduct],
        comparedTo sourceProduct: ScannedProduct,
        profile: UserProfile,
        localBarcodes: Set<String> = [],
        language: AppLanguage = .current
    ) -> [AlternativeProduct] {
        let normalizedLocalBarcodes = Set(localBarcodes.map { ProductDataCompleteness.normalizedText($0) ?? $0 })
        return candidates.compactMap { candidate in
            let assessment = assessment(for: candidate, profile: profile, language: language)

            guard assessment.result.level != .avoid else {
                return nil
            }

            return AlternativeProduct(
                product: candidate,
                assessment: assessment,
                categoryMatchDepth: ProductCategoryMatching.overlapCount(candidate.categoryLabels, sourceProduct.categoryLabels),
                isFromHistory: normalizedLocalBarcodes.contains(ProductDataCompleteness.normalizedText(candidate.barcode) ?? candidate.barcode),
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

            return sortName(for: lhs.product).localizedCaseInsensitiveCompare(sortName(for: rhs.product)) == .orderedAscending
        }
    }

    static func assessment(
        for product: ScannedProduct,
        profile: UserProfile?,
        language: AppLanguage = .current
    ) -> ProductSafetyAssessment {
        let safetyResult = SafetyAnalyzer.analyze(product: product, profile: profile, language: language)

        let hasIngredients = hasIngredientData(product)
        let hasAllergenData = hasAllergenOrTraceData(product)
        let hasCategoryData = hasCategoryData(product)

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

        return sortName(for: lhs).localizedCaseInsensitiveCompare(sortName(for: rhs)) == .orderedDescending ? rhs : lhs
    }

    static func completenessScore(for product: ScannedProduct) -> Int {
        let hasIngredients = hasIngredientData(product)
        let hasAllergenData = hasAllergenOrTraceData(product)
        let hasCategoryData = hasCategoryData(product)

        return [hasIngredients, hasAllergenData, hasCategoryData].filter { $0 }.count
    }

    private static func hasIngredientData(_ product: ScannedProduct) -> Bool {
        ProductDataCompleteness.hasText(product.ingredientsText)
    }

    private static func hasAllergenOrTraceData(_ product: ScannedProduct) -> Bool {
        !ProductTagFormatting.normalizedTags(product.allergens).isEmpty
        || !ProductTagFormatting.normalizedTags(product.traces).isEmpty
    }

    private static func hasCategoryData(_ product: ScannedProduct) -> Bool {
        !ProductCategoryMatching.uniqueLabels(product.categoryLabels).isEmpty
    }

    private static func sortName(for product: ScannedProduct) -> String {
        ProductDataCompleteness.normalizedText(product.name) ?? product.name
    }

    static func recommendationReasons(
        for product: ScannedProduct,
        assessment: ProductSafetyAssessment,
        sourceProduct: ScannedProduct
    ) -> [AppTextKey] {
        var reasons: [AppTextKey] = []

        if ProductCategoryMatching.hasOverlap(product.categoryLabels, sourceProduct.categoryLabels) {
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
