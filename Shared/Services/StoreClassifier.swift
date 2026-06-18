import Foundation
import MapKit
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Figures out what kinds of things a store sells, given only its name and the
/// coarse MapKit POI bucket. Deterministic keyword matching runs first; when
/// that comes up empty, the on-device language model reasons about the store
/// name ("Lumens Lighting" -> hardware/home goods). Results are cached by name.
actor StoreClassifier {
    static let shared = StoreClassifier()

    private var cache: [String: [StoreCategory]] = [:]

    /// Returns the categories a store plausibly sells. An empty result means
    /// "couldn't tell" — the caller should treat the place as a general store.
    func classify(name: String, poiCategory: MKPointOfInterestCategory?) async -> [StoreCategory] {
        let key = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if let cached = cache[key] { return cached }

        let llm = await llmClassify(name: name, poiCategory: poiCategory)
        cache[key] = llm
        return llm
    }

    // MARK: - FoundationModels

    private func llmClassify(name: String,
                             poiCategory: MKPointOfInterestCategory?) async -> [StoreCategory] {
#if canImport(FoundationModels)
        guard !name.isEmpty,
              SystemLanguageModel.default.availability == .available else {
            return []
        }
        do {
            let session = LanguageModelSession()
            let prompt = """
            A shopper is standing in front of a store named "\(name)". \
            Based on the name, what kinds of products does this store most likely sell? \
            Return only the relevant categories from the allowed list. If the name \
            gives no clear signal, return no categories.
            """
            let response = try await session.respond(
                to: prompt,
                generating: StoreClassification.self
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
struct StoreClassification {
    @Guide(description: "Up to 4 product categories this store most likely sells",
           .maximumCount(4))
    let categories: [CategoryToken]
}
#endif
