import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack {
                TodayView()
            }
            .tabItem { Label("Dzisiaj", systemImage: "house.fill") }

            NavigationStack {
                PlantsView()
            }
            .tabItem { Label("Rośliny", systemImage: "leaf") }

            NavigationStack {
                AtlasView()
            }
            .tabItem { Label("Atlas", systemImage: "book") }

            NavigationStack {
                DiagnosisView()
            }
            .tabItem { Label("Diagnoza", systemImage: "cross.case") }
        }
        .tint(Palette.terracotta)
    }
}
