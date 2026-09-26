import Foundation

enum ProductSourceTrustLevel: String, Codable, CaseIterable {
    case community
    case verified
    case limited

    var priority: Int {
        switch self {
        case .verified:
            return 0
        case .community:
            return 1
        case .limited:
            return 2
        }
    }
}

struct ProductDataSourceStatus: Identifiable, Equatable {
    let id: String
    let name: String
    let isEnabled: Bool
    let supportsAlternativeSearch: Bool
    let trustLevel: ProductSourceTrustLevel
}

enum ProductDataSourceFormatting {
    static let mergedSourceSeparator = " + "

    static func splitMergedSources(_ value: String) -> [String] {
        normalizedSources(value.components(separatedBy: mergedSourceSeparator))
    }

    static func joinedMergedSources(_ values: [String]) -> String {
        normalizedSources(values).joined(separator: mergedSourceSeparator)
    }

    private static func normalizedSources(_ values: [String]) -> [String] {
        let normalized = values.compactMap(ProductDataCompleteness.normalizedText)
        return Array(NSOrderedSet(array: normalized)) as? [String] ?? normalized
    }
}

enum ProductCategoryMatching {
    nonisolated static func uniqueLabels(_ labels: [String]) -> [String] {
        var seenCategories = Set<String>()
        return labels.compactMap { category -> String? in
            guard let label = displayCategory(category) else { return nil }
            let normalized = label.localizedLowercase
            guard seenCategories.insert(normalized).inserted else { return nil }

            return label
        }
    }

    nonisolated static func normalizedSet(_ labels: [String]) -> Set<String> {
        Set(labels.compactMap(normalizedCategory))
    }

    nonisolated static func overlapCount(_ lhs: [String], _ rhs: [String]) -> Int {
        normalizedSet(lhs).intersection(normalizedSet(rhs)).count
    }

    nonisolated static func hasOverlap(_ lhs: [String], _ rhs: [String]) -> Bool {
        overlapCount(lhs, rhs) > 0
    }

    nonisolated private static func normalizedCategory(_ value: String) -> String? {
        displayCategory(value)?.localizedLowercase
    }

    nonisolated private static func displayCategory(_ value: String) -> String? {
        let normalized = value
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
        return normalized.isEmpty ? nil : normalized
    }
}

enum ProductTagFormatting {
    nonisolated static func normalizedTag(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmed.isEmpty else { return nil }

        let normalized = ["en:", "no:"].reduce(trimmed) { value, prefix in
            value.hasPrefix(prefix) ? String(value.dropFirst(prefix.count)) : value
        }
        return normalized.isEmpty ? nil : normalized
    }

    nonisolated static func normalizedTags(_ values: [String]) -> [String] {
        let normalized = values.compactMap(normalizedTag)
        return Array(NSOrderedSet(array: normalized)) as? [String] ?? normalized
    }
}

enum ProductDataCompleteness {
    nonisolated static func normalizedText(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    nonisolated static func normalizedHTTPURLString(_ value: String?) -> String? {
        guard let normalized = normalizedText(value),
              let url = URL(string: normalized),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else {
            return nil
        }

        return normalized
    }

    nonisolated static func containsNonBlankValue(_ values: [String]) -> Bool {
        values.contains { hasText($0) }
    }

    nonisolated static func hasText(_ value: String) -> Bool {
        normalizedText(value) != nil
    }
}

struct ProviderProductRecord: Equatable {
    let providerID: String
    let providerName: String
    let sourceTrustLevel: ProductSourceTrustLevel
    let barcode: String
    let name: String
    let brands: String
    let ingredientsText: String
    let allergens: [String]
    let traces: [String]
    let categoryLabels: [String]
    let imageURLString: String?
    let lastModifiedAt: Date?

    init(
        providerID: String,
        providerName: String? = nil,
        sourceTrustLevel: ProductSourceTrustLevel = .community,
        barcode: String,
        name: String,
        brands: String,
        ingredientsText: String,
        allergens: [String],
        traces: [String],
        categoryLabels: [String],
        imageURLString: String?,
        lastModifiedAt: Date?
    ) {
        self.providerID = providerID
        self.providerName = providerName ?? providerID
        self.sourceTrustLevel = sourceTrustLevel
        self.barcode = barcode
        self.name = name
        self.brands = brands
        self.ingredientsText = ingredientsText
        self.allergens = allergens
        self.traces = traces
        self.categoryLabels = categoryLabels
        self.imageURLString = imageURLString
        self.lastModifiedAt = lastModifiedAt
    }
}

extension ProviderProductRecord {
    func asScannedProduct(lastScanned: Date = .now) -> ScannedProduct {
        ScannedProduct(
            barcode: barcode,
            sourceProviderID: providerID,
            sourceProviderName: providerName,
            sourceTrustLevelRawValue: sourceTrustLevel.rawValue,
            name: name,
            brands: brands,
            ingredientsText: ingredientsText,
            allergens: allergens,
            traces: traces,
            categoryLabels: categoryLabels,
            imageURLString: ProductDataCompleteness.normalizedHTTPURLString(imageURLString),
            lastModifiedAt: lastModifiedAt,
            lastScanned: lastScanned
        )
    }
}

extension ScannedProduct {
    func providerRecord() -> ProviderProductRecord {
        ProviderProductRecord(
            providerID: sourceProviderID,
            providerName: sourceProviderName,
            sourceTrustLevel: sourceTrustLevel,
            barcode: barcode,
            name: name,
            brands: brands,
            ingredientsText: ingredientsText,
            allergens: allergens,
            traces: traces,
            categoryLabels: categoryLabels,
            imageURLString: ProductDataCompleteness.normalizedHTTPURLString(imageURLString),
            lastModifiedAt: lastModifiedAt
        )
    }
}

@MainActor
protocol ProductDataProvider {
    var providerID: String { get }
    var displayName: String { get }
    var isEnabled: Bool { get }
    var supportsAlternativeSearch: Bool { get }
    var sourceTrustLevel: ProductSourceTrustLevel { get }

    func fetchProductRecord(barcode: String) async throws -> ProviderProductRecord?

    func fetchAlternativeCandidateRecords(
        categoryNames: [String],
        excludingBarcode barcode: String,
        limitPerCategory: Int,
        maxResults: Int
    ) async throws -> [ProviderProductRecord]
}
