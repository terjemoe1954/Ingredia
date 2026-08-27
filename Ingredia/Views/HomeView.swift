import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @Query(sort: \ScannedProduct.lastScanned, order: .reverse) private var products: [ScannedProduct]
    @AppStorage(AppLanguage.storageKey) private var selectedLanguage = AppLanguage.norwegian.rawValue

    @State private var showingScanner = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedProduct: ScannedProduct?

    private var profile: UserProfile? { UserProfile.activeProfile(from: profiles) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    profileSummaryCard
                    scanCallToAction

                    if isLoading {
                        ProgressView(AppText.text(.loadingProductInformation, language: language))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    if let errorMessage {
                        ContentUnavailableView(
                            AppText.text(.fetchProductFailed, language: language),
                            systemImage: "exclamationmark.triangle",
                            description: Text(errorMessage)
                        )
                    }

                    if !products.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Text(AppText.text(.recentlyScanned, language: language))
                                .font(.title3.bold())

                            ForEach(products.prefix(5)) { product in
                                Button {
                                    selectedProduct = product
                                } label: {
                                    RecentProductRow(product: product, profile: profile)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding()
            }
            .navigationTitle("Ingredia")
            .sheet(isPresented: $showingScanner) {
                NavigationStack {
                    ZStack {
                        BarcodeScannerView { code in
                            showingScanner = false
                            Task {
                                await lookup(code: code)
                            }
                        }
                        .ignoresSafeArea()

                        VStack {
                            Spacer()
                            Text(AppText.text(.positionBarcode, language: language))
                                .font(.headline)
                                .padding()
                                .background(.ultraThinMaterial, in: Capsule())
                                .padding(.bottom, 40)
                        }
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(AppText.text(.close, language: language)) { showingScanner = false }
                        }
                    }
                }
            }
            .sheet(item: $selectedProduct) { product in
                ProductResultView(product: product, profile: profile)
            }
            .task {
                createDefaultProfileIfNeeded()
            }
        }
    }

    private var profileSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(AppText.text(.yourProfile, language: language))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text(profileDisplayName)
                        .font(.title3.weight(.bold))
                }

                Spacer()

                Image(systemName: profileHasSelections ? "checkmark.shield.fill" : "slider.horizontal.3")
                    .font(.title2)
                    .foregroundStyle(profileHasSelections ? Color.green : Color.orange)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(AppText.text(.selectedAllergens, language: language))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                if profileHasSelections {
                    Text(selectedAllergenList)
                        .font(.body)
                        .foregroundStyle(.primary)
                } else {
                    Text(AppText.text(.noAllergensSelected, language: language))
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
            }

            Text(AppText.text(.chooseAllergensBeforeAssessment, language: language))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(profileAccessibilityLabel)
    }

    private var scanCallToAction: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(AppText.text(.scanIntroTitle, language: language))
                .font(.title2.weight(.bold))

            Text(AppText.text(.scanIntroBody, language: language))
                .font(.body)
                .foregroundStyle(.secondary)

            Button {
                showingScanner = true
            } label: {
                HStack {
                    Label(AppText.text(.scanProduct, language: language), systemImage: "barcode.viewfinder")
                        .font(.headline)
                    Spacer()
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.title3)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 18)
                .padding(.vertical, 18)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.green, Color.blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .accessibilityElement(children: .contain)
    }

    private var profileHasSelections: Bool {
        !(profile?.allergenIDs.isEmpty ?? true)
    }

    private var profileTitle: String {
        profileHasSelections
            ? AppText.text(.profileReadyTitle, language: language)
            : AppText.text(.profileNotReadyTitle, language: language)
    }

    private var selectedAllergenList: String {
        profile?.allergenIDs
            .compactMap { AllergenDefinition.byID($0)?.localizedName(for: language) }
            .joined(separator: " • ") ?? ""
    }

    private var profileAccessibilityLabel: String {
        let allergens = profileHasSelections
            ? "\(AppText.text(.accessibilitySelectedAllergens, language: language)): \(selectedAllergenList)"
            : AppText.text(.accessibilityNoSelectedAllergens, language: language)

        return [
            AppText.text(.yourProfile, language: language),
            profileDisplayName,
            profileTitle,
            allergens
        ].joined(separator: ", ")
    }

    private var profileDisplayName: String {
        profile?.displayName(language: language) ?? AppText.text(.defaultProfileName, language: language)
    }

    @MainActor
    private func createDefaultProfileIfNeeded() {
        guard profiles.isEmpty else { return }
        modelContext.insert(UserProfile())
        try? modelContext.save()
    }

    @MainActor
    private func lookup(code: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let fetched = try await OpenFoodFactsService.shared.fetchProduct(barcode: code)

            let descriptor = FetchDescriptor<ScannedProduct>(
                predicate: #Predicate { $0.barcode == code }
            )

            if let existing = try? modelContext.fetch(descriptor).first {
                existing.name = fetched.name
                existing.brands = fetched.brands
                existing.ingredientsText = fetched.ingredientsText
                existing.allergens = fetched.allergens
                existing.traces = fetched.traces
                existing.categoryLabels = fetched.categoryLabels
                existing.imageURLString = fetched.imageURLString
                existing.lastModifiedAt = fetched.lastModifiedAt
                existing.lastScanned = .now
                selectedProduct = existing
            } else {
                modelContext.insert(fetched)
                selectedProduct = fetched
            }

            try? modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: selectedLanguage) ?? .norwegian
    }
}

private struct RecentProductRow: View {
    let product: ScannedProduct
    let profile: UserProfile?

    var result: SafetyResult {
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
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(.systemBackground))
        )
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            [
                product.name,
                product.brands,
                "\(AppText.text(.accessibilityStatus)): \(result.level.title)"
            ]
            .filter { !$0.isEmpty }
            .joined(separator: ", ")
        )
        .accessibilityHint(AppText.text(.accessibilityOpensProduct))
    }

}
