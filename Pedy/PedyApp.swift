import SwiftUI
import SwiftData

@main
struct PedyApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.light)
        }
        .modelContainer(for: [Plant.self, CareEvent.self])
    }
}
