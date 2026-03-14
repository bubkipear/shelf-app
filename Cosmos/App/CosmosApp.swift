import SwiftUI

@main
struct CosmosApp: App {
    @StateObject private var store = ExperimentStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .preferredColorScheme(.dark)
        }
    }
}
