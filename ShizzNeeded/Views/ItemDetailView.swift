import SwiftUI
import SwiftData

struct ItemDetailView: View {
    @Bindable var item: ShoppingItem

    var body: some View {
        Form {
            Section("Item") {
                TextField("Name", text: $item.name)
                TextField("Notes", text: $item.notes, axis: .vertical)
                    .lineLimit(2...5)
            }

            Section {
                Toggle("Purchased", isOn: Binding(
                    get: { item.isPurchased },
                    set: { newValue in
                        if newValue != item.isPurchased {
                            item.togglePurchased()
                        }
                    }
                ))
            }

            Section("Categories") {
                ForEach(StoreCategory.allCases.filter { $0 != .uncategorized }) { category in
                    Toggle(isOn: binding(for: category)) {
                        Label(category.displayName, systemImage: category.symbolName)
                            .foregroundStyle(category.tintColor)
                    }
                }
            }
        }
        .navigationTitle(item.name.isEmpty ? "Item" : item.name)
    }

    private func binding(for category: StoreCategory) -> Binding<Bool> {
        Binding(
            get: { item.categoryTokens.contains(category.rawValue) },
            set: { newValue in
                var tokens = Set(item.categoryTokens.filter { $0 != StoreCategory.uncategorized.rawValue })
                if newValue {
                    tokens.insert(category.rawValue)
                } else {
                    tokens.remove(category.rawValue)
                }
                item.categoryTokens = Array(tokens)
                item.needsCategorization = false
                item.lastModified = Date()
            }
        )
    }
}
