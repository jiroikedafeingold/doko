import Foundation
import MapKit

extension StoreCategory {
    /// MapKit point-of-interest categories that map directly to this store category.
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
        case .uncategorized: []
        }
    }

    /// Lowercased substrings hinting at this category when MapKit only reports
    /// the broad `.store` POI bucket.
    var nameHints: [String] {
        switch self {
        case .hardware:    ["hardware", "home depot", "lowe", "ace hardware", "menards", "true value"]
        case .department:  ["target", "walmart", "kmart", "macy", "nordstrom", "kohl", "costco", "sam's club", "bj's"]
        case .electronics: ["best buy", "apple store", "micro center", "fry's", "electronics", "radioshack"]
        case .officeSupply: ["staples", "office depot", "officemax"]
        case .pet:         ["petco", "petsmart", "pet supplies"]
        case .garden:      ["garden", "nursery", "lawn"]
        case .liquor:      ["liquor", "wine shop", "spirits", "bottle shop"]
        case .bookstore:   ["barnes", "books-a-million", "bookstore", "bookshop"]
        case .clothing:    ["gap", "h&m", "uniqlo", "old navy", "zara", "clothing", "apparel", "outfitters"]
        case .pharmacy:    ["cvs", "walgreens", "rite aid", "duane reade", "pharmacy"]
        case .grocery:     ["whole foods", "trader joe", "kroger", "safeway", "publix", "wegmans",
                            "aldi", "stop & shop", "ralphs", "vons", "albertsons", "shoprite", "h-e-b"]
        default: []
        }
    }

    /// The full set of POI categories we ask MapKit to return when scanning
    /// what's near the user.
    static let poiSearchCategories: [MKPointOfInterestCategory] = [
        .foodMarket, .pharmacy, .bank, .atm, .store, .gasStation,
        .postOffice, .bakery, .evCharger, .animalService, .mailbox
    ]

    /// Resolve the `StoreCategory` values that best describe a MapKit map item.
    static func categories(for mapItem: MKMapItem) -> [StoreCategory] {
        let name = (mapItem.name ?? "").lowercased()
        let poi = mapItem.pointOfInterestCategory
        var matches: Set<StoreCategory> = []

        // 1. Direct POI matches (skip the broad `.store` bucket — needs name hint).
        if let poi {
            for category in StoreCategory.allCases where category != .uncategorized {
                if category.pointsOfInterest.contains(poi), poi != .store {
                    matches.insert(category)
                }
            }
        }

        // 2. Name-hint matches. Always applied (catches chains MapKit miscategorizes).
        for category in StoreCategory.allCases where !category.nameHints.isEmpty {
            if category.nameHints.contains(where: { name.contains($0) }) {
                matches.insert(category)
            }
        }

        // 3. Fallback: an unlabeled `.store` becomes a generic department store.
        if matches.isEmpty, poi == .store {
            matches.insert(.department)
        }

        return Array(matches)
    }
}
