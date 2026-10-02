import SwiftUI

struct AtlasView: View {
    @State private var query = ""
    @State private var petSafeOnly = false
    @State private var selected: PlantSpecies?

    private var species: [PlantSpecies] {
        PlantSpecies.catalog.filter { item in
            let text = "\(item.commonName) \(item.latinName) \(item.light)".folding(options: .diacriticInsensitive, locale: .current)
            return (query.isEmpty || text.localizedCaseInsensitiveContains(query)) && (!petSafeOnly || item.petSafety == "Bezpieczna dla zwierząt")
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Atlas roślin").font(.largeTitle.bold()).foregroundStyle(Palette.forest)
                Text("Wybierz gatunek, poznaj jego potrzeby i dodaj go do swojej kolekcji.")
                    .foregroundStyle(.secondary)
                Toggle("Tylko bezpieczne dla zwierząt", isOn: $petSafeOnly)
                    .tint(Palette.terracotta)
                    .padding(14)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16))
                LazyVStack(spacing: 12) {
                    ForEach(species) { item in
                        Button { selected = item } label: {
                            HStack(spacing: 14) {
                                PlantThumbnail()
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.commonName).font(.headline)
                                    Text(item.latinName).font(.subheadline).italic().foregroundStyle(.secondary)
                                    Text(item.light).font(.caption).foregroundStyle(Palette.terracotta)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                            }
                            .padding(12)
                            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 18))
                        }.buttonStyle(.plain)
                    }
                }
            }.padding(20)
        }
        .background(Palette.background.ignoresSafeArea())
        .searchable(text: $query, prompt: "Szukaj gatunku")
        .sheet(item: $selected) { SpeciesDetailView(species: $0) }
    }
}

struct SpeciesDetailView: View {
    let species: PlantSpecies
    @Environment(\.dismiss) private var dismiss
    @State private var adding = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Image("plant-hero").resizable().scaledToFill().frame(height: 220).clipped().clipShape(RoundedRectangle(cornerRadius: 24))
                    Text(species.commonName).font(.largeTitle.bold())
                    Text(species.latinName).italic().foregroundStyle(.secondary)
                    Text(species.summary).font(.body)
                    Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 16) {
                        GridRow { Text("Światło").foregroundStyle(.secondary); Text(species.light) }
                        GridRow { Text("Podlewanie").foregroundStyle(.secondary); Text(species.watering) }
                        GridRow { Text("Zwierzęta").foregroundStyle(.secondary); Text(species.petSafety) }
                    }.padding(18).background(Palette.surface, in: RoundedRectangle(cornerRadius: 18))
                    Button("Dodaj do moich roślin") { adding = true }.buttonStyle(PrimaryButtonStyle())
                }.padding(20)
            }.background(Palette.background.ignoresSafeArea())
            .navigationTitle("Wymagania").navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Gotowe") { dismiss() } }
            .sheet(isPresented: $adding) { AddPlantView(species: species) }
        }
    }
}

struct PlantThumbnail: View {
    var body: some View {
        Image("plant-hero").resizable().scaledToFill().frame(width: 64, height: 64).clipped().clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
