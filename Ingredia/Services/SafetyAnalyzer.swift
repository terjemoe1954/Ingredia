import Foundation
import SwiftUI

enum SafetyLevel: String {
    case compatible
    case caution
    case avoid
    case unknown

    var title: String {
        title(language: .current)
    }

    func title(language: AppLanguage) -> String {
        switch self {
        case .compatible: AppText.text(.safetyCompatible, language: language)
        case .caution: AppText.text(.safetyCaution, language: language)
        case .avoid: AppText.text(.safetyAvoid, language: language)
        case .unknown: AppText.text(.safetyUnknown, language: language)
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
    static func analyze(product: ScannedProduct, profile: UserProfile?, language: AppLanguage = .current) -> SafetyResult {
        guard let profile else {
            return SafetyResult(
                level: .unknown,
                findings: [],
                note: AppText.text(.createProfileForAssessment, language: language)
            )
        }

        let ingredientText = product.ingredientsText.trimmingCharacters(in: .whitespacesAndNewlines)
        let allergenTags = Set(ProductTagFormatting.normalizedTags(product.allergens))
        let traceTags = Set(ProductTagFormatting.normalizedTags(product.traces))
        guard !ingredientText.isEmpty || !allergenTags.isEmpty || !traceTags.isEmpty else {
            return SafetyResult(
                level: .unknown,
                findings: [],
                note: AppText.text(.missingProductDataForAssessment, language: language)
            )
        }

        let normalizedIngredientText = ingredientText.lowercased()
        var findings: [SafetyFinding] = []

        for allergenID in profile.allergenIDs {
            guard let definition = AllergenDefinition.byID(allergenID) else { continue }

            let directTagMatch = allergenTags.contains { Self.tag($0, matches: allergenID) }
            let ignoresIngredientKeywords = allergenID == "gluten"
                && Self.declaresGlutenFree(normalizedIngredientText)
            let ingredientMatch: Bool
            if ignoresIngredientKeywords {
                ingredientMatch = false
            } else {
                ingredientMatch = definition.keywords.contains {
                    Self.ingredientText(normalizedIngredientText, containsKeyword: $0)
                }
            }

            if directTagMatch || ingredientMatch {
                findings.append(
                    SafetyFinding(
                        allergenName: definition.localizedName(for: language),
                        reason: AppText.text(.registeredAsIngredient, language: language),
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
                        reason: AppText.text(.registeredAsTrace, language: language),
                        severe: profile.rejectMayContain
                    )
                )
            }
        }

        if findings.contains(where: \.severe) {
            return SafetyResult(
                level: .avoid,
                findings: findings,
                note: AppText.text(.basedOnProfileAndProductData, language: language)
            )
        }

        if !findings.isEmpty {
            return SafetyResult(
                level: .caution,
                findings: findings,
                note: AppText.text(.allowedTraceNeedsCheck, language: language)
            )
        }

        return SafetyResult(
            level: .compatible,
            findings: [],
            note: AppText.text(.noRegisteredConflictsCheckPackaging, language: language)
        )
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

    private static func declaresGlutenFree(_ text: String) -> Bool {
        text.contains("glutenfri")
        || text.contains("gluten-free")
        || text.contains("uten gluten")
        || text.contains("without gluten")
    }

    private static func ingredientText(_ text: String, containsKeyword keyword: String) -> Bool {
        let textTokens = tokens(in: text)
        let keywordTokens = tokens(in: keyword)

        guard !keywordTokens.isEmpty, textTokens.count >= keywordTokens.count else {
            return false
        }

        if keywordTokens.count == 1 {
            return textTokens.contains(keywordTokens[0])
        }

        return textTokens.indices.contains { startIndex in
            let endIndex = startIndex + keywordTokens.count
            guard endIndex <= textTokens.count else { return false }
            return Array(textTokens[startIndex..<endIndex]) == keywordTokens
        }
    }

    private static func tokens(in value: String) -> [String] {
        value
            .lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
    }
}
