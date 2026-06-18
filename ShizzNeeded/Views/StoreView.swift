import SwiftUI
import SwiftData

struct StoreView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var detector: NearbyStoreDetector

    @State private var selectedStore: NearbyStoreDetector.NearbyStore?
    @Query private var allItems: [ShoppingItem]

    var body: some View {
        NavigationStack {
            content
                .navigationTitle(navigationTitle)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { dismiss() }
                    }
                }
        }
    }

    private var navigationTitle: String {
        selectedStore?.name ?? "Nearby"
    }

    @ViewBuilder
    private var content: some View {
        if detector.isSearching {
            ProgressView("Looking around…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = detector.lastError {
            errorView(error)
        } else if detector.nearbyStores.isEmpty {
            ContentUnavailableView(
                "No stores nearby",
                systemImage: "location.slash",
                description: Text("I can't find any stores within a \(NearbyStoreDetector.searchRadiusFeet) foot radius.")
            )
        } else if let store = selectedStore {
            itemList(for: store)
        } else if detector.nearbyStores.count == 1 {
            itemList(for: detector.nearbyStores[0])
                .onAppear { selectedStore = detector.nearbyStores[0] }
        } else {
            storeChooser
        }
    }

    private var storeChooser: some View {
        List {
            Section("Pick a store") {
                ForEach(detector.nearbyStores) { store in
                    Button {
                        selectedStore = store
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(store.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(store.isGeneral
                                     ? "General store"
                                     : store.categories.map(\.displayName).joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func itemList(for store: NearbyStoreDetector.NearbyStore) -> some View {
        let categorySet = Set(store.categories)
        let filtered = allItems.filter { item in
            !item.isPurchased && !Set(item.categories).intersection(categorySet).isEmpty
        }

        return Group {
            if filtered.isEmpty {
                ContentUnavailableView(
                    "Nothing to grab here",
                    systemImage: "checkmark.seal",
                    description: Text(store.isGeneral
                        ? "Nothing on your list is left to pick up."
                        : "Nothing on your list is sold at \(store.categories.map(\.displayName).joined(separator: " / ")).")
                )
            } else {
                List {
                    Section {
                        ForEach(filtered) { item in
                            StoreItemRow(item: item)
                        }
                    } header: {
                        if store.isGeneral {
                            Label("Showing your whole list", systemImage: "list.bullet")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .textCase(nil)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 6) {
                                    ForEach(store.categories) { cat in
                                        Label(cat.displayName, systemImage: cat.symbolName)
                                            .font(.caption.weight(.semibold))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(cat.tintColor.opacity(0.18))
                                            .foregroundStyle(cat.tintColor)
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        ContentUnavailableView {
            Label("Couldn't find your location", systemImage: "location.slash.fill")
        } description: {
            Text(message)
        } actions: {
            Button("Try Again") {
                Task { await detector.detect() }
            }
        }
    }
}

private struct StoreItemRow: View {
    @Bindable var item: ShoppingItem

    var body: some View {
        HStack(spacing: 14) {
            Button {
                item.togglePurchased()
            } label: {
                Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                    .font(.title)
                    .foregroundStyle(item.isPurchased ? .green : .secondary)
            }
            .buttonStyle(.plain)

            Text(item.name)
                .font(.title3)
                .strikethrough(item.isPurchased)
                .foregroundStyle(item.isPurchased ? .secondary : .primary)

            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .swipeActions(edge: .trailing) {
            Button {
                item.togglePurchased()
            } label: {
                Label(item.isPurchased ? "Unpurchase" : "Purchased",
                      systemImage: item.isPurchased ? "arrow.uturn.backward" : "checkmark")
            }
            .tint(item.isPurchased ? .gray : .green)
        }
    }
}
