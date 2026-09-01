import Foundation

struct ProductDataSourceStatus: Identifiable, Equatable {
    let id: String
    let name: String
    let isEnabled: Bool
    let supportsAlternativeSearch: Bool
}

struct ProviderProductRecord: Equatable {
    let providerID: String
    let barcode: String
    let name: String
    let brands: String
    let ingredientsText: String
    let allergens: [String]
    let traces: [String]
    let categoryLabels: [String]
    let imageURLString: String?
    let lastModifiedAt: Date?
}

extension ProviderProductRecord {
    func asScannedProduct(lastScanned: Date = .now) -> ScannedProduct {
        ScannedProduct(
            barcode: barcode,
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

    func fetchProductRecord(barcode: String) async throws -> ProviderProductRecord?

    func fetchAlternativeCandidateRecords(
        categoryNames: [String],
        excludingBarcode barcode: String,
        limitPerCategory: Int,
        maxResults: Int
    ) async throws -> [ProviderProductRecord]
}
