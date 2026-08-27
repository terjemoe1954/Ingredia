import Foundation
import SwiftData

@Model
final class ScannedProduct {
    @Attribute(.unique) var barcode: String
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
}
