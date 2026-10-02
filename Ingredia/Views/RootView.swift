import SwiftUI
import SwiftData

struct RootView: View {
    @AppStorage(AppLanguage.storageKey) private var selectedLanguage = AppLanguage.norwegian.rawValue

    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label(AppText.text(.tabScan, language: language), systemImage: "barcode.viewfinder")
                }

            HistoryView()
                .tabItem {
                    Label(AppText.text(.tabHistory, language: language), systemImage: "clock")
                }

            RestaurantCardView()
                .tabItem {
                    Label(AppText.text(.tabRestaurantCard, language: language), systemImage: "fork.knife")
                }

            ProfileView()
                .tabItem {
                    Label(AppText.text(.tabProfile, language: language), systemImage: "person.crop.circle")
                }
        }
        .tint(Color.green)
    }

    private var language: AppLanguage {
        AppLanguage(rawValue: selectedLanguage) ?? .norwegian
    }
}
