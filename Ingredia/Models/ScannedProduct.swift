import Foundation
import SwiftData

@Model
final class ScannedProduct {
    @Attribute(.unique) var barcode: String
    var sourceProviderID: String
    var sourceProviderName: String
    var sourceTrustLevelRawValue: String
    var name: String
    var brands: String
    var ingredientsText: String
    var allergens: [String]
    var traces: [String]
    var categoryLabels: [String]
    var imageURLString: String?
    var lastModifiedAt: Date?
    var lastScanned: Date

    init(
        barcode: String,
        sourceProviderID: String = "open_food_facts",
        sourceProviderName: String = "Open Food Facts",
        sourceTrustLevelRawValue: String = ProductSourceTrustLevel.community.rawValue,
        name: String,
        brands: String = "",
        ingredientsText: String = "",
        allergens: [String] = [],
        traces: [String] = [],
        categoryLabels: [String] = [],
        imageURLString: String? = nil,
        lastModifiedAt: Date? = nil,
        lastScanned: Date = .now
    ) {
        self.barcode = barcode
        self.sourceProviderID = sourceProviderID
        self.sourceProviderName = sourceProviderName
        self.sourceTrustLevelRawValue = sourceTrustLevelRawValue
        self.name = name
        self.brands = brands
        self.ingredientsText = ingredientsText
        self.allergens = allergens
        self.traces = traces
        self.categoryLabels = categoryLabels
        self.imageURLString = ProductDataCompleteness.normalizedHTTPURLString(imageURLString)
        self.lastModifiedAt = lastModifiedAt
        self.lastScanned = lastScanned
    }

    var sourceTrustLevel: ProductSourceTrustLevel {
        ProductSourceTrustLevel(rawValue: sourceTrustLevelRawValue) ?? .community
    }

    var sourceProviderNames: [String] {
        ProductDataSourceFormatting.splitMergedSources(sourceProviderName)
    }

    var sourceProviderIDs: [String] {
        ProductDataSourceFormatting.splitMergedSources(sourceProviderID)
    }

    var hasMergedSourceProviders: Bool {
        sourceProviderIDs.count > 1 || sourceProviderNames.count > 1
    }

    func displayName(language: AppLanguage) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty || Self.localizedUnknownProductNames.contains(trimmed) {
            return AppText.text(.unknownProduct, language: language)
        }
        return trimmed
    }

    func updateProductData(from product: ScannedProduct, lastScanned: Date = .now) {
        sourceProviderID = product.sourceProviderID
        sourceProviderName = product.sourceProviderName
        sourceTrustLevelRawValue = product.sourceTrustLevelRawValue
        name = product.name
        brands = product.brands
        ingredientsText = product.ingredientsText
        allergens = product.allergens
        traces = product.traces
        categoryLabels = product.categoryLabels
        imageURLString = ProductDataCompleteness.normalizedHTTPURLString(product.imageURLString)
        lastModifiedAt = product.lastModifiedAt
        self.lastScanned = lastScanned
    }

    func copyForStorage(lastScanned: Date = .now) -> ScannedProduct {
        ScannedProduct(
            barcode: barcode,
            sourceProviderID: sourceProviderID,
            sourceProviderName: sourceProviderName,
            sourceTrustLevelRawValue: sourceTrustLevelRawValue,
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

    private static var localizedUnknownProductNames: Set<String> {
        Set(AppLanguage.allCases.map { AppText.text(.unknownProduct, language: $0) })
    }
}
