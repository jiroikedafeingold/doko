import Foundation
import MapKit
#if canImport(FoundationModels)
import FoundationModels
#endif

/// Decides what a store is *for*, so the right list items show up — and so that
/// specialty-food spots (ice cream, coffee) and service businesses (salons,
/// gyms) are left out entirely instead of masquerading as grocery stores.
///
/// The guiding rule: a store only earns a category if a shopper would go there
/// to buy a genuine *range* of that category's goods. When in doubt, exclude.
actor StoreClassifier {
    static let shared = StoreClassifier()

    private var cache: [String: StoreVerdict] = [:]

    /// The outcome of classifying a store.
    enum StoreVerdict: Equatable {
        /// Show items in these specific categories.
        case specific([StoreCategory])
        /// A general-merchandise store (supercenter/dollar/variety) — show the
        /// whole list.
        case general
        /// Not a relevant shopping destination — leave it out of the results.
        case excluded
    }

    func classify(name: String, poiCategory: MKPointOfInterestCategory?) async -> StoreVerdict {
        let key = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if let cached = cache[key] { return cached }

        let verdict = await resolve(name: name, poiCategory: poiCategory)
        cache[key] = verdict
        return verdict
    }

    // MARK: - Pipeline

    private func resolve(name: String, poiCategory: MKPointOfInterestCategory?) async -> StoreVerdict {
        let lowered = name.lowercased()

        // 1. Hard exclusions by name — specialty-food vendors, services, and EV
        //    chargers that aren't a shopping-list errand. Runs first so it
        //    overrides MapKit mislabels (an ice cream shop tagged `.foodMarket`,
        //    or a ChargePoint stall tagged `.gasStation`).
        if Self.excludedWords.contains(where: { lowered.contains($0) })
            || Self.evChargingWords.contains(where: { lowered.contains($0) }) {
            return .excluded
        }

        // 2. Confident broad-format chains.
        if Self.generalMerchandiseChains.contains(where: { lowered.contains($0) }) {
            return .general
        }
        if Self.departmentStoreChains.contains(where: { lowered.contains($0) }) {
            return .specific(Self.departmentSoftGoods)
        }

        // 3. Specialty name hints (hardware, jeweler, pet store, …).
        let hintMatches = StoreCategory.nameHintCategories(for: name)
        if !hintMatches.isEmpty {
            return .specific(hintMatches)
        }

        // 4. Confident specific POI buckets (pharmacy, bank, gas, post office,
        //    bakery, food market).
        if let direct = StoreCategory.directCategory(for: poiCategory) {
            return .specific([direct])
        }

        // 5. Ambiguous (generic `.store` with an unrecognized name) — ask the
        //    on-device model to reason about the store's format. If it can't say
        //    confidently, the store is excluded rather than guessed.
        return await llmVerdict(name: name)
    }

    // MARK: - FoundationModels

    private func llmVerdict(name: String) async -> StoreVerdict {
#if canImport(FoundationModels)
        guard !name.isEmpty,
              SystemLanguageModel.default.availability == .available else {
            return .excluded
        }
        do {
            let session = LanguageModelSession(instructions: Self.instructions)
            let response = try await session.respond(
                to: "Store name: \"\(name)\"",
                generating: StoreClassification.self
            )
            return Self.verdict(from: response.content)
        } catch {
            return .excluded
        }
#else
        return .excluded
#endif
    }

#if canImport(FoundationModels)
    private static func verdict(from c: StoreClassification) -> StoreVerdict {
        switch c.kind {
        case .generalMerchandise:
            return .general
        case .departmentStore:
            return .specific(departmentSoftGoods)
        case .grocery:
            return .specific([.grocery])
        case .pharmacy:
            return .specific([.pharmacy])
        case .specialtyRetail:
            let cats = c.categories.compactMap(\.storeCategory)
            return cats.isEmpty ? .excluded : .specific(cats)
        case .excluded:
            return .excluded
        }
    }

    private static let instructions = """
    You categorize a brick-and-mortar store by its retail format, so an app can \
    decide which shopping-list items a person could buy there. You are given only \
    the store's name. Classify it into exactly one kind:

    - generalMerchandise: a big-box, supercenter, warehouse, dollar, or variety \
      store that stocks a wide everyday range across many categories, usually \
      including groceries (e.g. Walmart, Target, Costco, dollar stores).
    - departmentStore: a LARGE store with multiple full departments, or a \
      well-known off-price chain (e.g. Macy's, Nordstrom, Kohl's, TJ Maxx). \
      Thrift, vintage, consignment, resale, and small boutique shops are NOT \
      department stores — classify those as specialtyRetail (usually clothing).
    - grocery: a GENERAL food retailer stocking a broad range of groceries and \
      household staples — supermarket, market, bodega, corner store, mini-mart, \
      or convenience store.
    - pharmacy: a drugstore.
    - specialtyRetail: primarily sells goods in one or a few specific categories \
      from the allowed list (e.g. hardware store, jeweler, bookstore, pet store, \
      electronics store, sporting goods, a vintage clothing shop). Provide those \
      categories.
    - excluded: anything else. This includes restaurants, cafés, bars, and \
      single-food vendors like ice cream, coffee, candy, juice, donut, or deli \
      shops; all service businesses (salons, gyms, repair shops, clinics, spas, \
      tattoo parlors, dry cleaners); and any store too unclear to place.

    Rules:
    - A store must sell a real RANGE of a category's goods to earn it. A shop \
      selling only one or two food items is NOT grocery — it is excluded.
    - A business named only after a person (e.g. "Jane Smith", "Brianna \
      Beaudoin") with no retail-type word, and any freelance or by-appointment \
      professional (makeup artist, photographer, hair or nail stylist, \
      esthetician, personal trainer), is a service — exclude it.
    - Prefer excluded when uncertain. Leaving a store out is better than guessing.
    - Only use specialtyRetail categories the store is clearly built around.
    """
#endif

    // MARK: - Deterministic word lists (also the offline fallback)

    /// Names that mark a place as food-service or a single-item food vendor —
    /// excluded even if MapKit tagged it a food market.
    static let excludedWords: [String] = [
        "ice cream", "gelato", "frozen yogurt", "froyo", "creamery", "candy",
        "chocolate", "donut", "doughnut", "cupcake", "coffee", "espresso",
        "café", "cafe", "juice", "smoothie", "bubble tea", "boba", "tea house",
        "deli", "butcher", "restaurant", "grill", "diner", "bistro", "pizzeria",
        "pizza", "taqueria", "sushi", "ramen", "steakhouse", "bar & grill",
        "pub", "tavern", "brewery", "salon", "spa", "nail", "barber", "gym",
        "fitness", "yoga", "pilates", "tattoo", "massage", "dry clean",
        "laundromat", "repair", "mechanic", "auto repair", "car wash",
        "dentist", "dental", "clinic", "urgent care", "veterinar", "animal hospital",
        "makeup artist", "esthetician", "eyelash", "lash bar", "brow bar",
        "waxing", "permanent makeup", "photography", "photographer",
        "hair stylist", "hairstylist", "personal trainer"
    ]

    /// EV charging networks/stalls — MapKit often tags these `.gasStation`, but
    /// they sell none of the fuel-aisle items, so exclude them.
    static let evChargingWords: [String] = [
        "chargepoint", "ev charging", "ev charger", "charging station",
        "supercharger", "electrify america", "evgo", "blink charging"
    ]

    static let generalMerchandiseChains: [String] = [
        "walmart", "target", "costco", "sam's club", "bj's wholesale", "meijer",
        "fred meyer", "kmart", "dollar general", "dollar tree", "family dollar",
        "five below", "big lots", "supercenter"
    ]

    static let departmentStoreChains: [String] = [
        "macy", "nordstrom", "kohl", "jcpenney", "jc penney", "dillard",
        "bloomingdale", "marshalls", "tj maxx", "t.j. maxx", "ross dress",
        "burlington"
    ]

    /// The range a department store covers — soft goods, not groceries/hardware.
    static let departmentSoftGoods: [StoreCategory] = [
        .department, .clothing, .shoes, .jewelry, .beauty, .homeGoods, .toys
    ]
}

#if canImport(FoundationModels)
@Generable
struct StoreClassification {
    @Guide(description: "The store's retail format")
    let kind: StoreKind

    @Guide(description: "For specialtyRetail only: the specific categories the store is clearly built around",
           .maximumCount(4))
    let categories: [CategoryToken]
}

@Generable
enum StoreKind: String, Codable {
    case generalMerchandise
    case departmentStore
    case grocery
    case pharmacy
    case specialtyRetail
    case excluded
}
#endif
