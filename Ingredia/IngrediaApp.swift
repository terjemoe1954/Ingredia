import SwiftUI
import SwiftData

@main
struct IngrediaApp: App {
    @AppStorage(AppLanguage.storageKey) private var selectedLanguage = AppLanguage.norwegian.rawValue
    @AppStorage(AppTheme.storageKey) private var selectedTheme = AppTheme.system.rawValue

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.locale, Locale(identifier: language.localeIdentifier))
                .preferredColorScheme(theme.colorScheme)
        }
        .modelContainer(for: [
            UserProfile.self,
            ScannedProduct.self
        ])
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: selectedLanguage) ?? .norwegian
    }

    private var theme: AppTheme {
        AppTheme(rawValue: selectedTheme) ?? .system
    }
}
