import Foundation
#if canImport(FoundationModels)
import FoundationModels

/// The constrained set of category tokens the on-device model is allowed to
/// return. Raw values match `StoreCategory.rawValue` so they map back directly.
/// `uncategorized` is intentionally excluded — the model should never pick it.
@Generable
enum CategoryToken: String, Codable {
    case grocery, pharmacy, hardware, bank, department,
         electronics, officeSupply, pet, garden, liquor,
         bakery, clothing, bookstore, gasStation, postOffice,
         jewelry, furniture, toys, sportingGoods, music,
         craft, beauty, shoes, homeGoods, autoParts

    var storeCategory: StoreCategory? {
        StoreCategory(rawValue: rawValue)
    }
}
#endif
