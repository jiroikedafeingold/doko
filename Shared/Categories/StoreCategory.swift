import Foundation
import SwiftUI

enum StoreCategory: String, CaseIterable, Codable, Hashable, Identifiable {
    case grocery
    case pharmacy
    case hardware
    case bank
    case department
    case electronics
    case officeSupply
    case pet
    case garden
    case liquor
    case bakery
    case clothing
    case bookstore
    case gasStation
    case postOffice
    case jewelry
    case furniture
    case toys
    case sportingGoods
    case music
    case craft
    case beauty
    case shoes
    case homeGoods
    case autoParts
    case uncategorized

    var id: String { rawValue }

    /// Every "real" category — excludes the `uncategorized` sentinel. Useful for
    /// pickers and for the LLM token set.
    static var selectable: [StoreCategory] {
        allCases.filter { $0 != .uncategorized }
    }

    var displayName: String {
        switch self {
        case .grocery:       "Grocery"
        case .pharmacy:      "Pharmacy"
        case .hardware:      "Hardware"
        case .bank:          "Bank"
        case .department:    "Department Store"
        case .electronics:   "Electronics"
        case .officeSupply:  "Office Supply"
        case .pet:           "Pet Store"
        case .garden:        "Garden Center"
        case .liquor:        "Liquor Store"
        case .bakery:        "Bakery"
        case .clothing:      "Clothing"
        case .bookstore:     "Bookstore"
        case .gasStation:    "Gas Station"
        case .postOffice:    "Post Office"
        case .jewelry:       "Jewelry"
        case .furniture:     "Furniture"
        case .toys:          "Toy Store"
        case .sportingGoods: "Sporting Goods"
        case .music:         "Music Store"
        case .craft:         "Craft Store"
        case .beauty:        "Beauty"
        case .shoes:         "Shoe Store"
        case .homeGoods:     "Home Goods"
        case .autoParts:     "Auto Parts"
        case .uncategorized: "Uncategorized"
        }
    }

    var symbolName: String {
        switch self {
        case .grocery:       "cart"
        case .pharmacy:      "cross.case"
        case .hardware:      "hammer"
        case .bank:          "banknote"
        case .department:    "bag"
        case .electronics:   "bolt.horizontal"
        case .officeSupply:  "paperclip"
        case .pet:           "pawprint"
        case .garden:        "leaf"
        case .liquor:        "wineglass"
        case .bakery:        "birthday.cake"
        case .clothing:      "tshirt"
        case .bookstore:     "book"
        case .gasStation:    "fuelpump"
        case .postOffice:    "envelope"
        case .jewelry:       "diamond"
        case .furniture:     "sofa"
        case .toys:          "teddybear"
        case .sportingGoods: "sportscourt"
        case .music:         "guitars"
        case .craft:         "paintpalette"
        case .beauty:        "sparkles"
        case .shoes:         "shoe"
        case .homeGoods:     "house"
        case .autoParts:     "car"
        case .uncategorized: "questionmark.circle"
        }
    }

    var tintColor: Color {
        switch self {
        case .grocery:       .green
        case .pharmacy:      .red
        case .hardware:      .orange
        case .bank:          .indigo
        case .department:    .pink
        case .electronics:   .blue
        case .officeSupply:  .gray
        case .pet:           .brown
        case .garden:        .mint
        case .liquor:        .purple
        case .bakery:        .yellow
        case .clothing:      .cyan
        case .bookstore:     .teal
        case .gasStation:    .secondary
        case .postOffice:    .blue
        case .jewelry:       .indigo
        case .furniture:     .brown
        case .toys:          .red
        case .sportingGoods: .green
        case .music:         .purple
        case .craft:         .orange
        case .beauty:        .pink
        case .shoes:         .cyan
        case .homeGoods:     .teal
        case .autoParts:     .gray
        case .uncategorized: .gray
        }
    }
}
