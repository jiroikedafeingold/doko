import Foundation

/// Static lookup table for item -> store categories, backed by
/// `ItemCategories.json` in the app bundle.
struct ItemDictionary {
    static let shared = ItemDictionary()

    private let table: [String: [StoreCategory]]

    init() {
        guard
            let url = Bundle.main.url(forResource: "ItemCategories", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let raw = try? JSONDecoder().decode([String: [String]].self, from: data)
        else {
            self.table = [:]
            return
        }
        var built: [String: [StoreCategory]] = [:]
        for (key, values) in raw {
            built[key] = values.compactMap { StoreCategory(rawValue: $0) }
        }
        self.table = built
    }

    /// Look up an item name in the dictionary, with a tiny pluralization fallback.
    func lookup(_ name: String) -> [StoreCategory]? {
        let normalized = ItemDictionary.normalize(name)
        if let direct = table[normalized] { return direct }

        if normalized.hasSuffix("ies") {
            let singular = String(normalized.dropLast(3)) + "y"
            if let result = table[singular] { return result }
        }
        if normalized.hasSuffix("es"), let result = table[String(normalized.dropLast(2))] {
            return result
        }
        if normalized.hasSuffix("s"), let result = table[String(normalized.dropLast())] {
            return result
        }
        return nil
    }

    static func normalize(_ name: String) -> String {
        name
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
