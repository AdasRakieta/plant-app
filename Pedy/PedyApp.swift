import SwiftUI
import SwiftData

@main
struct PedyApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Plant.self, CareEvent.self])
    }
}
