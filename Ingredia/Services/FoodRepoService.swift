import Foundation

@MainActor
final class FoodRepoService: ProductDataProvider {
    static let shared = FoodRepoService()

    let providerID = "food_repo"
    let displayName = "Food Repo"
    let isEnabled = false
    let supportsAlternativeSearch = false
    let sourceTrustLevel = ProductSourceTrustLevel.limited

    func fetchProductRecord(barcode: String) async throws -> ProviderProductRecord? {
        nil
    }

    func fetchAlternativeCandidateRecords(
        categoryNames: [String],
        excludingBarcode barcode: String,
        limitPerCategory: Int,
        maxResults: Int
    ) async throws -> [ProviderProductRecord] {
        []
    }

    func validateAPIKey() async -> Bool {
        false
    }
}
