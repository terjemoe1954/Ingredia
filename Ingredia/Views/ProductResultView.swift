import SwiftData
import SwiftUI

struct ProductResultView: View {
    private static let hideUnknownAlternativesStorageKey = "hideUnknownAlternatives"

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppLanguage.storageKey) private var selectedLanguage = AppLanguage.norwegian.rawValue
    @AppStorage(Self.hideUnknownAlternativesStorageKey) private var hideUnknownAlternatives = true
    @Query(sort: \ScannedProduct.lastScanned, order: .reverse) private var cachedProducts: [ScannedProduct]

    let product: ScannedProduct
    let profile: UserProfile?

    @State private var isLoadingAlternatives = false
    @State private var alternativesErrorMessage: String?
    @State private var alternativeOutcome: AlternativeLookupOutcome?
    @State private var selectedAlternativeProduct: ScannedProduct?

    private var productAssessment: ProductSafetyAssessment {
        AlternativeRankingService.assessment(for: product, profile: profile)
    }

    private var result: SafetyResult {
        productAssessment.result
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    productHeroCard
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                }

                Section(AppText.text(.assessment, language: language)) {
                    assessmentCard
                }

                Section(AppText.text(.productDataConfidence, language: language)) {
                    dataQualityCard
                }

                if !result.findings.isEmpty {
                    Section(AppText.text(.profileMatches, language: language)) {
                        ForEach(result.findings) { finding in
                            findingRow(finding)
                        }
                    }
                }

                Section(AppText.text(.betterAlternatives, language: language)) {
                    if isLoadingAlternatives {
                        ProgressView(AppText.text(.lookingForAlternatives, language: language))
                    } else if let alternativesErrorMessage {
                        VStack(alignment: .leading, spacing: 12) {
                            infoMessage(alternativesErrorMessage)

                            Button(AppText.text(.alternativeRetry, language: language)) {
                                Task {
                                    await loadAlternatives()
                                }
                            }
                            .font(.subheadline.weight(.semibold))
                        }
                    } else if let alternativeOutcome {
                        switch alternativeOutcome {
                        case .results(let products):
                            Toggle(
                                AppText.text(.alternativeFilterHideUnknown, language: language),
                                isOn: $hideUnknownAlternatives
                            )
                            .font(.subheadline)

                            HStack(alignment: .firstTextBaseline) {
                                Text(AppText.text(.alternativeFilterOnlyKnown, language: language))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                Spacer()

                                if !hideUnknownAlternatives {
                                    Button(AppText.text(.alternativeResetFilters, language: language)) {
                                        hideUnknownAlternatives = true
                                    }
                                    .font(.caption.weight(.semibold))
                                }
                            }

                            if filteredAlternatives(from: products).isEmpty {
                                infoMessage(AppText.text(.alternativeNoMatches, language: language))
                            } else {
                                ForEach(filteredAlternatives(from: products)) { alternative in
                                    Button {
                                        selectedAlternativeProduct = persistViewedAlternative(alternative.product)
                                    } label: {
                                        AlternativeRow(alternative: alternative, language: language)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        default:
                            infoMessage(alternativeOutcome.message)
                        }
                    }
                }

                if !product.ingredientsText.isEmpty {
                    Section(AppText.text(.ingredients, language: language)) {
                        Text(product.ingredientsText)
                    }
                }

                if !product.allergens.isEmpty {
                    Section(AppText.text(.registeredAllergens, language: language)) {
                        Text(product.allergens.joined(separator: ", "))
                    }
                }

                if !product.traces.isEmpty {
                    Section(AppText.text(.mayContainTracesOf, language: language)) {
                        Text(product.traces.joined(separator: ", "))
                    }
                }

                if hasLimitedProductData {
                    Section {
                        limitedDataCard
                    }
                }

                Section(AppText.text(.importantToCheck, language: language)) {
                    Text(result.note)
                        .font(.body)
                        .foregroundStyle(.primary)

                    Text(AppText.text(.advisoryDisclaimer, language: language))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section {
                    EmptyView()
                }
            }
            .navigationTitle(AppText.text(.product, language: language))
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedAlternativeProduct) { selectedProduct in
                ProductResultView(product: selectedProduct, profile: profile)
            }
            .task(id: product.barcode) {
                await loadAlternatives()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(AppText.text(.done, language: language)) { dismiss() }
                }
            }
        }
    }

    @MainActor
    private func loadAlternatives() async {
        isLoadingAlternatives = true
        alternativesErrorMessage = nil
        alternativeOutcome = nil

        do {
            alternativeOutcome = try await AlternativeProductService.shared.alternatives(
                for: product,
                profile: profile,
                cachedProducts: cachedProducts
            )
        } catch {
            alternativesErrorMessage = AppText.text(.alternativeFetchFailed, language: language)
        }

        isLoadingAlternatives = false
    }

    @MainActor
    private func persistViewedAlternative(_ product: ScannedProduct) -> ScannedProduct {
        let barcode = product.barcode
        let descriptor = FetchDescriptor<ScannedProduct>(
            predicate: #Predicate { $0.barcode == barcode }
        )

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.name = product.name
            existing.brands = product.brands
            existing.ingredientsText = product.ingredientsText
            existing.allergens = product.allergens
            existing.traces = product.traces
            existing.categoryLabels = product.categoryLabels
            existing.imageURLString = product.imageURLString
            existing.lastModifiedAt = product.lastModifiedAt
            existing.lastScanned = .now
            try? modelContext.save()
            return existing
        }

        let savedProduct = ScannedProduct(
            barcode: product.barcode,
            name: product.name,
            brands: product.brands,
            ingredientsText: product.ingredientsText,
            allergens: product.allergens,
            traces: product.traces,
            categoryLabels: product.categoryLabels,
            imageURLString: product.imageURLString,
            lastModifiedAt: product.lastModifiedAt,
            lastScanned: .now
        )
        modelContext.insert(savedProduct)
        try? modelContext.save()
        return savedProduct
    }

    private func filteredAlternatives(from products: [AlternativeProduct]) -> [AlternativeProduct] {
        guard hideUnknownAlternatives else {
            return products
        }

        return products.filter { $0.assessment.result.level != .unknown }
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: selectedLanguage) ?? .norwegian
    }

    private var productHeroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(AppText.text(.productOverviewTitle, language: language))
                .font(.headline)
                .foregroundStyle(.secondary)

            HStack(alignment: .top, spacing: 16) {
                productImage

                VStack(alignment: .leading, spacing: 8) {
                    Text(product.name)
                        .font(.title2.weight(.bold))

                    if !product.brands.isEmpty {
                        Text(product.brands)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(AppText.text(.scannedBarcode, language: language))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(product.barcode)
                            .font(.caption.monospaced())
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .accessibilityElement(children: .combine)
    }

    private var productImage: some View {
        Group {
            if let urlString = product.imageURLString,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFit()
                } placeholder: {
                    ProgressView()
                }
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "photo")
                        .font(.title2)
                    Text(AppText.text(.noImageAvailable, language: language))
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(.secondary)
                .padding(8)
            }
        }
        .frame(width: 96, height: 96)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }

    private var assessmentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: result.level.systemImage)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(result.level.color)

                Text(result.level.title)
                    .font(.title3.weight(.bold))
            }

            Text(result.note)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(result.level.color.opacity(0.12))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            [
                AppText.text(.assessment, language: language),
                "\(AppText.text(.accessibilityStatus, language: language)): \(result.level.title)",
                result.note
            ].joined(separator: ", ")
        )
    }

    private func findingRow(_ finding: SafetyFinding) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: finding.severe ? "exclamationmark.octagon.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(finding.severe ? Color.red : Color.orange)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(finding.allergenName)
                    .font(.headline)
                Text(finding.reason)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
    }

    private func infoMessage(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.vertical, 6)
            .accessibilityElement(children: .combine)
    }

    private var dataQualityCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(productAssessment.dataQuality.title)
                .font(.headline)

            Text(productAssessment.dataQuality.detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text(AppText.text(.productDataUpdated, language: language))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                if let lastModifiedAt = product.lastModifiedAt {
                    Text(lastModifiedAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                } else {
                    Text(AppText.text(.productDataUpdatedUnavailable, language: language))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            [
                AppText.text(.productDataConfidence, language: language),
                productAssessment.dataQuality.title,
                productAssessment.dataQuality.detail,
                AppText.text(.productDataUpdated, language: language),
                product.lastModifiedAt?.formatted(date: .abbreviated, time: .omitted)
                ?? AppText.text(.productDataUpdatedUnavailable, language: language)
            ].joined(separator: ", ")
        )
    }

    private var hasLimitedProductData: Bool {
        product.ingredientsText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        && product.allergens.isEmpty
        && product.traces.isEmpty
    }

    private var limitedDataCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(AppText.text(.limitedProductDataTitle, language: language), systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)

            Text(AppText.text(.limitedProductDataBody, language: language))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.orange.opacity(0.12))
        )
        .accessibilityElement(children: .combine)
    }

}

