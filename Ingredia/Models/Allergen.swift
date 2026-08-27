import Foundation

struct AllergenDefinition: Identifiable, Hashable {
    let id: String
    let name: String
    let symbol: String
    let keywords: [String]

    static let supported: [AllergenDefinition] = [
        .init(id: "milk", name: "Melk", symbol: "drop.fill",
              keywords: ["milk", "melk", "lactose", "laktose", "whey", "myse", "casein", "kasein", "butter", "smør", "cream", "fløte"]),
        .init(id: "gluten", name: "Gluten", symbol: "leaf.fill",
              keywords: ["gluten", "wheat", "hvete", "rye", "rug", "barley", "bygg", "oats", "havre", "spelt"]),
        .init(id: "peanuts", name: "Peanøtter", symbol: "exclamationmark.triangle.fill",
              keywords: ["peanut", "peanuts", "peanøtt", "peanøtter", "jordnøtt", "jordnøtter"]),
        .init(id: "nuts", name: "Nøtter", symbol: "circle.hexagongrid.fill",
              keywords: ["almond", "mandel", "hazelnut", "hasselnøtt", "walnut", "valnøtt", "cashew", "pistachio", "pistasj", "pecan", "macadamia"]),
        .init(id: "eggs", name: "Egg", symbol: "oval.fill",
              keywords: ["egg", "eggs", "albumin"]),
        .init(id: "soybeans", name: "Soya", symbol: "circle.grid.cross.fill",
              keywords: ["soy", "soya", "soybean", "soybeans"]),
        .init(id: "sesame-seeds", name: "Sesam", symbol: "circle.grid.2x2.fill",
              keywords: ["sesame", "sesam", "tahini"]),
        .init(id: "fish", name: "Fisk", symbol: "fish.fill",
              keywords: ["fish", "fisk", "cod", "torsk", "salmon", "laks", "anchovy", "ansjos"]),
        .init(id: "crustaceans", name: "Skalldyr", symbol: "water.waves",
              keywords: ["crustacean", "shrimp", "prawn", "krabbe", "crab", "lobster", "hummer", "reke", "reker"]),
        .init(id: "celery", name: "Selleri", symbol: "leaf.circle.fill",
              keywords: ["celery", "selleri"]),
        .init(id: "mustard", name: "Sennep", symbol: "circle.dotted",
              keywords: ["mustard", "sennep"]),
        .init(id: "lupin", name: "Lupin", symbol: "leaf.arrow.circlepath",
              keywords: ["lupin", "lupine"]),
        .init(id: "molluscs", name: "Bløtdyr", symbol: "shell.fill",
              keywords: ["mollusc", "mollusk", "mussel", "blåskjell", "oyster", "østers", "squid", "blekksprut"]),
        .init(id: "sulphur-dioxide-and-sulphites", name: "Sulfitt", symbol: "aqi.medium",
              keywords: ["sulphite", "sulfite", "sulfitt", "sulphur dioxide", "svoveldioksid"])
    ]

    static func byID(_ id: String) -> AllergenDefinition? {
        supported.first { $0.id == id }
    }

    func localizedName(for language: AppLanguage = .current) -> String {
        switch language {
        case .norwegian:
            return name
        case .english:
            switch id {
            case "milk": return "Milk"
            case "gluten": return "Gluten"
            case "peanuts": return "Peanuts"
            case "nuts": return "Tree nuts"
            case "eggs": return "Eggs"
            case "soybeans": return "Soy"
            case "sesame-seeds": return "Sesame"
            case "fish": return "Fish"
            case "crustaceans": return "Crustaceans"
            case "celery": return "Celery"
            case "mustard": return "Mustard"
            case "lupin": return "Lupin"
            case "molluscs": return "Molluscs"
            case "sulphur-dioxide-and-sulphites": return "Sulphites"
            default: return name
            }
        case .thai:
            switch id {
            case "milk": return "นม"
            case "gluten": return "กลูเตน"
            case "peanuts": return "ถั่วลิสง"
            case "nuts": return "ถั่วเปลือกแข็ง"
            case "eggs": return "ไข่"
            case "soybeans": return "ถั่วเหลือง"
            case "sesame-seeds": return "งา"
            case "fish": return "ปลา"
            case "crustaceans": return "สัตว์น้ำเปลือกแข็ง"
            case "celery": return "เซเลอรี"
            case "mustard": return "มัสตาร์ด"
            case "lupin": return "ลูพิน"
            case "molluscs": return "หอย"
            case "sulphur-dioxide-and-sulphites": return "ซัลไฟต์"
            default: return name
            }
        }
    }
}
