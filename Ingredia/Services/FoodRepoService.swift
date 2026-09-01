import Foundation

struct FoodRepoProductListResponse: Decodable {
    let data: [FoodRepoProduct]
}

struct FoodRepoSearchResponse: Decodable {
    let hits: FoodRepoSearchHits
}

struct FoodRepoSearchHits: Decodable {
    let hits: [FoodRepoSearchHit]
}

struct FoodRepoSearchHit: Decodable {
    let source: FoodRepoProduct

    enum CodingKeys: String, CodingKey {
        case source = "_source"
    }
}

struct FoodRepoProduct: Decodable {
    let barcode: String?
    let displayNameTranslations: [String: String]
    let ingredientsTranslations: [String: String]
    let images: [FoodRepoImage]
    let updatedAt: String?

    init(from decoder: Decoder) throws {
        let root = try decoder.container(keyedBy: RootCodingKeys.self)
        if root.contains(.attributes) {
            let attributes = try root.nestedContainer(keyedBy: CodingKeys.self, forKey: .attributes)
            barcode = try attributes.decodeIfPresent(String.self, forKey: .barcode)
            displayNameTranslations = try attributes.decodeIfPresent([String: String].self, forKey: .displayNameTranslations) ?? [:]
            ingredientsTranslations = try attributes.decodeIfPresent([String: String].self, forKey: .ingredientsTranslations) ?? [:]
            images = try attributes.decodeIfPresent([FoodRepoImage].self, forKey: .images) ?? []
            updatedAt = try attributes.decodeIfPresent(String.self, forKey: .updatedAt)
        } else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            barcode = try container.decodeIfPresent(String.self, forKey: .barcode)
            displayNameTranslations = try container.decodeIfPresent([String: String].self, forKey: .displayNameTranslations) ?? [:]
            ingredientsTranslations = try container.decodeIfPresent([String: String].self, forKey: .ingredientsTranslations) ?? [:]
            images = try container.decodeIfPresent([FoodRepoImage].self, forKey: .images) ?? []
            updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        }
    }

    private enum RootCodingKeys: String, CodingKey {
        case attributes
    }

    private enum CodingKeys: String, CodingKey {
        case barcode
        case displayNameTranslations = "display_name_translations"
        case ingredientsTranslations = "ingredients_translations"
        case images
        case updatedAt = "updated_at"
    }
}

struct FoodRepoImage: Decodable {
    let categories: [String]?
    let thumb: String?
    let medium: String?
    let large: String?
    let xlarge: String?
}

@MainActor
final class FoodRepoService: ProductDataProvider {
    static let shared = FoodRepoService()

    let providerID = "food_repo"
    let displayName = "Food Repo"
    let supportsAlternativeSearch = true

    var isConfigured: Bool {
        AppMetadata.hasFoodRepoAPIKey
    }

    var isEnabled: Bool {
        isConfigured
    }

    func fetchProductRecord(barcode: String) async throws -> ProviderProductRecord? {
        guard isConfigured else {
            return nil
        }

        let clean = barcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty, clean.allSatisfy(\.isNumber) else {
            throw ProductLookupError.invalidBarcode
        }

        let response: FoodRepoProductListResponse = try await fetchProductList(
            queryItems: [URLQueryItem(name: "barcodes", value: clean)]
        )

        guard let product = response.data.first else {
            return nil
        }

        return makeRecord(from: product, fallbackBarcode: clean)
    }

    func fetchAlternativeCandidateRecords(
        categoryNames: [String],
        excludingBarcode barcode: String,
        limitPerCategory: Int,
        maxResults: Int
    ) async throws -> [ProviderProductRecord] {
        guard isConfigured else {
            return []
        }

        let cleanCategories = Array(
            NSOrderedSet(array: categoryNames.map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }.filter { !$0.isEmpty })
        ) as? [String] ?? []

        guard !cleanCategories.isEmpty else {
            return []
        }

        var seenBarcodes = Set<String>()
        var results: [ProviderProductRecord] = []

        for categoryName in cleanCategories {
            let searchResponse = try await searchProducts(
                query: searchQuery(for: categoryName),
                limit: limitPerCategory
            )

            for hit in searchResponse.hits.hits {
                guard let record = makeRecord(from: hit.source, fallbackBarcode: hit.source.barcode ?? UUID().uuidString, categoryHint: categoryName) else {
                    continue
                }

                guard record.barcode != barcode else { continue }
                guard seenBarcodes.insert(record.barcode).inserted else { continue }

                results.append(record)

                if results.count >= maxResults {
                    return results
                }
            }
        }

