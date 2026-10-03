import SwiftUI

struct AtlasView: View {
    @State private var query = ""
    @State private var petSafeOnly = false
    @State private var difficulty = "Wszystkie"
    @State private var light = "Wszystkie"
    @State private var selected: PlantSpecies?

    private var species: [PlantSpecies] {
        PlantSpecies.catalog.filter { item in
            let text = "\(item.commonName) \(item.latinName) \(item.light)".folding(options: .diacriticInsensitive, locale: .current)
            return (query.isEmpty || text.localizedCaseInsensitiveContains(query)) && (!petSafeOnly || item.petSafety == "Bezpieczna dla zwierząt") && (difficulty == "Wszystkie" || item.difficulty == difficulty) && (light == "Wszystkie" || item.light == light)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Atlas roślin").font(.largeTitle.bold()).foregroundStyle(Palette.forest)
                Text("Wybierz gatunek, poznaj jego potrzeby i dodaj go do swojej kolekcji.")
                    .foregroundStyle(.secondary)
                HStack(spacing: 10) {
                    Menu { Picker("Trudność", selection: $difficulty) { ForEach(["Wszystkie", "Łatwa", "Umiarkowana", "Wymagająca"], id: \.self) { Text($0).tag($0) } } } label: { filterLabel("Trudność", value: difficulty) }
                    Menu { Picker("Światło", selection: $light) { ForEach(["Wszystkie"] + Array(Set(PlantSpecies.catalog.map(\.light))).sorted(), id: \.self) { Text($0).tag($0) } } } label: { filterLabel("Światło", value: light) }
                }
                Toggle("Bezpieczne dla zwierząt", isOn: $petSafeOnly)
                    .tint(Palette.terracotta).font(.subheadline)
                LazyVStack(spacing: 12) {
                    ForEach(species) { item in
                        Button { selected = item } label: {
                            HStack(spacing: 14) {
                                PlantThumbnail(species: item)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.commonName).font(.headline)
                                    Text(item.latinName).font(.subheadline).italic().foregroundStyle(.secondary)
                                    HStack { Text(item.light); Spacer(); Text(item.difficulty) }.font(.caption).foregroundStyle(Palette.terracotta)
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

    private func filterLabel(_ title: String, value: String) -> some View {
        Label(value == "Wszystkie" ? title : value, systemImage: "line.3.horizontal.decrease.circle")
            .font(.subheadline.weight(.medium)).foregroundStyle(Palette.forest)
            .padding(.horizontal, 12).padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(Palette.surface, in: Capsule())
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
                    Image(species.imageName).resizable().scaledToFill().frame(height: 220).clipped().clipShape(RoundedRectangle(cornerRadius: 24))
                    Text(species.commonName).font(.largeTitle.bold())
                    Text(species.latinName).italic().foregroundStyle(.secondary)
                    Text(species.summary).font(.body)
                    Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 16) {
                        GridRow { Text("Światło").foregroundStyle(.secondary); Text(species.light) }
                        GridRow { Text("Podlewanie").foregroundStyle(.secondary); Text(species.watering) }
                        GridRow { Text("Trudność").foregroundStyle(.secondary); Text(species.difficulty) }
                        GridRow { Text("Nawożenie").foregroundStyle(.secondary); Text(species.fertilizer) }
                        GridRow { Text("Podłoże").foregroundStyle(.secondary); Text(species.soil) }
                        GridRow { Text("Doniczka").foregroundStyle(.secondary); Text(species.pot) }
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
    var species: PlantSpecies? = nil
    var body: some View {
        Image(species?.imageName ?? "PlantHero").resizable().scaledToFill().frame(width: 64, height: 64).clipped().clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
