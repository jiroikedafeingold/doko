import SwiftUI
import SwiftData
import CoreLocation

struct ContentView: View {
    @Query private var allItems: [ShoppingItem]
    @State private var detector = NearbyStoreDetector()
    @State private var showStoreList: Bool = false
    @State private var manualCategory: StoreCategory?

    private var forcedCoordinate: CLLocationCoordinate2D? {
        allItems.contains {
            $0.name.localizedCaseInsensitiveCompare(NearbyStoreDetector.overrideItemName) == .orderedSame
        } ? NearbyStoreDetector.overrideCoordinate : nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    Button {
                        Task {
                            await detector.detect(forcedCoordinate: forcedCoordinate)
                            showStoreList = !detector.nearbyStores.isEmpty
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .font(.title2)
                            Text("What's Nearby?")
                                .font(.headline)
                            if detector.isSearching {
                                ProgressView()
                                    .controlSize(.small)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(detector.isSearching)

                    if let error = detector.lastError {
                        Text(error)
                            .font(.caption2)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                    }

                    Divider()

                    Text("Or pick a store type")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(StoreCategory.allCases.filter { $0 != .uncategorized }) { category in
                        NavigationLink {
                            WatchStoreListView(
                                title: category.displayName,
                                categories: [category]
                            )
                        } label: {
                            HStack {
                                Image(systemName: category.symbolName)
                                    .foregroundStyle(category.tintColor)
                                Text(category.displayName)
                                Spacer()
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("Doko?")
            .navigationDestination(isPresented: $showStoreList) {
                if let store = detector.nearbyStores.first {
                    WatchStoreListView(
                        title: store.name,
                        categories: store.categories
                    )
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ShoppingItem.self, inMemory: true)
}
