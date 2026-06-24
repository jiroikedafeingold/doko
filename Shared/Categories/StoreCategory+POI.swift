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
        case .bank:          [.bank, .atm]
        case .bakery:        [.bakery]
        case .gasStation:    [.gasStation]
        case .postOffice:    [.postOffice]
        // Everything else is the generic `.store` bucket — resolved by name/LLM.
        case .hardware, .department, .electronics, .officeSupply, .pet, .garden,
             .liquor, .clothing, .bookstore, .jewelry, .furniture, .toys,
             .sportingGoods, .music, .craft, .beauty, .shoes, .homeGoods, .autoParts:
            [.store]
        case .uncategorized: []
        }
    }

    /// Lowercased substrings hinting at this specific category when MapKit only
    /// reports the broad `.store` bucket. These cover *specialty* retailers; broad
    /// formats (supercenters, department stores) are handled in `StoreClassifier`.
    var nameHints: [String] {
        switch self {
        case .hardware:    ["hardware", "home depot", "lowe", "ace hardware", "menards", "true value"]
        case .department:  ["macy", "nordstrom", "kohl", "jcpenney", "jc penney", "dillard", "bloomingdale", "department store"]
        case .electronics: ["best buy", "apple store", "micro center", "fry's", "electronics", "radioshack"]
        case .officeSupply: ["staples", "office depot", "officemax", "office supply"]
        case .pet:         ["petco", "petsmart", "pet supplies", "pet store", "pet shop"]
        case .garden:      ["garden center", "plant nursery", "lawn & garden"]
        case .liquor:      ["liquor", "wine shop", "spirits", "bottle shop"]
        case .bookstore:   ["barnes", "books-a-million", "bookstore", "bookshop", "powell's books"]
        case .clothing:    ["gap outlet", "h&m", "uniqlo", "old navy", "zara", "clothing store",
                            "apparel", "outfitters", "thrift", "consignment", "resale"]
        case .pharmacy:    ["cvs", "walgreens", "rite aid", "duane reade", "pharmacy", "drugstore", "drug store"]
        case .grocery:     ["whole foods", "trader joe", "kroger", "safeway", "publix", "wegmans",
                            "aldi", "stop & shop", "ralphs", "vons", "albertsons", "shoprite", "h-e-b",
                            "supermarket", "grocery", "bodega", "mini mart", "minimart", "convenience store"]
        case .jewelry:     ["jewelry", "jeweler", "jewellers", "tiffany", "kay jewelers", "zales", "pandora"]
        case .furniture:   ["furniture", "ikea", "ashley furniture", "west elm", "crate & barrel", "crate and barrel", "pottery barn", "la-z-boy", "mattress"]
        case .toys:        ["toy store", "toys r us", "build-a-bear", "lego store"]
        case .sportingGoods: ["sporting goods", "dick's", "rei", "academy sports", "sports authority", "big 5", "bass pro", "cabela"]
        case .music:       ["guitar center", "sam ash", "music store", "musical instruments", "sweetwater"]
        case .craft:       ["michaels", "jo-ann", "joann", "hobby lobby", "craft store", "fabric store"]
        case .beauty:      ["sephora", "ulta", "sally beauty", "cosmetics", "beauty supply"]
        case .shoes:       ["foot locker", "footlocker", "famous footwear", "dsw", "payless", "shoe store"]
        case .homeGoods:   ["homegoods", "home goods", "bed bath", "container store", "pier 1", "pier one", "home decor"]
        case .autoParts:   ["autozone", "o'reilly auto", "advance auto", "napa auto", "pep boys", "auto parts", "car parts"]
        default: []
        }
    }

    /// The POI categories we ask MapKit to return. Deliberately excludes
    /// service-type POIs (EV chargers, mailboxes, salons, vets) that aren't
    /// shopping-errand destinations.
    static let poiSearchCategories: [MKPointOfInterestCategory] = [
        .foodMarket, .pharmacy, .bank, .atm, .store, .gasStation, .postOffice, .bakery
    ]

    /// A confident category from a *specific* POI bucket. Returns nil for the
    /// broad `.store` bucket and for `.foodMarket` (both need name/LLM analysis —
    /// `.foodMarket` because Apple Maps tags wholesalers as food markets too).
    static func directCategory(for poi: MKPointOfInterestCategory?) -> StoreCategory? {
        switch poi {
        case .pharmacy:           .pharmacy
        case .bank, .atm:         .bank
        case .gasStation:         .gasStation
        case .postOffice:         .postOffice
        case .bakery:             .bakery
        default:                  nil
        }
    }

    /// Specialty categories whose name hints appear in the store name.
    static func nameHintCategories(for name: String) -> [StoreCategory] {
        let lowered = name.lowercased()
        var matches: Set<StoreCategory> = []
        for category in StoreCategory.selectable where !category.nameHints.isEmpty {
            if category.nameHints.contains(where: { lowered.contains($0) }) {
                matches.insert(category)
            }
        }
        return Array(matches)
    }
}
