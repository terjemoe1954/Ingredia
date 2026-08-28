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

    var errorDescription: String? {
        switch self {
        case .invalidBarcode:
            return AppText.text(.productLookupInvalidBarcode)
        case .productNotFound:
            return AppText.text(.productLookupNotFound)
        case .badResponse:
            return AppText.text(.productLookupBadResponse)
        case .offline:
            return AppText.text(.productLookupOffline)
        case .timedOut:
            return AppText.text(.productLookupTimedOut)
        case .serverIssue:
            return AppText.text(.productLookupServerIssue)
        }
    }
}

@MainActor
final class OpenFoodFactsService {
    static let shared = OpenFoodFactsService()

    func fetchProduct(barcode: String) async throws -> ScannedProduct {
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

        return Self.makeProduct(from: product, fallbackBarcode: clean)
    }

    func fetchAlternativeCandidates(
        categoryNames: [String],
        excludingBarcode barcode: String,
        limitPerCategory: Int = 12,
        maxResults: Int = 36
    ) async throws -> [ScannedProduct] {
        let cleanCategories = Array(
            NSOrderedSet(array: categoryNames.map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }.filter { !$0.isEmpty })
        ) as? [String] ?? []

        guard !cleanCategories.isEmpty else {
            return []
        }

        var seenBarcodes = Set<String>()
        var results: [ScannedProduct] = []

        for categoryName in cleanCategories {
            let products = try await fetchAlternativeCandidatesPage(
                categoryName: categoryName,
                excludingBarcode: barcode,
                limit: limitPerCategory
            )

            for product in products {
                guard seenBarcodes.insert(product.barcode).inserted else { continue }
                results.append(product)

                if results.count >= maxResults {
                    return results
                }
            }
        }

        return results
    }

    private static func normalizedTags(_ tags: [String]) -> [String] {
        tags.map {
            $0
                .replacingOccurrences(of: "en:", with: "")
                .replacingOccurrences(of: "no:", with: "")
                .lowercased()
        }
    }

    private func fetchAlternativeCandidatesPage(
        categoryName: String,
        excludingBarcode barcode: String,
        limit: Int
    ) async throws -> [ScannedProduct] {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "world.openfoodfacts.org"
        components.path = "/api/v2/search"
        components.queryItems = [
            URLQueryItem(name: "categories_tags_en", value: categoryName),
            URLQueryItem(name: "sort_by", value: "last_modified_t"),
            URLQueryItem(name: "page_size", value: String(limit)),
            URLQueryItem(
                name: "fields",
                value: "code,product_name,brands,ingredients_text,allergens_tags,traces_tags,categories_tags_en,image_front_small_url,last_modified_t"
            )
        ]

        let decoded: OFFSearchResponse = try await Self.fetch(url: components.url)
        return decoded.products.compactMap { product in
            guard product.code != barcode else { return nil }
            return Self.makeProduct(from: product)
        }
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

    private static func makeProduct(from product: OFFProduct, fallbackBarcode: String? = nil) -> ScannedProduct {
        ScannedProduct(
            barcode: product.code ?? fallbackBarcode ?? UUID().uuidString,
            name: safeName(from: product.productName),
            brands: product.brands ?? "",
            ingredientsText: product.ingredientsText ?? "",
            allergens: normalizedTags(product.allergensTags ?? []),
            traces: normalizedTags(product.tracesTags ?? []),
            categoryLabels: product.categoriesTagsEN?.filter { !$0.isEmpty } ?? [],
            imageURLString: product.imageFrontSmallURL,
            lastModifiedAt: date(fromUnixTimestamp: product.lastModifiedTimestamp)
        )
    }

    private static func safeName(from name: String?) -> String {
        if let name, !name.isEmpty {
            return name
        }
        return AppText.text(.unknownProduct)
    }

    private static func date(fromUnixTimestamp timestamp: Int?) -> Date? {
        guard let timestamp else { return nil }
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
        case 500...599:
            return .serverIssue
        default:
            return .badResponse
        }
    }
}
