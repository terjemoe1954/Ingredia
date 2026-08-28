import Foundation

enum AppMetadata {
    static let appName = "Ingredia"
    static let appVersion = "0.1"

    // Set this to your real public support URL before App Store release.
    static let supportURLString: String? = nil

    static var userAgent: String {
        let platform = "iOS"

        if let supportURLString,
           !supportURLString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(appName)/\(appVersion) (\(platform); support: \(supportURLString))"
        }

        return "\(appName)/\(appVersion) (\(platform))"
    }
}
