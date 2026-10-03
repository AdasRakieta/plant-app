import SwiftUI
import SwiftData
import PhotosUI
import UIKit

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
    @State private var photoItem: PhotosPickerItem?
    @State private var photoImage: UIImage?
    @State private var candidates: [AIPlantCandidate] = []
    @State private var isRecognising = false
    @State private var recognitionError: String?
    @State private var customSpeciesName = ""
    @State private var customRequirements = ""

    private var validName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    init(species: PlantSpecies? = nil, customSpeciesName: String = "", customRequirements: String = "") {
        _speciesName = State(initialValue: species?.commonName ?? "")
        _checkIntervalDays = State(initialValue: species?.intervalDays ?? 3)
        _customSpeciesName = State(initialValue: customSpeciesName)
        _customRequirements = State(initialValue: customRequirements)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Roślina") {
                    TextField("Własna nazwa", text: $name)
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label(photoImage == nil ? "Wybierz zdjęcie do rozpoznania" : "Zmień zdjęcie", systemImage: "camera.viewfinder")
                    }
                    if photoImage != nil {
                        Button { Task { await recognisePlant() } } label: {
                            Label(isRecognising ? "Rozpoznaję lokalnie…" : "Rozpoznaj gatunek lokalnie", systemImage: "sparkles")
                        }.disabled(isRecognising)
                    }
                    if let recognitionError { Text(recognitionError).font(.footnote).foregroundStyle(Palette.terracotta) }
                    if !candidates.isEmpty {
                        Text("Potwierdź gatunek — AI nie zapisuje go samodzielnie.").font(.footnote).foregroundStyle(.secondary)
                        ForEach(candidates) { candidate in
                            Button {
                                speciesName = PlantSpecies.catalog.first(where: { $0.id == candidate.speciesID })?.commonName ?? candidate.commonName
                                if name.isEmpty { name = speciesName }
                                if let species = PlantSpecies.match(speciesName) { checkIntervalDays = species.intervalDays }
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(candidate.commonName)
                                        if let latin = candidate.latinName { Text(latin).font(.caption).italic() }
                                    }
                                    Spacer()
                                    Text("\(Int(candidate.confidence * 100))%")
                                }
                            }.foregroundStyle(Palette.forest)
                        }
                    }
                    Picker("Gatunek", selection: $speciesName) {
                        Text("Wybierz później").tag("")
                        ForEach(PlantSpecies.catalog) { item in
                            Text(item.commonName).tag(item.commonName)
                        }
                    }
                    TextField("Gatunek lub odmiana spoza atlasu", text: $customSpeciesName)
                    if !customSpeciesName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Własne wymagania").font(.subheadline.weight(.semibold))
                            TextEditor(text: $customRequirements)
                                .frame(minHeight: 90)
                            Text("Np. światło, podłoże, podlewanie, nawożenie i wielkość doniczki. Te dane zostają przy roślinie oraz są przekazywane do lokalnej diagnozy.")
                                .font(.footnote).foregroundStyle(.secondary)
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
                        let requestedSpecies = customSpeciesName.trimmingCharacters(in: .whitespacesAndNewlines)
                        let plant = Plant(
                            name: validName,
                            speciesName: requestedSpecies.isEmpty ? speciesName.trimmingCharacters(in: .whitespacesAndNewlines) : requestedSpecies,
                            room: room.trimmingCharacters(in: .whitespacesAndNewlines),
                            nextCheckDate: nextCheckDate,
                            checkIntervalDays: checkIntervalDays,
                            customRequirements: customRequirements.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : customRequirements.trimmingCharacters(in: .whitespacesAndNewlines)
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
        .onChange(of: photoItem) { _, item in Task { await loadPhoto(item) } }
        .alert("Błąd zapisu", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
    }

    @MainActor private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let data = try? await item?.loadTransferable(type: Data.self), let image = UIImage(data: data) else { return }
        photoImage = image
        candidates = []
        recognitionError = nil
    }

    private func recognisePlant() async {
        guard let photoImage else { return }
        await MainActor.run { isRecognising = true; recognitionError = nil; candidates = [] }
        do {
            let identification = try await LocalPlantAIClient.shared.identify(image: photoImage)
            await MainActor.run {
                candidates = identification.candidates.filter { candidate in PlantSpecies.catalog.contains(where: { $0.id == candidate.speciesID }) }
                if candidates.isEmpty { recognitionError = identification.uncertainty }
            }
        } catch {
            await MainActor.run { recognitionError = error.localizedDescription }
        }
        await MainActor.run { isRecognising = false }
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
                NavigationLink("Zdiagnozuj tę roślinę") { DiagnosisView(speciesName: plant.speciesName, requirements: plant.customRequirements ?? "") }
                if let requirements = plant.customRequirements, !requirements.isEmpty {
                    LabeledContent("Własne wymagania") { Text(requirements).multilineTextAlignment(.trailing) }
                }
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
