import SwiftUI

struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var page: Int = 0

    private let pages: [OnboardingPageData] = [
        OnboardingPageData(
            systemImage: "location.magnifyingglass",
            tint: .accentColor,
            title: "Meet doko",
            kana: "どこ",
            body: "Doko means \"what's here?\" in Japanese. Jot down whatever you need, and the app helps you remember to grab it at the store you're standing next to.",
            example: nil
        ),
        OnboardingPageData(
            systemImage: "text.badge.plus",
            tint: .accentColor,
            title: "Capture in a flash",
            kana: "書く",
            body: "Type what you need and hit return. Separate multiple items with commas — doko splits them and figures out where you'll find each one.",
            example: "milk, eggs, ibuprofen, drill bit, batteries"
        ),
        OnboardingPageData(
            systemImage: "location.viewfinder",
            tint: .accentColor,
            title: "What's Here?",
            kana: "どこ",
            body: "When you walk past a store, tap What's Here? doko reads the kind of place you're at — grocery, pharmacy, hardware, bank — and shows only the items you can grab there.",
            example: nil
        ),
        OnboardingPageData(
            systemImage: "applewatch",
            tint: .accentColor,
            title: "Quick on the wrist",
            kana: "手首で",
            body: "On your Apple Watch, raise your wrist, tap What's Nearby?, and check items off as you go. Everything syncs across your iPhone, iPad, Mac, and Watch.",
            example: nil
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.offset) { index, data in
                    OnboardingPage(data: data)
                        .tag(index)
                        .padding(.horizontal, 24)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack(spacing: 10) {
                Button {
                    if page < pages.count - 1 {
                        withAnimation { page += 1 }
                    } else {
                        finish()
                    }
                } label: {
                    Text(page < pages.count - 1 ? "Next" : "Get Started")
                        .fontWeight(.semibold)
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

                if page < pages.count - 1 {
                    Button("Skip") { finish() }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 30)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }

    private func finish() {
        UserDefaults.standard.set(true, forKey: "kokoaru.hasSeenOnboarding.v1")
        isPresented = false
    }
}

private struct OnboardingPageData {
    let systemImage: String
    let tint: Color
    let title: String
    let kana: String?
    let body: String
    let example: String?
}

private struct OnboardingPage: View {
    let data: OnboardingPageData

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 20)

            ZStack {
                Circle()
                    .fill(data.tint.opacity(0.15))
                    .frame(width: 160, height: 160)
                Image(systemName: data.systemImage)
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(data.tint)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(spacing: 14) {
                VStack(spacing: 4) {
                    Text(data.title)
                        .font(.title.weight(.bold))
                        .multilineTextAlignment(.center)
                    if let kana = data.kana {
                        Text(kana)
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .tracking(2)
                    }
                }
                Text(data.body)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
            }

            if let example = data.example {
                VStack(alignment: .leading, spacing: 6) {
                    Text("TRY")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.tertiary)
                    Text(example)
                        .font(.callout.monospaced())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color(.secondarySystemBackground))
                        )
                }
            }

            Spacer()
        }
    }
}

#Preview {
    OnboardingView(isPresented: .constant(true))
}
