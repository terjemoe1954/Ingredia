import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \ScannedProduct.lastScanned, order: .reverse) private var products: [ScannedProduct]
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @AppStorage(AppLanguage.storageKey) private var selectedLanguage = AppLanguage.norwegian.rawValue

    var body: some View {
        NavigationStack {
            List {
                if !products.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(AppText.text(.historySummaryTitle, language: language))
                                .font(.title3.weight(.bold))
                            Text(AppText.text(.historySummaryBody, language: language))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(products.count) \(AppText.text(.savedScansCount, language: language))")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 6)
                    }
                    .listRowBackground(Color.clear)

                    Section {
                        ForEach(products) { product in
                            NavigationLink {
                                ProductResultView(product: product, profile: UserProfile.activeProfile(from: profiles))
                            } label: {
                                HistoryProductRow(product: product, profile: UserProfile.activeProfile(from: profiles))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .overlay {
                if products.isEmpty {
                    ContentUnavailableView(
                        AppText.text(.noScansYet, language: language),
                        systemImage: "barcode.viewfinder",
                        description: Text(AppText.text(.scanFirstProduct, language: language))
                    )
                }
            }
            .navigationTitle(AppText.text(.history, language: language))
        }
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: selectedLanguage) ?? .norwegian
    }
}

private struct HistoryProductRow: View {
    let product: ScannedProduct
    let profile: UserProfile?

    private var result: SafetyResult {
        SafetyAnalyzer.analyze(product: product, profile: profile)
    }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: result.level.systemImage)
                .font(.title3.weight(.bold))
                .foregroundStyle(result.level.color)
                .frame(width: 42, height: 42)
                .background(
                    Circle()
                        .fill(result.level.color.opacity(0.12))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                if !product.brands.isEmpty {
                    Text(product.brands)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Text(result.level.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Text(product.lastScanned, format: .dateTime.day().month().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(.vertical, 6)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            [
                product.name,
                product.brands,
                "\(AppText.text(.accessibilityStatus)): \(result.level.title)",
                product.lastScanned.formatted(.dateTime.day().month().hour().minute())
            ]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        )
        .accessibilityHint(AppText.text(.accessibilityOpensProduct))
    }

}
