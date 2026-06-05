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
    case uncategorized

    var id: String { rawValue }

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
        case .uncategorized: .gray
        }
    }
}
