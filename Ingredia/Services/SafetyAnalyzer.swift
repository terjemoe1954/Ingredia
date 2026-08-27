import Foundation
import SwiftUI

enum SafetyLevel: String {
    case compatible
    case caution
    case avoid
    case unknown

    var title: String {
        switch self {
        case .compatible: AppText.text(.safetyCompatible)
        case .caution: AppText.text(.safetyCaution)
        case .avoid: AppText.text(.safetyAvoid)
        case .unknown: AppText.text(.safetyUnknown)
        }
    }

    var systemImage: String {
        switch self {
        case .compatible: "checkmark.circle.fill"
        case .caution: "exclamationmark.triangle.fill"
        case .avoid: "xmark.octagon.fill"
        case .unknown: "questionmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .compatible:
            return .green
        case .caution:
            return .orange
        case .avoid:
            return .red
        case .unknown:
            return .gray
        }
    }
}

struct SafetyFinding: Identifiable {
    let id = UUID()
    let allergenName: String
    let reason: String
    let severe: Bool
}

struct SafetyResult {
    let level: SafetyLevel
    let findings: [SafetyFinding]
    let note: String
}

struct SafetyAnalyzer {
    static func analyze(product: ScannedProduct, profile: UserProfile?) -> SafetyResult {
        let language = AppLanguage.current

        guard let profile else {
            return SafetyResult(
                level: .unknown,
                findings: [],
                note: AppText.text(.createProfileForAssessment)
            )
        }

        guard !product.ingredientsText.isEmpty || !product.allergens.isEmpty || !product.traces.isEmpty else {
            return SafetyResult(
                level: .unknown,
                findings: [],
                note: AppText.text(.missingProductDataForAssessment)
            )
        }

        let ingredientText = product.ingredientsText.lowercased()
        let allergenTags = Set(product.allergens.map { cleanTag($0) })
        let traceTags = Set(product.traces.map { cleanTag($0) })
        var findings: [SafetyFinding] = []

        for allergenID in profile.allergenIDs {
            guard let definition = AllergenDefinition.byID(allergenID) else { continue }

            let directTagMatch = allergenTags.contains { Self.tag($0, matches: allergenID) }
            let ingredientMatch = definition.keywords.contains {
                ingredientText.localizedCaseInsensitiveContains($0)
            }

            if directTagMatch || ingredientMatch {
                findings.append(
                    SafetyFinding(
                        allergenName: definition.localizedName(for: language),
                        reason: AppText.text(.registeredAsIngredient),
                        severe: true
                    )
                )
                continue
            }

            let traceMatch = traceTags.contains { Self.tag($0, matches: allergenID) }
            if traceMatch {
                findings.append(
                    SafetyFinding(
                        allergenName: definition.localizedName(for: language),
                        reason: AppText.text(.registeredAsTrace),
                        severe: profile.rejectMayContain
                    )
                )
            }
        }

        if findings.contains(where: \.severe) {
            return SafetyResult(
                level: .avoid,
                findings: findings,
                note: AppText.text(.basedOnProfileAndProductData)
            )
        }

        if !findings.isEmpty {
            return SafetyResult(
                level: .caution,
                findings: findings,
                note: AppText.text(.allowedTraceNeedsCheck)
            )
        }

        return SafetyResult(
            level: .compatible,
            findings: [],
            note: AppText.text(.noRegisteredConflictsCheckPackaging)
        )
    }

    private static func cleanTag(_ tag: String) -> String {
        tag
            .replacingOccurrences(of: "en:", with: "")
            .replacingOccurrences(of: "no:", with: "")
            .lowercased()
    }

    private static func tag(_ tag: String, matches allergenID: String) -> Bool {
        let aliases: [String: [String]] = [
            "milk": ["milk", "melk"],
            "gluten": ["gluten", "wheat", "hvete"],
            "peanuts": ["peanuts", "peanut", "peanøtter"],
            "nuts": ["nuts", "tree-nuts", "nøtter"],
            "eggs": ["eggs", "egg"],
            "soybeans": ["soybeans", "soy", "soya"],
            "sesame-seeds": ["sesame-seeds", "sesame", "sesam"],
            "fish": ["fish", "fisk"],
            "crustaceans": ["crustaceans", "skalldyr"],
            "celery": ["celery", "selleri"],
            "mustard": ["mustard", "sennep"],
            "lupin": ["lupin"],
            "molluscs": ["molluscs", "mollusks", "bløtdyr"],
            "sulphur-dioxide-and-sulphites": ["sulphur-dioxide-and-sulphites", "sulfites", "sulphites", "sulfitt"]
        ]
        return aliases[allergenID, default: [allergenID]].contains(tag)
    }
}
