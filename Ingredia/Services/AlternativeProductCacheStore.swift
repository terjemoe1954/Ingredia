import Foundation

@MainActor
final class AlternativeProductCacheStore {
    static let shared = AlternativeProductCacheStore()

    private struct CachedProduct: Codable {
        let barcode: String
        let sourceProviderID: String
        let sourceProviderName: String
        let sourceTrustLevelRawValue: String
        let name: String
        let brands: String
        let ingredientsText: String
        let allergens: [String]
        let traces: [String]
        let categoryLabels: [String]
        let imageURLString: String?
        let lastModifiedAt: Date?

        init(product: ScannedProduct) {
            barcode = product.barcode
            sourceProviderID = product.sourceProviderID
            sourceProviderName = product.sourceProviderName
            sourceTrustLevelRawValue = product.sourceTrustLevelRawValue
            name = product.name
            brands = product.brands
            ingredientsText = product.ingredientsText
            allergens = product.allergens
            traces = product.traces
            categoryLabels = product.categoryLabels
            imageURLString = product.imageURLString
            lastModifiedAt = product.lastModifiedAt
        }

        func makeProduct() -> ScannedProduct {
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
                lastModifiedAt: lastModifiedAt
            )
        }
    }

    private struct CacheBucket: Codable {
        let updatedAt: Date
        let products: [CachedProduct]
    }

    private let defaults: UserDefaults
    private let storageKey = "alternativeProductCache.v1"
    private let maximumSourceProducts = 50
    private let maximumAge: TimeInterval = 30 * 24 * 60 * 60

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func products(for sourceBarcode: String, now: Date = .now) -> [ScannedProduct] {
        let key = normalizedBarcode(sourceBarcode)
        guard let bucket = loadCache()[key],
              now.timeIntervalSince(bucket.updatedAt) <= maximumAge else {
            return []
        }

        return bucket.products.map { $0.makeProduct() }
    }

    func save(_ products: [ScannedProduct], for sourceBarcode: String, now: Date = .now) {
        guard !products.isEmpty else { return }

        let key = normalizedBarcode(sourceBarcode)
        var cache = loadCache().filter {
            now.timeIntervalSince($0.value.updatedAt) <= maximumAge
        }
        cache[key] = CacheBucket(
            updatedAt: now,
            products: products.prefix(12).map(CachedProduct.init)
        )

        if cache.count > maximumSourceProducts {
            let retainedKeys = cache
                .sorted { $0.value.updatedAt > $1.value.updatedAt }
                .prefix(maximumSourceProducts)
                .map(\.key)
            cache = cache.filter { retainedKeys.contains($0.key) }
        }

        guard let data = try? JSONEncoder().encode(cache) else { return }
        defaults.set(data, forKey: storageKey)
    }

    func removeAll() {
        defaults.removeObject(forKey: storageKey)
    }

    private func loadCache() -> [String: CacheBucket] {
        guard let data = defaults.data(forKey: storageKey),
              let cache = try? JSONDecoder().decode([String: CacheBucket].self, from: data) else {
            return [:]
        }

        return cache
    }

    private func normalizedBarcode(_ barcode: String) -> String {
        ProductDataCompleteness.normalizedText(barcode) ?? barcode
    }
}
