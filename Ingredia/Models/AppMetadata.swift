import Foundation
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case dark
    case light

    static let storageKey = "selectedTheme"

    var id: String { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system:
            return nil
        case .dark:
            return .dark
        case .light:
            return .light
        }
    }
}

enum AppMetadata {
    static let appName = "Ingredia"

    // Set this to your real public support URL before App Store release.
    static let supportURLString: String? = nil

    // Keep third-party API keys out of source control for production builds.
    // During development you can inject this as an environment variable or Info.plist value.
    static let foodRepoAPIKeyInfoKey = "FOODREPO_API_KEY"

    static var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1"
    }

    static var buildNumber: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }

    static var userAgent: String {
        let platform = "iOS"

        if let supportURLString,
           !supportURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(appName)/\(appVersion) (\(platform); support: \(supportURLString))"
        }

        return "\(appName)/\(appVersion) (\(platform))"
    }

    static var foodRepoAPIKey: String? {
        let environmentValue = ProcessInfo.processInfo.environment[foodRepoAPIKeyInfoKey]
        if let trimmed = normalizedOptionalString(environmentValue) {
            return trimmed
        }

        let infoPlistValue = Bundle.main.object(forInfoDictionaryKey: foodRepoAPIKeyInfoKey) as? String
        return normalizedOptionalString(infoPlistValue)
    }

    static var hasFoodRepoAPIKey: Bool {
        foodRepoAPIKey != nil
    }

    private static func normalizedOptionalString(_ value: String?) -> String? {
        guard let value else { return nil }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