private struct AlternativeRow: View {
    let alternative: AlternativeProduct
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(alternative.product.name)
                        .font(.headline)

                    if !alternative.product.brands.isEmpty {
                        Text(alternative.product.brands)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    sourceBadge
                }

                Spacer()

                safetyChip
            }

            if let topFinding = alternative.assessment.result.findings.first {
                Text(topFinding.reason)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text(AppText.text(.noRegisteredConflictsInAvailableData))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(alternative.assessment.dataQuality.title + " • " + alternative.assessment.dataQuality.detail)
                .font(.caption)
                .foregroundStyle(.tertiary)

            if !alternative.recommendationReasons.isEmpty {
                Text(
                    alternative.recommendationReasons
                        .map { AppText.text($0, language: language) }
                        .joined(separator: " • ")
                )
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            [
                alternative.product.name,
                alternative.product.brands,
                sourceText,
                "\(AppText.text(.accessibilityStatus, language: language)): \(alternative.assessment.result.level.title)",
                alternative.assessment.dataQuality.title,
                alternative.recommendationReasons
                    .map { AppText.text($0, language: language) }
                    .joined(separator: ", ")
            ]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        )
        .accessibilityHint(AppText.text(.accessibilityOpensProduct, language: language))
    }

    private var sourceBadge: some View {
        Text(sourceText)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(alternative.isFromHistory ? Color.green : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(alternative.isFromHistory ? Color.green.opacity(0.14) : Color.secondary.opacity(0.12))
            )
    }

    private var safetyChip: some View {
        HStack(spacing: 6) {
            Image(systemName: alternative.assessment.result.level.systemImage)
                .font(.caption.weight(.bold))
            Text(alternative.assessment.result.level.title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .foregroundStyle(alternative.assessment.result.level.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule(style: .continuous)
                .fill(alternative.assessment.result.level.color.opacity(0.14))
        )
    }

    private var sourceText: String {
        AppText.text(
            alternative.isFromHistory ? .alternativeSourceHistory : .alternativeSourceDatabase,
            language: language
        )
    }
}
