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
}
