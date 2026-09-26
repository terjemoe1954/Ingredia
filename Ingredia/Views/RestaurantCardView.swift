import SwiftUI
import SwiftData

struct RestaurantCardView: View {
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @AppStorage(AppLanguage.storageKey) private var selectedLanguage = AppLanguage.norwegian.rawValue

    private var profile: UserProfile? { UserProfile.activeProfile(from: profiles) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    cardHeader

                    if let profile, !profile.allergenIDs.isEmpty {
                        allergyCard(profile: profile)
                    } else {
                        emptyCardState
                    }
                }
                .padding()
                .frame(maxWidth: 680)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(AppText.text(.restaurantCard, language: language))
        }
    }

    private var cardHeader: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.shield.fill")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 84, height: 84)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.red, Color.orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )

            Text(AppText.text(.allergyCardTitle, language: language))
                .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                .multilineTextAlignment(.center)

            Text(AppText.text(.allergyCardSubtitle, language: language))
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let profile {
                Text(profile.displayName(language: language))
                    .font(.title3.weight(.semibold))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    )
            }
        }
        .padding(.top, 12)
    }

    private func allergyCard(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(AppText.text(.iMustAvoid, language: language))
                .font(.title2.weight(.bold))

            VStack(spacing: 12) {
                ForEach(profile.allergenIDs, id: \.self) { id in
                    if let allergen = AllergenDefinition.byID(id) {
                        HStack(spacing: 14) {
                            Image(systemName: allergen.symbol)
                                .font(.title3.weight(.semibold))
                                .frame(width: 28)
                                .foregroundStyle(Color.red)

                            Text(allergen.localizedName(for: language))
                                .font(.title3.weight(.semibold))

                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.red.opacity(0.08))
                        )
                    }
                }
            }

            if profile.rejectMayContain {
                VStack(alignment: .leading, spacing: 8) {
                    Text(AppText.text(.crossContaminationWarningTitle, language: language))
                        .font(.headline)
                    Text(AppText.text(.avoidCrossContamination, language: language))
                        .font(.body)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.orange.opacity(0.12))
                )
            }

            if profile.hasDiningNote {
                VStack(alignment: .leading, spacing: 8) {
                    Text(AppText.text(.restaurantNote, language: language))
                        .font(.headline)
                    Text(profile.diningNote)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.blue.opacity(0.10))
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(AppText.text(.pleaseVerifyPreparation, language: language))
                    .font(.headline)
                Text(AppText.text(.showCardToStaff, language: language))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }

    private var emptyCardState: some View {
        VStack(spacing: 16) {
            Text(AppText.text(.chooseAllergensForCard, language: language))
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color(.systemBackground))
        )
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: selectedLanguage) ?? .norwegian
    }
}
