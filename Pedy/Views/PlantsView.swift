import SwiftUI
import SwiftData

struct PlantsView: View {
    @Query(sort: \Plant.name) private var plants: [Plant]
    @State private var showingAdd = false

    var body: some View {
        Group {
            if plants.isEmpty {
                ContentUnavailableView(
                    "Twoje rośliny",
                    systemImage: "leaf",
                    description: Text("Dodaj roślinę, by zapisywać kontrole i historię pielęgnacji.")
                )
            } else {
                List(plants) { plant in
                    NavigationLink {
                        PlantDetailView(plant: plant)
                    } label: {
                        HStack(spacing: 12) {
                            PlantThumbnail(species: PlantSpecies.match(plant.speciesName))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(plant.name).font(.headline)
                                Text([plant.speciesName, plant.room].filter { !$0.isEmpty }.joined(separator: " · "))
                                    .font(.subheadline).foregroundStyle(.secondary)
                                Text("Kontrola: \(plant.nextCheckDate.formatted(date: .abbreviated, time: .omitted))")
                                    .font(.caption).foregroundStyle(Palette.terracotta)
                            }
                        }
                        .padding(.vertical, 5)
                    }
                }
                .scrollContentBackground(.hidden)
            }
        }
        .background(Palette.background.ignoresSafeArea())
        .navigationTitle("Moje rośliny")
        .toolbar {
            Button("Dodaj", systemImage: "plus") { showingAdd = true }
                .accessibilityLabel("Dodaj roślinę")
        }
        .sheet(isPresented: $showingAdd) { AddPlantView() }
    }
}

struct AddPlantView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var speciesName = ""
    @State private var room = ""
    @State private var nextCheckDate = Date()
    @State private var checkIntervalDays = 3
    @State private var saveError: String?

    private var validName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    init(species: PlantSpecies? = nil) {
        _speciesName = State(initialValue: species?.commonName ?? "")
        _checkIntervalDays = State(initialValue: species?.intervalDays ?? 3)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Roślina") {
                    TextField("Własna nazwa", text: $name)
                    Picker("Gatunek", selection: $speciesName) {
                        Text("Wybierz później").tag("")
                        ForEach(PlantSpecies.catalog) { item in
                            Text(item.commonName).tag(item.commonName)
                        }
                    }
                    TextField("Pomieszczenie", text: $room)
                }
                Section("Kontrola podłoża") {
                    DatePicker("Pierwsza kontrola", selection: $nextCheckDate, displayedComponents: .date)
                    Stepper("Odstęp kontroli: \(checkIntervalDays) dni", value: $checkIntervalDays, in: 1...30)
                    Text("To odstęp przypominania o sprawdzeniu, nie nakaz podlewania. Później dopasujemy go do wymagań gatunku i Twoich obserwacji.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Dodaj roślinę")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Zapisz") {
                        let plant = Plant(
                            name: validName,
                            speciesName: speciesName.trimmingCharacters(in: .whitespacesAndNewlines),
                            room: room.trimmingCharacters(in: .whitespacesAndNewlines),
                            nextCheckDate: nextCheckDate,
                            checkIntervalDays: checkIntervalDays
                        )
                        context.insert(plant)
                        do {
                            try context.save()
                            dismiss()
                        } catch {
                            context.rollback()
                            saveError = "Nie udało się zapisać rośliny. Spróbuj ponownie."
                        }
                    }
                    .disabled(validName.isEmpty)
                }
            }
        }
        .tint(Palette.terracotta)
        .alert("Błąd zapisu", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }
}

struct PlantDetailView: View {
    let plant: Plant
    @Query(sort: \CareEvent.occurredAt, order: .reverse) private var allEvents: [CareEvent]

    private var events: [CareEvent] { allEvents.filter { $0.plantID == plant.id } }

    var body: some View {
        List {
            Section {
                Text(plant.speciesName.isEmpty ? "Gatunek nieustalony" : plant.speciesName)
                    .foregroundStyle(.secondary)
                if !plant.room.isEmpty { Label(plant.room, systemImage: "house") }
                LabeledContent("Następna kontrola", value: plant.nextCheckDate.formatted(date: .abbreviated, time: .omitted))
                if let date = plant.lastWateredAt {
                    LabeledContent("Ostatnie podlewanie", value: date.formatted(date: .abbreviated, time: .omitted))
                }
                NavigationLink("Sprawdź podłoże") { CareDetailView(plant: plant) }
            }
            Section("Historia") {
                if events.isEmpty {
                    Text("Brak obserwacji").foregroundStyle(.secondary)
                }
                ForEach(events) { event in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(CareEvent.Kind(rawValue: event.kind)?.title ?? "Wpis")
                        Text(event.occurredAt, format: .dateTime.day().month().year().hour().minute())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Palette.background)
        .navigationTitle(plant.name)
    }
}
