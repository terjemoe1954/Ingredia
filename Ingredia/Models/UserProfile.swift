import Foundation
import SwiftData

@Model
final class UserProfile {
    var name: String
    var allergenIDs: [String]
    var rejectMayContain: Bool
    var diningNote: String
    var isActive: Bool
    var createdAt: Date

    init(
        name: String = AppText.text(.defaultProfileName),
        allergenIDs: [String] = [],
        rejectMayContain: Bool = true,
        diningNote: String = "",
        isActive: Bool = true,
        createdAt: Date = .now
    ) {
        self.name = name
        self.allergenIDs = allergenIDs
        self.rejectMayContain = rejectMayContain
        self.diningNote = diningNote
        self.isActive = isActive
        self.createdAt = createdAt
    }

    func contains(_ allergenID: String) -> Bool {
        allergenIDs.contains(allergenID)
    }

    func toggle(_ allergenID: String) {
        if let index = allergenIDs.firstIndex(of: allergenID) {
            allergenIDs.remove(at: index)
        } else {
            allergenIDs.append(allergenID)
        }
    }

    func displayName(language: AppLanguage) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? AppText.text(.defaultProfileName, language: language) : trimmed
    }

    var hasDiningNote: Bool {
        !diningNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    static func activeProfile(from profiles: [UserProfile]) -> UserProfile? {
        profiles.first(where: \.isActive) ?? profiles.first
    }

    static func fallbackActiveProfileAfterRemoving(
        profile removedProfile: UserProfile,
        from profiles: [UserProfile]
    ) -> UserProfile? {
        let remainingProfiles = profiles.filter { $0 != removedProfile }
        if removedProfile.isActive {
            return remainingProfiles.first
        }

        return activeProfile(from: remainingProfiles)
    }
}
