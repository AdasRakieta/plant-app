import SwiftUI
import SwiftData

struct TodayView: View {
    @Query(sort: \Plant.name) private var plants: [Plant]
    @State private var showingAdd = false
    @State private var planRevision = 0

    private var sessions: [CareSession] {
        _ = planRevision
        return CarePlanner.sessions(for: CarePlanner.tasks(for: plants))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Twój rytm")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Palette.forest)
                    Text("Mniej przypomnień. Więcej spokoju.")
                        .foregroundStyle(.secondary)
                }

                if plants.isEmpty {
                    ContentUnavailableView(
                        "Dodaj pierwszą roślinę",
                        systemImage: "leaf",
                        description: Text("Zapisz roślinę i datę najbliższej kontroli, aby zobaczyć plan.")
                    )
                    Button("Dodaj roślinę") { showingAdd = true }
                        .buttonStyle(PrimaryButtonStyle())
                } else if let first = sessions.first {
                    NavigationLink {
                        SessionView(session: first, plants: plants) { planRevision += 1 }
                    } label: {
                        ZStack(alignment: .leading) {
                            Image("PlantHero").resizable().scaledToFill().frame(height: 250).clipped()
                            LinearGradient(colors: [Palette.terracotta.opacity(0.96), Palette.terracotta.opacity(0.56)], startPoint: .leading, endPoint: .trailing)
                            VStack(alignment: .leading, spacing: 12) {
                                Text("NAJBLIŻSZA SESJA").font(.caption.weight(.semibold))
                                Text(first.date, format: .dateTime.weekday(.wide).day().month(.wide)).font(.title2.bold())
                                Text("\(first.tasks.count) \(first.tasks.count == 1 ? "roślina" : first.tasks.count < 5 ? "rośliny" : "roślin") · wspólna kontrola")
                                Label("Zobacz plan", systemImage: "arrow.right").font(.headline).padding(.top, 12)
                            }.foregroundStyle(.white).padding(24)
                        }.clipShape(RoundedRectangle(cornerRadius: 26))
                    }
                    .buttonStyle(.plain)

                    Text("DO SPRAWDZENIA")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.secondary)

                    ForEach(first.tasks) { task in
                        if let plant = plants.first(where: { $0.id == task.plantID }) {
                            NavigationLink {
                                CareDetailView(plant: plant) { planRevision += 1 }
                            } label: {
                                HStack {
                                    PlantThumbnail(species: PlantSpecies.match(plant.speciesName))
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(plant.name).font(.headline)
                                        Text("Sprawdź podłoże").font(.subheadline).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                                }
                                .foregroundStyle(Palette.forest)
                                .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            Divider()
                        }
                    }

                    Text("Podlej dopiero po sprawdzeniu podłoża. Termin jest przypomnieniem o kontroli.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(20)
        }
        .background(Palette.background.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAdd) { AddPlantView() }
    }
}

struct SessionView: View {
    let session: CareSession
    let plants: [Plant]
    let didSave: (() -> Void)?

    var body: some View {
        List {
            Section {
                Text(session.date, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.title2.bold())
                Text("Sprawdź każdą roślinę i zapisz wynik. Podlewanie potwierdzisz osobno.")
                    .foregroundStyle(.secondary)
            }
            Section("Kolejność kontroli") {
                ForEach(session.tasks) { task in
                    if let plant = plants.first(where: { $0.id == task.plantID }) {
                        NavigationLink {
                            CareDetailView(plant: plant, didSave: didSave)
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(plant.name).font(.headline)
                                Text("Sprawdź podłoże").font(.subheadline).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.background)
        .navigationTitle("Plan pielęgnacji")
    }
}
