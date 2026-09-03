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
        self.imageURLString = imageURLString
        self.lastModifiedAt = lastModifiedAt
        self.lastScanned = lastScanned
    }

    var sourceTrustLevel: ProductSourceTrustLevel {
        ProductSourceTrustLevel(rawValue: sourceTrustLevelRawValue) ?? .community
    }
}
