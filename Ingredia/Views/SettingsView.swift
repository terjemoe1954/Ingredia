import SwiftUI

struct SettingsView: View {
    @AppStorage(AppLanguage.storageKey) private var selectedLanguage = AppLanguage.norwegian.rawValue
    @AppStorage(AppTheme.storageKey) private var selectedTheme = AppTheme.system.rawValue

    var body: some View {
        List {
            Section(AppText.text(.language, language: language)) {
                Text(AppText.text(.languageDescription, language: language))
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Picker(AppText.text(.language, language: language), selection: $selectedLanguage) {
                    ForEach(AppLanguage.allCases) { appLanguage in
                        Text(appLanguage.displayName)
                            .tag(appLanguage.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                Text(AppText.text(.languageSupport, language: language))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            Section(AppText.text(.appearance, language: language)) {
                Text(AppText.text(.appearanceDescription, language: language))
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Picker(AppText.text(.appearance, language: language), selection: $selectedTheme) {
                    ForEach(AppTheme.allCases) { theme in
                        Text(themeTitle(theme))
                            .tag(theme.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section(AppText.text(.help, language: language)) {
                NavigationLink {
                    HelpView()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(AppText.text(.userGuide, language: language))
                            .foregroundStyle(.primary)
                        Text(AppText.text(.helpDescription, language: language))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section(AppText.text(.dataSources, language: language)) {
                Text(AppText.text(.dataSourcesDescription, language: language))
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                ForEach(sourceStatuses.filter(\.isEnabled)) { status in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(status.name)
                            Spacer()
                            Text(AppText.text(.dataSourceActive, language: language))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.green)
                        }

                        Text(
                            status.supportsAlternativeSearch
                            ? AppText.text(.dataSourceAlternativeSearchAvailable, language: language)
                            : AppText.text(.dataSourceAlternativeSearchUnavailable, language: language)
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            Section(AppText.text(.appInformation, language: language)) {
                settingsValueRow(
                    title: AppText.text(.version, language: language),
                    value: AppMetadata.appVersion
                )

                settingsValueRow(
                    title: AppText.text(.build, language: language),
                    value: AppMetadata.buildNumber
                )
            }
        }
        .navigationTitle(AppText.text(.settings, language: language))
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: selectedLanguage) ?? .norwegian
    }

    private var sourceStatuses: [ProductDataSourceStatus] {
        ProductLookupAggregator.sourceStatuses()
    }

    private func themeTitle(_ theme: AppTheme) -> String {
        switch theme {
        case .system:
            return AppText.text(.appearanceSystem, language: language)
        case .dark:
            return AppText.text(.appearanceDark, language: language)
        case .light:
            return AppText.text(.appearanceLight, language: language)
        }
    }

    private func settingsValueRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(.secondary)
        }
    }
}
