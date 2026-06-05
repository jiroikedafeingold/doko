import SwiftUI
import SwiftData

struct WatchStoreListView: View {
    let title: String
    let categories: [StoreCategory]

    @Query private var allItems: [ShoppingItem]

    private var filtered: [ShoppingItem] {
        let categorySet = Set(categories)
        return allItems.filter { item in
            !item.isPurchased && !Set(item.categories).intersection(categorySet).isEmpty
        }
    }

    var body: some View {
        Group {
            if filtered.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.seal")
                        .font(.largeTitle)
                        .foregroundStyle(.green)
                    Text("Nothing to grab")
                        .font(.headline)
                    Text("Nothing on your list belongs in this kind of store.")
                        .font(.caption2)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .padding()
            } else {
                List {
                    ForEach(filtered) { item in
                        WatchItemRow(item: item)
                    }
                }
            }
        }
        .navigationTitle(title)
    }
}

private struct WatchItemRow: View {
    @Bindable var item: ShoppingItem

    var body: some View {
        Button {
            item.togglePurchased()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(item.isPurchased ? .green : .secondary)
                Text(item.name)
                    .strikethrough(item.isPurchased)
                    .foregroundStyle(item.isPurchased ? .secondary : .primary)
                    .lineLimit(2)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
