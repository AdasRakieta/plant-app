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
                FutureFeatureView(
                    title: "Atlas roślin",
                    description: "Wyszukiwanie gatunków, wymagań i dobór roślin do Twojego domu powstaje w kolejnym etapie.",
                    symbol: "books.vertical"
                )
            }
            .tabItem { Label("Atlas", systemImage: "book") }

            NavigationStack {
                FutureFeatureView(
                    title: "Diagnoza",
                    description: "Analiza zdjęć i obserwacja objawów zostaną dodane po opracowaniu bazy roślin i zasad prywatności.",
                    symbol: "camera.macro"
                )
            }
            .tabItem { Label("Diagnoza", systemImage: "cross.case") }
        }
        .tint(Palette.terracotta)
    }
}

private struct FutureFeatureView: View {
    let title: String
    let description: String
    let symbol: String

    var body: some View {
        ContentUnavailableView(title, systemImage: symbol, description: Text(description))
            .navigationTitle(title)
            .background(Palette.background.ignoresSafeArea())
    }
}