        return results
    }

    private func fetchProductList(queryItems: [URLQueryItem]) async throws -> FoodRepoProductListResponse {
        guard let apiKey = AppMetadata.foodRepoAPIKey else {
            return FoodRepoProductListResponse(data: [])
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.foodrepo.org"
        components.path = "/api/v3/products"
        components.queryItems = queryItems

        guard let url = components.url else {
            throw ProductLookupError.badResponse
        }

        var request = URLRequest(url: url)
        request.setValue(AppMetadata.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/vnd.api+json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token token=\"\(apiKey)\"", forHTTPHeaderField: "Authorization")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw OpenFoodFactsService.mapRequestError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw ProductLookupError.badResponse
        }

        switch http.statusCode {
        case 200..<300:
            break
        case 401, 403:
            return FoodRepoProductListResponse(data: [])
        default:
            throw OpenFoodFactsService.mapHTTPStatus(http.statusCode)
        }

        do {
            return try JSONDecoder().decode(FoodRepoProductListResponse.self, from: data)
        } catch {
            throw ProductLookupError.badResponse
        }
    }

    private func searchProducts(query: [String: Any], limit: Int) async throws -> FoodRepoSearchResponse {
        guard let apiKey = AppMetadata.foodRepoAPIKey else {
            return FoodRepoSearchResponse(hits: FoodRepoSearchHits(hits: []))
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "www.foodrepo.org"
        components.path = "/api/v3/products/_search"

        guard let url = components.url else {
            throw ProductLookupError.badResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(AppMetadata.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/vnd.api+json", forHTTPHeaderField: "Content-Type")
        request.setValue("Token token=\"\(apiKey)\"", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: searchRequestPayload(query: query, limit: limit))

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw OpenFoodFactsService.mapRequestError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw ProductLookupError.badResponse
        }

        switch http.statusCode {
        case 200..<300:
            break
        case 401, 403:
            return FoodRepoSearchResponse(hits: FoodRepoSearchHits(hits: []))
        default:
            throw OpenFoodFactsService.mapHTTPStatus(http.statusCode)
        }

        do {
            return try JSONDecoder().decode(FoodRepoSearchResponse.self, from: data)
        } catch {
            throw ProductLookupError.badResponse
        }
    }

    private func makeRecord(
        from product: FoodRepoProduct,
        fallbackBarcode: String,
        categoryHint: String? = nil
    ) -> ProviderProductRecord? {
        let normalizedBarcode = normalizedString(product.barcode) ?? fallbackBarcode
        guard !normalizedBarcode.isEmpty else {
            return nil
        }

        return ProviderProductRecord(
            providerID: providerID,
            barcode: normalizedBarcode,
            name: preferredLocalizedValue(from: product.displayNameTranslations) ?? AppText.text(.unknownProduct),
            brands: "",
            ingredientsText: preferredLocalizedValue(from: product.ingredientsTranslations) ?? "",
            allergens: [],
            traces: [],
            categoryLabels: categoryHint.map { [$0] } ?? [],
            imageURLString: preferredImageURL(from: product.images),
            lastModifiedAt: date(from: product.updatedAt)
        )
    }

    private func preferredLocalizedValue(from translations: [String: String]) -> String? {
        let preferredLanguageCodes = ["en", "no", "nb", "da", "sv", "fr", "de", "it"]

        for code in preferredLanguageCodes {
            if let value = normalizedString(translations[code]) {
                return value
            }
        }

        for key in translations.keys.sorted() {
            if let value = normalizedString(translations[key]) {
                return value
            }
        }

        return nil
    }

    private func preferredImageURL(from images: [FoodRepoImage]) -> String? {
        for image in images {
            if let value = normalizedString(image.medium) {
                return value
            }
            if let value = normalizedString(image.large) {
                return value
            }
            if let value = normalizedString(image.thumb) {
                return value
            }
            if let value = normalizedString(image.xlarge) {
                return value
            }
        }

        return nil
    }

    private func normalizedString(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func searchQuery(for categoryName: String) -> [String: Any] {
        let exactQuery = "\"\(categoryName)\""
        let tokenQuery = categoryName
            .split(whereSeparator: \.isWhitespace)
            .map(String.init)
            .filter { !$0.isEmpty }
            .joined(separator: " ")

        return [
            "bool": [
                "should": [
                    [
                        "query_string": [
                            "fields": ["_all_names"],
                            "query": exactQuery
                        ]
                    ],
                    [
                        "query_string": [
                            "fields": ["_all_text_translations.en"],
                            "query": exactQuery
                        ]
                    ],
                    [
                        "query_string": [
                            "fields": ["_all_names", "_all_text_translations.en"],
                            "query": tokenQuery
                        ]
                    ]
                ],
                "minimum_should_match": 1
            ]
        ]
    }

    private func searchRequestPayload(query: [String: Any], limit: Int) -> [String: Any] {
        [
            "_source": [
                "includes": [
                    "barcode",
                    "display_name_translations",
                    "ingredients_translations",
                    "images",
                    "updated_at"
                ]
            ],
            "size": max(1, limit),
            "query": query
        ]
    }

    private func date(from value: String?) -> Date? {
        guard let value = normalizedString(value) else { return nil }
        return Self.fractionalDateFormatter.date(from: value) ?? Self.standardDateFormatter.date(from: value)
    }

    private static let fractionalDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    private static let standardDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
