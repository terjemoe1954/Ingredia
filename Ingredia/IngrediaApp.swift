import SwiftUI
import SwiftData

@main
struct IngrediaApp: App {
    @AppStorage(AppLanguage.storageKey) private var selectedLanguage = AppLanguage.norwegian.rawValue

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.locale, Locale(identifier: language.localeIdentifier))
        }
        .modelContainer(for: [
            UserProfile.self,
            ScannedProduct.self
        ])
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: selectedLanguage) ?? .norwegian
    }
}
