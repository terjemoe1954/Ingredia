import Foundation

struct OFFProductResponse: Decodable {
    let status: Int?
    let statusVerbose: String?
    let product: OFFProduct?

    enum CodingKeys: String, CodingKey {
        case status
        case statusVerbose = "status_verbose"
        case product
    }
}

struct OFFProduct: Decodable {
    let code: String?
    let productName: String?
    let brands: String?
    let ingredientsText: String?
    let allergensTags: [String]?
    let tracesTags: [String]?
    let categoriesTagsEN: [String]?
    let imageFrontSmallURL: String?
    let lastModifiedTimestamp: Int?

    enum CodingKeys: String, CodingKey {
        case code
        case productName = "product_name"
        case brands
        case ingredientsText = "ingredients_text"
        case allergensTags = "allergens_tags"
        case tracesTags = "traces_tags"
        case categoriesTagsEN = "categories_tags_en"
        case imageFrontSmallURL = "image_front_small_url"
        case lastModifiedTimestamp = "last_modified_t"
    }
}

struct OFFSearchResponse: Decodable {
    let products: [OFFProduct]
}

enum ProductLookupError: LocalizedError {
    case invalidBarcode
    case productNotFound
    case badResponse
    case offline
    case timedOut
    case serverIssue
    case dataSourceUnauthorized

    var errorDescription: String? {
        description(language: .current)
    }

    func description(language: AppLanguage) -> String {
        switch self {
        case .invalidBarcode:
            return AppText.text(.productLookupInvalidBarcode, language: language)
        case .productNotFound:
            return AppText.text(.productLookupNotFound, language: language)
        case .badResponse:
            return AppText.text(.productLookupBadResponse, language: language)
        case .offline:
            return AppText.text(.productLookupOffline, language: language)
        case .timedOut:
            return AppText.text(.productLookupTimedOut, language: language)
        case .serverIssue:
            return AppText.text(.productLookupServerIssue, language: language)
        case .dataSourceUnauthorized:
            return AppText.text(.productLookupDataSourceUnauthorized, language: language)
        }
    }
}

@MainActor
final class OpenFoodFactsService: ProductDataProvider {
    static let shared = OpenFoodFactsService()
    let providerID = "open_food_facts"
    let displayName = "Open Food Facts"
    let isEnabled = true
    let supportsAlternativeSearch = true
    let sourceTrustLevel = ProductSourceTrustLevel.community

    func fetchProduct(barcode: String) async throws -> ScannedProduct {
        guard let record = try await fetchProductRecord(barcode: barcode) else {
            throw ProductLookupError.productNotFound
        }

        return record.asScannedProduct()
    }

    func fetchAlternativeCandidates(
        categoryNames: [String],
        excludingBarcode barcode: String,
        limitPerCategory: Int = 12,
        maxResults: Int = 36
    ) async throws -> [ScannedProduct] {
        let records = try await fetchAlternativeCandidateRecords(
            categoryNames: categoryNames,
            excludingBarcode: barcode,
            limitPerCategory: limitPerCategory,
            maxResults: maxResults
        )
        return records.map { $0.asScannedProduct() }
    }

