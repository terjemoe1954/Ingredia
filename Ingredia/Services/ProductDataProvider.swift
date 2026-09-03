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
            imageURLString: imageURLString,
            lastModifiedAt: lastModifiedAt,
            lastScanned: lastScanned
        )
    }
}

extension ScannedProduct {
    func providerRecord(providerID: String) -> ProviderProductRecord {
        ProviderProductRecord(
            providerID: providerID,
            providerName: sourceProviderName,
            sourceTrustLevel: sourceTrustLevel,
            barcode: barcode,
            name: name,
            brands: brands,
            ingredientsText: ingredientsText,
            allergens: allergens,
            traces: traces,
            categoryLabels: categoryLabels,
            imageURLString: imageURLString,
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
