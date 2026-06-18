import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Resolves a shopping item name into one or more `StoreCategory` values.
/// Dictionary lookup runs first; if it misses and Apple Intelligence is
/// available, the on-device language model fills in the gap.
actor Categorizer {
    static let shared = Categorizer()

    private let dictionary = ItemDictionary.shared
    private var cache: [String: [StoreCategory]] = [:]

    func categories(for itemName: String) async -> [StoreCategory] {
        let key = ItemDictionary.normalize(itemName)
        if let cached = cache[key] { return cached }
        if let direct = dictionary.lookup(key) {
            cache[key] = direct
            return direct
        }
        let llm = await llmCategorize(itemName: itemName)
        if !llm.isEmpty {
            cache[key] = llm
            return llm
        }
        return [.uncategorized]
    }

    // MARK: - FoundationModels fallback

    private func llmCategorize(itemName: String) async -> [StoreCategory] {
#if canImport(FoundationModels)
        guard SystemLanguageModel.default.availability == .available else {
            return []
        }
        do {
            let session = LanguageModelSession()
            let prompt = """
            What kinds of stores typically sell "\(itemName)"? \
            Return only the most relevant categories from the allowed list.
            """
            let response = try await session.respond(
                to: prompt,
                generating: ItemClassification.self
            )
            return response.content.categories.compactMap(\.storeCategory)
        } catch {
            return []
        }
#else
        return []
#endif
    }
}

#if canImport(FoundationModels)
@Generable
struct ItemClassification {
    @Guide(description: "Up to 3 most relevant store categories that typically sell this item",
           .maximumCount(3))
    let categories: [CategoryToken]
}
#endif
