import Foundation
import SwiftData

@Model
final class ShoppingItem {
    var name: String = ""
    var notes: String = ""
    var isPurchased: Bool = false
    var purchasedAt: Date?
    var createdAt: Date = Date()
    var lastModified: Date = Date()
    /// Raw `StoreCategory.rawValue` tokens. Stored as `[String]` because
    /// CloudKit handles primitive arrays natively and round-trips them reliably.
    var categoryTokens: [String] = []
    /// True until the categorizer has finished resolving a result.
    var needsCategorization: Bool = true

    init(name: String,
         notes: String = "",
         categories: [StoreCategory] = [],
         needsCategorization: Bool = true) {
        self.name = name
        self.notes = notes
        self.categoryTokens = categories.map(\.rawValue)
        self.needsCategorization = needsCategorization
        self.createdAt = Date()
        self.lastModified = Date()
    }

    var categories: [StoreCategory] {
        get { categoryTokens.compactMap { StoreCategory(rawValue: $0) } }
        set {
            categoryTokens = newValue.map(\.rawValue)
            lastModified = Date()
        }
    }

    func togglePurchased() {
        isPurchased.toggle()
        purchasedAt = isPurchased ? Date() : nil
        lastModified = Date()
    }
}
