import SwiftUI
import SwiftData

@main
struct Shizzneeded_Watch_AppApp: App {
    let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([ShoppingItem.self])
            let config = ModelConfiguration(
                schema: schema,
                cloudKitDatabase: .private("iCloud.com.jirofeingold.doko")
            )
            modelContainer = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
