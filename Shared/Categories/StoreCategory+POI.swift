import Foundation
import MapKit

extension StoreCategory {
    /// MapKit point-of-interest categories that map directly to this store category.
    /// Note: MapKit has no specific retail subtypes — most shops come back as the
    /// broad `.store` bucket, so name hints and the LLM do the real work.
    var pointsOfInterest: Set<MKPointOfInterestCategory> {
        switch self {
        case .grocery:       [.foodMarket]
        case .pharmacy:      [.pharmacy]
        case .hardware:      [.store]
        case .bank:          [.bank, .atm]
        case .department:    [.store]
        case .electronics:   [.store]
        case .officeSupply:  [.store]
        case .pet:           [.store, .animalService]
        case .garden:        [.store]
        case .liquor:        [.store]
        case .bakery:        [.bakery]
        case .clothing:      [.store]
        case .bookstore:     [.store]
        case .gasStation:    [.gasStation, .evCharger]
        case .postOffice:    [.postOffice, .mailbox]
        case .jewelry:       [.store]
        case .furniture:     [.store]
        case .toys:          [.store]
        case .sportingGoods: [.store]
        case .music:         [.store]
        case .craft:         [.store]
        case .beauty:        [.store, .beauty]
        case .shoes:         [.store]
        case .homeGoods:     [.store]
        case .autoParts:     [.store]
        case .uncategorized: []
        }
    }

    /// Lowercased substrings hinting at this category when MapKit only reports
    /// the broad `.store` POI bucket.
    var nameHints: [String] {
        switch self {
        case .hardware:    ["hardware", "home depot", "lowe", "ace hardware", "menards", "true value"]
        case .department:  ["target", "walmart", "kmart", "macy", "nordstrom", "kohl", "costco", "sam's club", "bj's", "department store"]
        case .electronics: ["best buy", "apple store", "micro center", "fry's", "electronics", "radioshack"]
        case .officeSupply: ["staples", "office depot", "officemax"]
        case .pet:         ["petco", "petsmart", "pet supplies", "pet store"]
        case .garden:      ["garden", "nursery", "lawn"]
        case .liquor:      ["liquor", "wine shop", "spirits", "bottle shop"]
        case .bookstore:   ["barnes", "books-a-million", "bookstore", "bookshop", "powell's books"]
        case .clothing:    ["gap", "h&m", "uniqlo", "old navy", "zara", "clothing", "apparel", "outfitters"]
        case .pharmacy:    ["cvs", "walgreens", "rite aid", "duane reade", "pharmacy"]
        case .grocery:     ["whole foods", "trader joe", "kroger", "safeway", "publix", "wegmans",
                            "aldi", "stop & shop", "ralphs", "vons", "albertsons", "shoprite", "h-e-b"]
        case .jewelry:     ["jewelry", "jeweler", "jewellers", "tiffany", "kay jewelers", "zales", "pandora", "claire's"]
        case .furniture:   ["furniture", "ikea", "ashley", "west elm", "crate & barrel", "crate and barrel", "pottery barn", "la-z-boy", "mattress"]
        case .toys:        ["toys", "toy store", "toys r us", "build-a-bear", "lego store"]
        case .sportingGoods: ["sporting goods", "dick's", "rei", "academy sports", "sports authority", "big 5", "bass pro", "cabela"]
        case .music:       ["guitar center", "sam ash", "music store", "instruments", "sweetwater"]
        case .craft:       ["michaels", "jo-ann", "joann", "hobby lobby", "craft store", "fabric store"]
        case .beauty:      ["sephora", "ulta", "sally beauty", "cosmetics", "beauty supply"]
        case .shoes:       ["foot locker", "footlocker", "famous footwear", "dsw", "payless", "shoe store", "sneaker"]
        case .homeGoods:   ["homegoods", "home goods", "bed bath", "container store", "pier 1", "pier one", "home decor"]
        case .autoParts:   ["autozone", "o'reilly", "advance auto", "napa auto", "pep boys", "auto parts", "car parts"]
        default: []
        }
    }

    /// The full set of POI categories we ask MapKit to return when scanning
    /// what's near the user.
    static let poiSearchCategories: [MKPointOfInterestCategory] = [
        .foodMarket, .pharmacy, .bank, .atm, .store, .gasStation,
        .postOffice, .bakery, .evCharger, .animalService, .mailbox, .beauty
    ]

    /// Deterministic, offline first pass at describing a MapKit map item. Uses
    /// the direct POI mapping plus name-hint keyword matching. Returns an empty
    /// array when nothing matches — the caller then asks the on-device model or
    /// treats the place as a general store, rather than guessing "department".
    static func deterministicCategories(for mapItem: MKMapItem) -> [StoreCategory] {
        let name = (mapItem.name ?? "").lowercased()
        let poi = mapItem.pointOfInterestCategory
        var matches: Set<StoreCategory> = []

        // 1. Direct POI matches (skip the broad `.store` bucket — needs name hint).
        if let poi {
            for category in StoreCategory.selectable {
                if category.pointsOfInterest.contains(poi), poi != .store {
                    matches.insert(category)
                }
            }
        }

        // 2. Name-hint matches. Always applied (catches chains MapKit miscategorizes).
        for category in StoreCategory.selectable where !category.nameHints.isEmpty {
            if category.nameHints.contains(where: { name.contains($0) }) {
                matches.insert(category)
            }
        }

        return Array(matches)
    }
}
