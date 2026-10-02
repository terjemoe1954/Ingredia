import Foundation

@MainActor
final class ProductLookupAggregator {
    static let shared = ProductLookupAggregator()

    private let configuredProviders: [any ProductDataProvider]?

    init(providers: [any ProductDataProvider]? = nil) {
        self.configuredProviders = providers
    }

    static func sourceStatuses() -> [ProductDataSourceStatus] {
        [
            ProductDataSourceStatus(
                id: OpenFoodFactsService.shared.providerID,
                name: OpenFoodFactsService.shared.displayName,
                isEnabled: OpenFoodFactsService.shared.isEnabled,
                supportsAlternativeSearch: OpenFoodFactsService.shared.supportsAlternativeSearch,
                trustLevel: OpenFoodFactsService.shared.sourceTrustLevel
            )
        ]
    }

    private static func defaultProviders() -> [any ProductDataProvider] {
        [OpenFoodFactsService.shared]
    }

    private var providers: [any ProductDataProvider] {
        configuredProviders ?? Self.defaultProviders()
    }

    func fetchProduct(barcode: String) async throws -> ScannedProduct {
        var lastError: Error?
        var mergedRecord: ProviderProductRecord?

        for provider in providers {
            do {
                if let record = try await provider.fetchProductRecord(barcode: barcode) {
                    if let existing = mergedRecord {
                        mergedRecord = Self.merge(existing, with: record)
                    } else {
                        mergedRecord = record
                    }
                }
            } catch {
                lastError = Self.preferredError(lastError, error)
            }
        }

        if let mergedRecord {
            return mergedRecord.asScannedProduct()
        }

        if let lastError {
            throw lastError
        }

        throw ProductLookupError.productNotFound
    }

    func fetchAlternativeCandidates(
        categoryNames: [String],
        excludingBarcode barcode: String,
        limitPerCategory: Int = 12,
        maxResults: Int = 36
    ) async throws -> [ScannedProduct] {
        guard maxResults > 0 else {
            return []
        }

        let normalizedCategoryNames = ProductCategoryMatching.uniqueLabels(categoryNames)
        guard !normalizedCategoryNames.isEmpty else {
            return []
        }

        let normalizedLimitPerCategory = max(1, limitPerCategory)
        let excludedBarcode = ProductDataCompleteness.normalizedText(barcode)
        var lastError: Error?
        var mergedByBarcode: [String: ScannedProduct] = [:]
        var orderedBarcodes: [String] = []

        for provider in providers {
            do {
                let records = try await provider.fetchAlternativeCandidateRecords(
                    categoryNames: normalizedCategoryNames,
                    excludingBarcode: barcode,
                    limitPerCategory: normalizedLimitPerCategory,
                    maxResults: maxResults
                )

                for record in records {
                    let candidate = record.asScannedProduct()
                    let candidateBarcode = ProductDataCompleteness.normalizedText(candidate.barcode) ?? candidate.barcode
                    guard candidateBarcode != excludedBarcode else {
                        continue
                    }

                    guard let existing = mergedByBarcode[candidateBarcode] else {
                        mergedByBarcode[candidateBarcode] = candidate
                        orderedBarcodes.append(candidateBarcode)
                        continue
                    }

                    let mergedRecord = Self.merge(existing.providerRecord(), with: record)
                    mergedByBarcode[candidateBarcode] = mergedRecord.asScannedProduct(lastScanned: existing.lastScanned)
                }
            } catch {
                lastError = Self.preferredError(lastError, error)
            }
        }

        let merged = orderedBarcodes.compactMap { mergedByBarcode[$0] }
        if !merged.isEmpty {
            return Array(merged.prefix(maxResults))
        }

        if let lastError {
            throw lastError
        }

        return []
    }

    static func merge(_ lhs: ProviderProductRecord, with rhs: ProviderProductRecord) -> ProviderProductRecord {
        let preferred = preferredRecord(between: lhs, and: rhs)
        let secondary = preferred.providerID == lhs.providerID ? rhs : lhs

        return ProviderProductRecord(
            providerID: mergedProviderID(lhs, rhs, fallback: preferred.providerID),
            providerName: mergedProviderName(lhs, rhs, fallback: preferred.providerName),
            sourceTrustLevel: mergedTrustLevel(lhs.sourceTrustLevel, rhs.sourceTrustLevel),
            barcode: ProductDataCompleteness.normalizedText(preferred.barcode) ?? preferred.barcode,
            name: preferredNonEmptyString(lhs.name, rhs.name, fallback: preferred.name),
            brands: preferredNonEmptyString(lhs.brands, rhs.brands, fallback: preferred.brands),
            ingredientsText: preferredLongerString(lhs.ingredientsText, rhs.ingredientsText, fallback: preferred.ingredientsText),
            allergens: mergedNonBlankValues(lhs.allergens, rhs.allergens),
            traces: mergedNonBlankValues(lhs.traces, rhs.traces),
            categoryLabels: ProductCategoryMatching.uniqueLabels(lhs.categoryLabels + rhs.categoryLabels),
            imageURLString: preferredImageURLString(lhs.imageURLString, rhs.imageURLString, fallback: preferred.imageURLString),
            lastModifiedAt: [lhs.lastModifiedAt, rhs.lastModifiedAt].compactMap { $0 }.max() ?? secondary.lastModifiedAt
        )
    }

