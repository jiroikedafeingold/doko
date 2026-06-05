import SwiftUI
import SwiftData

struct ContentView: View {
    var body: some View {
        ListView()
    }
}

#Preview {
    ContentView()
        .modelContainer(for: ShoppingItem.self, inMemory: true)
}