    func fetchProductRecord(barcode: String) async throws -> ProviderProductRecord? {
        let clean = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty,
              clean.allSatisfy({ $0.isNumber }) else {
            throw ProductLookupError.invalidBarcode
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "world.openfoodfacts.org"
        components.path = "/api/v2/product/\(clean)"
        components.queryItems = [
            URLQueryItem(
                name: "fields",
                value: "code,product_name,brands,ingredients_text,allergens_tags,traces_tags,categories_tags_en,image_front_small_url,last_modified_t"
            )
        ]

        let decoded: OFFProductResponse = try await Self.fetch(url: components.url)

        guard decoded.status == 1, let product = decoded.product else {
            throw ProductLookupError.productNotFound
        }

        return Self.makeRecord(from: product, fallbackBarcode: clean, providerID: providerID)
    }

    func fetchAlternativeCandidateRecords(
        categoryNames: [String],
        excludingBarcode barcode: String,
        limitPerCategory: Int,
        maxResults: Int
    ) async throws -> [ProviderProductRecord] {
        let cleanCategories = Self.normalizedCategories(categoryNames)

        guard !cleanCategories.isEmpty else {
            return []
        }

        var seenBarcodes = Set<String>()
        var results: [ProviderProductRecord] = []

        for categoryName in cleanCategories {
            let exactCategoryProducts = try await fetchAlternativeCandidatesPage(
                categoryName: categoryName,
                excludingBarcode: barcode,
                limit: limitPerCategory
            )

            let fallbackSearchProducts: [ProviderProductRecord]
            if exactCategoryProducts.count < max(4, limitPerCategory / 2) {
                fallbackSearchProducts = try await fetchAlternativeCandidatesBySearchTerm(
                    categoryName,
                    excludingBarcode: barcode,
                    limit: limitPerCategory
                )
            } else {
                fallbackSearchProducts = []
            }

            for product in exactCategoryProducts + fallbackSearchProducts {
                guard seenBarcodes.insert(product.barcode).inserted else { continue }
                results.append(product)

                if results.count >= maxResults {
                    return results
                }
            }
        }

        return results
    }

    static func normalizedTags(_ tags: [String]) -> [String] {
        ProductTagFormatting.normalizedTags(tags)
    }

    static func normalizedCategories(_ categories: [String]) -> [String] {
        ProductCategoryMatching.uniqueLabels(categories)
    }

    private func fetchAlternativeCandidatesPage(
        categoryName: String,
        excludingBarcode barcode: String,
        limit: Int
    ) async throws -> [ProviderProductRecord] {
        try await fetchAlternativeCandidates(
            queryItems: [
                URLQueryItem(name: "categories_tags_en", value: categoryName),
                URLQueryItem(name: "sort_by", value: "last_modified_t"),
                URLQueryItem(name: "page_size", value: String(limit))
            ],
            excludingBarcode: barcode
        )
    }

    private func fetchAlternativeCandidatesBySearchTerm(
        _ categoryName: String,
        excludingBarcode barcode: String,
        limit: Int
    ) async throws -> [ProviderProductRecord] {
        let query = Self.searchTerms(for: categoryName)
        guard !query.isEmpty else {
            return []
        }

        return try await fetchAlternativeCandidates(
            queryItems: [
                URLQueryItem(name: "search_terms", value: query),
                URLQueryItem(name: "sort_by", value: "last_modified_t"),
                URLQueryItem(name: "page_size", value: String(limit))
            ],
            excludingBarcode: barcode
        )
    }

    private func fetchAlternativeCandidates(
        queryItems: [URLQueryItem],
        excludingBarcode barcode: String
    ) async throws -> [ProviderProductRecord] {
        let excludedBarcode = Self.normalizedBarcode(barcode)
        var components = URLComponents()
        components.scheme = "https"
        components.host = "world.openfoodfacts.org"
        components.path = "/api/v2/search"
        components.queryItems = queryItems + [
            URLQueryItem(
                name: "fields",
                value: "code,product_name,brands,ingredients_text,allergens_tags,traces_tags,categories_tags_en,image_front_small_url,last_modified_t"
            )
        ]

        let decoded: OFFSearchResponse = try await Self.fetch(url: components.url)
        return decoded.products.compactMap { product in
            let record = Self.makeRecord(from: product, providerID: providerID)
            guard record.barcode != excludedBarcode else { return nil }
            return record
        }
    }

    static func searchTerms(for categoryName: String) -> String {
        categoryName
            .replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .map(String.init)
            .filter { token in
                let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmed.count > 2
            }
            .prefix(4)
            .joined(separator: " ")
    }

    private static func fetch<Response: Decodable>(url: URL?) async throws -> Response {
        guard let url else {
            throw ProductLookupError.badResponse
        }

        var request = URLRequest(url: url)
        request.setValue(AppMetadata.userAgent, forHTTPHeaderField: "User-Agent")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw mapRequestError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw ProductLookupError.badResponse
        }

        guard 200..<300 ~= http.statusCode else {
            throw mapHTTPStatus(http.statusCode)
        }

        do {
            return try JSONDecoder().decode(Response.self, from: data)
        } catch {
            throw ProductLookupError.badResponse
        }
    }

    private static func makeRecord(
        from product: OFFProduct,
        fallbackBarcode: String? = nil,
        providerID: String
    ) -> ProviderProductRecord {
        ProviderProductRecord(
            providerID: providerID,
            providerName: OpenFoodFactsService.shared.displayName,
            sourceTrustLevel: OpenFoodFactsService.shared.sourceTrustLevel,
            barcode: normalizedBarcode(product.code, fallback: fallbackBarcode),
            name: normalizedProductName(product.productName),
            brands: normalizedText(product.brands),
            ingredientsText: normalizedText(product.ingredientsText),
            allergens: normalizedTags(product.allergensTags ?? []),
            traces: normalizedTags(product.tracesTags ?? []),
            categoryLabels: normalizedCategories(product.categoriesTagsEN ?? []),
            imageURLString: normalizedImageURLString(product.imageFrontSmallURL),
            lastModifiedAt: date(fromUnixTimestamp: product.lastModifiedTimestamp)
        )
    }

    static func normalizedBarcode(_ barcode: String?, fallback: String? = nil) -> String {
        ProductDataCompleteness.normalizedText(barcode)
        ?? ProductDataCompleteness.normalizedText(fallback)
        ?? UUID().uuidString
    }

    static func normalizedOptionalText(_ value: String?) -> String? {
        ProductDataCompleteness.normalizedText(value)
    }

    static func normalizedImageURLString(_ value: String?) -> String? {
        ProductDataCompleteness.normalizedHTTPURLString(value)
    }

    static func normalizedProductName(_ name: String?) -> String {
        ProductDataCompleteness.normalizedText(name) ?? AppText.text(.unknownProduct)
    }

    static func normalizedText(_ value: String?) -> String {
        ProductDataCompleteness.normalizedText(value) ?? ""
    }

    static func date(fromUnixTimestamp timestamp: Int?) -> Date? {
        guard let timestamp, timestamp >= 0 else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(timestamp))
    }

    static func mapRequestError(_ error: Error) -> ProductLookupError {
        guard let urlError = error as? URLError else {
            return .badResponse
        }

        switch urlError.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
            return .offline
        case .timedOut:
            return .timedOut
        case .cannotConnectToHost, .cannotFindHost, .dnsLookupFailed, .secureConnectionFailed, .cannotLoadFromNetwork:
            return .serverIssue
        default:
            return .badResponse
        }
    }

    static func mapHTTPStatus(_ statusCode: Int) -> ProductLookupError {
        switch statusCode {
        case 404:
            return .productNotFound
        case 408:
            return .timedOut
        case 429, 500...599:
            return .serverIssue
        default:
            return .badResponse
        }
    }
}