    private static func preferredRecord(between lhs: ProviderProductRecord, and rhs: ProviderProductRecord) -> ProviderProductRecord {
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

        return sortName(for: lhs).localizedCaseInsensitiveCompare(sortName(for: rhs)) == .orderedDescending ? rhs : lhs
    }

    private static func sortName(for record: ProviderProductRecord) -> String {
        ProductDataCompleteness.normalizedText(record.name) ?? record.name
    }

    private static func mergedTrustLevel(_ lhs: ProductSourceTrustLevel, _ rhs: ProductSourceTrustLevel) -> ProductSourceTrustLevel {
        lhs.priority <= rhs.priority ? lhs : rhs
    }

    private static func mergedProviderName(
        _ lhs: ProviderProductRecord,
        _ rhs: ProviderProductRecord,
        fallback: String
    ) -> String {
        mergedSourceString([lhs.providerName, rhs.providerName], fallback: fallback)
    }

    private static func mergedProviderID(
        _ lhs: ProviderProductRecord,
        _ rhs: ProviderProductRecord,
        fallback: String
    ) -> String {
        mergedSourceString([lhs.providerID, rhs.providerID], fallback: fallback)
    }

    private static func completenessScore(for record: ProviderProductRecord) -> Int {
        let hasIngredients = ProductDataCompleteness.hasText(record.ingredientsText)
        let hasAllergenData = !ProductTagFormatting.normalizedTags(record.allergens).isEmpty
        || !ProductTagFormatting.normalizedTags(record.traces).isEmpty
        let hasCategoryData = !ProductCategoryMatching.uniqueLabels(record.categoryLabels).isEmpty

        return [hasIngredients, hasAllergenData, hasCategoryData].filter { $0 }.count
    }

    private static func preferredError(_ existing: Error?, _ newError: Error) -> Error {
        guard let existing else {
            return newError
        }

        return errorPriority(newError) > errorPriority(existing) ? newError : existing
    }

    private static func errorPriority(_ error: Error) -> Int {
        guard let lookupError = error as? ProductLookupError else {
            return 40
        }

        switch lookupError {
        case .invalidBarcode:
            return 100
        case .offline:
            return 90
        case .timedOut:
            return 80
        case .serverIssue:
            return 70
        case .dataSourceUnauthorized:
            return 60
        case .badResponse:
            return 50
        case .productNotFound:
            return 10
        }
    }

    private static func mergedSourceString(_ values: [String], fallback: String) -> String {
        let normalized = values.compactMap(ProductDataCompleteness.normalizedText)
        let unique = Array(NSOrderedSet(array: normalized)) as? [String] ?? normalized

        guard unique.count > 1 else {
            return unique.first ?? ProductDataCompleteness.normalizedText(fallback) ?? fallback
        }

        return ProductDataSourceFormatting.joinedMergedSources(unique)
    }

    private static func mergedNonBlankValues(_ lhs: [String], _ rhs: [String]) -> [String] {
        let normalized = (lhs + rhs).compactMap(ProductDataCompleteness.normalizedText)
        return Array(NSOrderedSet(array: normalized)) as? [String] ?? normalized
    }

    private static func preferredNonEmptyString(_ lhs: String, _ rhs: String, fallback: String) -> String {
        let lhsValue = ProductDataCompleteness.normalizedText(lhs)
        let rhsValue = ProductDataCompleteness.normalizedText(rhs)

        if lhsValue == nil && rhsValue == nil {
            return ProductDataCompleteness.normalizedText(fallback) ?? fallback
        }

        if lhsValue == nil {
            return rhsValue ?? rhs
        }

        if rhsValue == nil {
            return lhsValue ?? lhs
        }

        return ProductDataCompleteness.normalizedText(fallback) ?? fallback
    }

    private static func preferredLongerString(_ lhs: String, _ rhs: String, fallback: String) -> String {
        let lhsTrimmed = ProductDataCompleteness.normalizedText(lhs) ?? ""
        let rhsTrimmed = ProductDataCompleteness.normalizedText(rhs) ?? ""

        if lhsTrimmed.isEmpty && rhsTrimmed.isEmpty {
            return fallback
        }

        if lhsTrimmed.count == rhsTrimmed.count {
            return ProductDataCompleteness.normalizedText(fallback) ?? fallback
        }

        return lhsTrimmed.count > rhsTrimmed.count ? lhsTrimmed : rhsTrimmed
    }

    private static func preferredImageURLString(_ lhs: String?, _ rhs: String?, fallback: String?) -> String? {
        let lhsValue = ProductDataCompleteness.normalizedHTTPURLString(lhs)
        let rhsValue = ProductDataCompleteness.normalizedHTTPURLString(rhs)

        if lhsValue == nil && rhsValue == nil {
            return ProductDataCompleteness.normalizedHTTPURLString(fallback)
        }

        if lhsValue == nil {
            return rhsValue
        }

        if rhsValue == nil {
            return lhsValue
        }

        return ProductDataCompleteness.normalizedHTTPURLString(fallback) ?? lhsValue
    }
}
