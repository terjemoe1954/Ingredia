import Foundation

@MainActor
final class ProductLookupAggregator {
    static let shared = ProductLookupAggregator(providers: defaultProviders())

    private let providers: [any ProductDataProvider]

    init(providers: [any ProductDataProvider]) {
        self.providers = providers
    }

    static func sourceStatuses() -> [ProductDataSourceStatus] {
        [
            ProductDataSourceStatus(
                id: OpenFoodFactsService.shared.providerID,
                name: OpenFoodFactsService.shared.displayName,
                isEnabled: OpenFoodFactsService.shared.isEnabled,
                supportsAlternativeSearch: OpenFoodFactsService.shared.supportsAlternativeSearch
            ),
            ProductDataSourceStatus(
                id: FoodRepoService.shared.providerID,
                name: FoodRepoService.shared.displayName,
                isEnabled: FoodRepoService.shared.isEnabled,
                supportsAlternativeSearch: FoodRepoService.shared.supportsAlternativeSearch
            )
        ]
    }

    private static func defaultProviders() -> [any ProductDataProvider] {
        sourceStatuses()
            .filter(\.isEnabled)
            .compactMap { status in
                switch status.id {
                case OpenFoodFactsService.shared.providerID:
                    OpenFoodFactsService.shared
                case FoodRepoService.shared.providerID:
                    FoodRepoService.shared
                default:
                    nil
                }
            }
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
                lastError = error
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
        var lastError: Error?
        var mergedByBarcode: [String: ScannedProduct] = [:]

        for provider in providers {
            do {
                let records = try await provider.fetchAlternativeCandidateRecords(
                    categoryNames: categoryNames,
                    excludingBarcode: barcode,
                    limitPerCategory: limitPerCategory,
                    maxResults: maxResults
                )

                for record in records {
                    let candidate = record.asScannedProduct()

                    guard let existing = mergedByBarcode[candidate.barcode] else {
                        mergedByBarcode[candidate.barcode] = candidate
                        continue
                    }

                    let mergedRecord = Self.merge(existing.providerRecord(providerID: provider.providerID), with: record)
                    mergedByBarcode[candidate.barcode] = mergedRecord.asScannedProduct(lastScanned: existing.lastScanned)
                }
            } catch {
                lastError = error
            }
        }

        let merged = Array(mergedByBarcode.values)
        if !merged.isEmpty {
            return merged
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
            providerID: preferred.providerID,
            barcode: preferred.barcode,
            name: preferredNonEmptyString(lhs.name, rhs.name, fallback: preferred.name),
            brands: preferredNonEmptyString(lhs.brands, rhs.brands, fallback: preferred.brands),
            ingredientsText: preferredLongerString(lhs.ingredientsText, rhs.ingredientsText, fallback: preferred.ingredientsText),
            allergens: mergedValues(lhs.allergens, rhs.allergens),
            traces: mergedValues(lhs.traces, rhs.traces),
            categoryLabels: mergedValues(lhs.categoryLabels, rhs.categoryLabels),
            imageURLString: preferredNonEmptyOptional(lhs.imageURLString, rhs.imageURLString, fallback: preferred.imageURLString),
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

        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedDescending ? rhs : lhs
    }

    private static func completenessScore(for record: ProviderProductRecord) -> Int {
        let hasIngredients = !record.ingredientsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasAllergenData = !record.allergens.isEmpty || !record.traces.isEmpty
        let hasCategoryData = !record.categoryLabels.isEmpty

        return [hasIngredients, hasAllergenData, hasCategoryData].filter { $0 }.count
    }

    private static func mergedValues(_ lhs: [String], _ rhs: [String]) -> [String] {
        Array(NSOrderedSet(array: lhs + rhs)) as? [String] ?? lhs + rhs
    }

    private static func preferredNonEmptyString(_ lhs: String, _ rhs: String, fallback: String) -> String {
        let lhsTrimmed = lhs.trimmingCharacters(in: .whitespacesAndNewlines)
        let rhsTrimmed = rhs.trimmingCharacters(in: .whitespacesAndNewlines)

        if lhsTrimmed.isEmpty && rhsTrimmed.isEmpty {
            return fallback
        }

        if lhsTrimmed.isEmpty {
            return rhs
        }

        if rhsTrimmed.isEmpty {
            return lhs
        }

        return fallback
    }

    private static func preferredLongerString(_ lhs: String, _ rhs: String, fallback: String) -> String {
        let lhsTrimmed = lhs.trimmingCharacters(in: .whitespacesAndNewlines)
        let rhsTrimmed = rhs.trimmingCharacters(in: .whitespacesAndNewlines)

        if lhsTrimmed.isEmpty && rhsTrimmed.isEmpty {
            return fallback
        }

        if lhsTrimmed.count == rhsTrimmed.count {
            return fallback
        }

        return lhsTrimmed.count > rhsTrimmed.count ? lhs : rhs
    }

    private static func preferredNonEmptyOptional(_ lhs: String?, _ rhs: String?, fallback: String?) -> String? {
        let lhsValue = lhs?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let rhsValue = rhs?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if lhsValue.isEmpty && rhsValue.isEmpty {
            return fallback
        }

        if lhsValue.isEmpty {
            return rhs
        }

        if rhsValue.isEmpty {
            return lhs
        }

        return fallback
    }
}
