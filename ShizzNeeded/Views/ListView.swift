import SwiftUI
import SwiftData

struct ListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\ShoppingItem.createdAt, order: .reverse)])
    private var items: [ShoppingItem]

    @State private var entryText: String = ""
    @State private var showStoreSheet: Bool = false
    @State private var detector = NearbyStoreDetector()
    @State private var showOnboarding: Bool = !UserDefaults.standard.bool(forKey: Self.onboardingFlag)
    @FocusState private var entryFocused: Bool

    private static let onboardingFlag = "kokoaru.hasSeenOnboarding.v1"
    private static let purgeWindow: TimeInterval = 2 * 24 * 60 * 60 // 2 days

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                entrySection
                listSection
            }
            .background(Color(.systemGroupedBackground))
            .simultaneousGesture(
                TapGesture().onEnded {
                    if entryFocused { entryFocused = false }
                }
            )
            .navigationTitle("Doko?")
            .navigationSubtitle("どこ")
            .sheet(isPresented: $showStoreSheet) {
                StoreView(detector: detector)
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView(isPresented: $showOnboarding)
            }
            .task {
                purgeOldPurchased()
            }
        }
    }

    // MARK: - Sections

    private var entrySection: some View {
        VStack(spacing: 36) {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.tint)
                TextField("Add items (comma-separated)", text: $entryText)
                    .textFieldStyle(.plain)
                    .focused($entryFocused)
                    .submitLabel(.done)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onSubmit { commitEntry() }
                Button {
                    commitEntry()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.tint)
                }
                .disabled(entryText.isEmpty)
                .opacity(entryText.isEmpty ? 0.3 : 1)
                .animation(.easeInOut(duration: 0.15), value: entryText.isEmpty)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
            )

            Divider()

            Button {
                triggerStoreLookup()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "location.fill")
                        .font(.headline)
                    Text("What's Here?")
                        .fontWeight(.semibold)
                    if detector.isSearching {
                        ProgressView()
                            .controlSize(.small)
                            .tint(.white)
                    }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    LinearGradient(
                        colors: [.accentColor, .accentColor.opacity(0.78)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.accentColor.opacity(0.25), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)
            .disabled(detector.isSearching)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 16)
    }

    @ViewBuilder
    private var listSection: some View {
        if items.isEmpty {
            ContentUnavailableView {
                Label("Nothing on the list", systemImage: "cart")
            } description: {
                Text("Add items above. doko will guess what kind of store you'll find them at.")
            }
            .frame(maxHeight: .infinity)
        } else {
            List {
                let active = items.filter { !$0.isPurchased }
                let purchased = items.filter { $0.isPurchased }

                if !active.isEmpty {
                    Section {
                        ForEach(active) { item in
                            NavigationLink {
                                ItemDetailView(item: item)
                            } label: {
                                ItemRow(item: item)
                            }
                        }
                        .onDelete { offsets in
                            for offset in offsets {
                                modelContext.delete(active[offset])
                            }
                        }
                    } header: {
                        SectionHeader(text: "To Get", systemImage: "list.bullet")
                    }
                }

                if !purchased.isEmpty {
                    Section {
                        ForEach(purchased) { item in
                            NavigationLink {
                                ItemDetailView(item: item)
                            } label: {
                                ItemRow(item: item)
                            }
                        }
                        .onDelete { offsets in
                            for offset in offsets {
                                modelContext.delete(purchased[offset])
                            }
                        }
                    } header: {
                        SectionHeader(text: "Recently Purchased", systemImage: "clock.arrow.circlepath")
                    } footer: {
                        Text("Cleared automatically after two days.")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .scrollDismissesKeyboard(.immediately)
        }
    }

    // MARK: - Actions

    private func triggerStoreLookup() {
        Task {
            await detector.detect()
            showStoreSheet = true
        }
    }

    private func commitEntry() {
        let pieces = entryText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        guard !pieces.isEmpty else { return }

        for piece in pieces {
            let existing = items.first {
                !$0.isPurchased && $0.name.localizedCaseInsensitiveCompare(piece) == .orderedSame
            }
            guard existing == nil else { continue }

            let item = ShoppingItem(name: piece)
            modelContext.insert(item)

            Task { @MainActor in
                let categories = await Categorizer.shared.categories(for: piece)
                item.categories = categories
                item.needsCategorization = false
            }
        }
        entryText = ""
        entryFocused = true
    }

    private func purgeOldPurchased() {
        let cutoff = Date().addingTimeInterval(-Self.purgeWindow)
        let stale = items.filter { item in
            item.isPurchased && (item.purchasedAt ?? Date.distantPast) < cutoff
        }
        guard !stale.isEmpty else { return }
        for item in stale {
            modelContext.delete(item)
        }
        try? modelContext.save()
    }
}

// MARK: - Section header

private struct SectionHeader: View {
    let text: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
            Text(text)
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(.secondary)
        .textCase(nil)
    }
}

// MARK: - Row

private struct ItemRow: View {
    @Bindable var item: ShoppingItem

    var body: some View {
        HStack(spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    item.togglePurchased()
                }
            } label: {
                Image(systemName: item.isPurchased ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(item.isPurchased ? .green : .secondary)
                    .symbolEffect(.bounce, value: item.isPurchased)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 5) {
                Text(item.name)
                    .strikethrough(item.isPurchased)
                    .foregroundStyle(item.isPurchased ? .secondary : .primary)

                if item.needsCategorization {
                    Text("Categorizing…")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else if !item.categories.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(item.categories) { category in
                            CategoryChip(category: category)
                        }
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }
}

private struct CategoryChip: View {
    let category: StoreCategory

    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: category.symbolName)
                .font(.caption2)
            Text(category.displayName)
                .font(.caption2.weight(.medium))
                .lineLimit(1)
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(category.tintColor.opacity(0.16))
        )
        .overlay(
            Capsule()
                .strokeBorder(category.tintColor.opacity(0.25), lineWidth: 0.5)
        )
        .foregroundStyle(category.tintColor)
    }
}

#Preview {
    ListView()
        .modelContainer(for: ShoppingItem.self, inMemory: true)
}
