import SwiftUI
import SwiftData

struct ProfileView: View {
    private enum Field: Hashable {
        case profileName
        case restaurantNote
    }

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \UserProfile.createdAt) private var profiles: [UserProfile]
    @AppStorage(AppLanguage.storageKey) private var selectedLanguage = AppLanguage.norwegian.rawValue
    @FocusState private var focusedField: Field?

    private var profile: UserProfile? { UserProfile.activeProfile(from: profiles) }

    var body: some View {
        NavigationStack {
            Group {
                if let profile {
                    List {
                        Section {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(AppText.text(.chooseActiveProfile, language: language))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                ForEach(profiles) { candidate in
                                    Button {
                                        setActiveProfile(candidate)
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(candidate.displayName(language: language))
                                                    .foregroundStyle(.primary)
                                                Text("\(candidate.allergenIDs.count) \(AppText.text(.selectedAllergens, language: language).lowercased())")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }

                                            Spacer()

                                            if candidate.isActive {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundStyle(.green)
                                            }
                                        }
                                        .padding(.vertical, 6)
                                    }
                                    .buttonStyle(.plain)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            deleteProfile(candidate)
                                        } label: {
                                            Label(AppText.text(.deleteProfile, language: language), systemImage: "trash")
                                        }

                                        Button {
                                            duplicateProfile(candidate)
                                        } label: {
                                            Label(AppText.text(.duplicateProfile, language: language), systemImage: "plus.square.on.square")
                                        }
                                        .tint(.blue)
                                    }
                                }

                                Button {
                                    createProfile()
                                } label: {
                                    Label(AppText.text(.createNewProfile, language: language), systemImage: "plus.circle.fill")
                                }
                            }
                        } header: {
                            Text(AppText.text(.activeProfile, language: language))
                        }

                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(AppText.text(.profileNameDescription, language: language))
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                TextField(
                                    AppText.text(.profileName, language: language),
                                    text: Binding(
                                        get: { profile.name },
                                        set: {
                                            profile.name = $0
                                            try? modelContext.save()
                                        }
                                    )
                                )
                                .textInputAutocapitalization(.words)
                                .focused($focusedField, equals: .profileName)
                            }
                        } header: {
                            Text(AppText.text(.profileName, language: language))
                        } footer: {
                            Text(AppText.text(.profileAutoSave, language: language))
                        }

                        Section {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(AppText.text(.allMyAllergens, language: language))
                                    .font(.title3.weight(.bold))
                                Text(AppText.text(.allergySelectionDescription, language: language))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.clear)

                        Section {
                            ForEach(AllergenDefinition.supported) { allergen in
                                Button {
                                    profile.toggle(allergen.id)
                                    try? modelContext.save()
                                } label: {
                                    HStack {
                                        Label(allergen.localizedName(for: language), systemImage: allergen.symbol)
                                            .foregroundStyle(.primary)
                                        Spacer()
                                        if profile.contains(allergen.id) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundStyle(.green)
                                        }
                                    }
                                    .padding(.vertical, 6)
                                }
                                .accessibilityLabel(allergen.localizedName(for: language))
                                .accessibilityValue(
                                    profile.contains(allergen.id)
                                    ? AppText.text(.accessibilitySelected, language: language)
                                    : AppText.text(.accessibilityNotSelected, language: language)
                                )
                            }
                        }

                        Section(AppText.text(.crossContamination, language: language)) {
                            Toggle(
                                AppText.text(.rejectMayContain, language: language),
                                isOn: Binding(
                                    get: { profile.rejectMayContain },
                                    set: {
                                        profile.rejectMayContain = $0
                                        try? modelContext.save()
                                    }
                                )
                            )

                            Text(AppText.text(.crossContaminationDescription, language: language))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }

                        Section(AppText.text(.restaurantNote, language: language)) {
                            Text(AppText.text(.restaurantNoteDescription, language: language))
                                .font(.footnote)
                                .foregroundStyle(.secondary)

                            TextField(
                                AppText.text(.restaurantNote, language: language),
                                text: Binding(
                                    get: { profile.diningNote },
                                    set: {
                                        profile.diningNote = $0
                                        try? modelContext.save()
                                    }
                                ),
                                axis: .vertical
                            )
                            .lineLimit(3...6)
                            .focused($focusedField, equals: .restaurantNote)
                        }

                        Section(AppText.text(.language, language: language)) {
                            Text(AppText.text(.languageDescription, language: language))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Picker(AppText.text(.language, language: language), selection: $selectedLanguage) {
                                ForEach(AppLanguage.allCases) { language in
                                    Text(language.displayName)
                                        .tag(language.rawValue)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        Section(AppText.text(.help, language: language)) {
                            NavigationLink {
                                HelpView()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(AppText.text(.help, language: language))
                                        .foregroundStyle(.primary)
                                    Text(AppText.text(.helpDescription, language: language))
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }

                        Section {
                            Text(AppText.text(.profileDisclaimer, language: language))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .scrollDismissesKeyboard(.interactively)
                } else {
                    ProgressView()
                        .task {
                            createProfile()
                        }
                }
            }
            .navigationTitle(AppText.text(.profile, language: language))
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()

                    Button(AppText.text(.done, language: language)) {
                        focusedField = nil
                    }
                }
            }
        }
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: selectedLanguage) ?? .norwegian
    }

    @MainActor
    private func createProfile() {
        for existing in profiles {
            existing.isActive = false
        }

        let profile = UserProfile(
            name: AppText.text(.newProfileDefaultName, language: language),
            isActive: true
        )
        modelContext.insert(profile)
        try? modelContext.save()
    }

    @MainActor
    private func setActiveProfile(_ profile: UserProfile) {
        for candidate in profiles {
            candidate.isActive = candidate == profile
        }
        try? modelContext.save()
    }

    @MainActor
    private func duplicateProfile(_ profile: UserProfile) {
        for candidate in profiles {
            candidate.isActive = false
        }

        let duplicatedProfile = UserProfile(
            name: "\(profile.displayName(language: language)) (\(AppText.text(.copiedProfileSuffix, language: language)))",
            allergenIDs: profile.allergenIDs,
            rejectMayContain: profile.rejectMayContain,
            diningNote: profile.diningNote,
            isActive: true
        )
        modelContext.insert(duplicatedProfile)
        try? modelContext.save()
    }

    @MainActor
    private func deleteProfile(_ profile: UserProfile) {
        guard profiles.count > 1 else { return }

        if let nextActiveProfile = UserProfile.fallbackActiveProfileAfterRemoving(profile: profile, from: profiles) {
            for candidate in profiles where candidate != profile {
                candidate.isActive = candidate == nextActiveProfile
            }
        }

        modelContext.delete(profile)
        try? modelContext.save()
    }
}
