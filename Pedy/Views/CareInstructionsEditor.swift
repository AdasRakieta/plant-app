import SwiftUI
import SwiftData

struct CareInstructionsEditor: View {
    let speciesName: String
    @Binding var instructions: String
    @State private var generating = false
    @State private var suggestion: String?
    @State private var message: String?

    var body: some View {
        TextEditor(text: $instructions).frame(minHeight: 200)
            .accessibilityLabel("Instrukcje pielęgnacji — edytuj dowolny fragment")
        Text("Możesz zmienić cały opis: światło, podlewanie, podłoże, doniczkę, nawożenie i pozostałe wskazówki.").font(.footnote)
        Text("Dla gatunków z atlasu instrukcje są wczytywane lokalnie. Dla innych AI otrzyma tylko wpisaną nazwę przez Malinę, bez zdjęcia ani historii; wynik zostanie zapamiętany dla tego gatunku.").font(.footnote).foregroundStyle(.secondary)
        Button(generating ? "Przygotowuję instrukcje…" : "Wygeneruj instrukcje dla gatunku") {
            let requestedSpecies = speciesName.trimmingCharacters(in: .whitespacesAndNewlines)
            generating = true
            message = nil
            Task { @MainActor in
                defer { generating = false }
                do {
                    if let species = PlantSpecies.match(requestedSpecies) {
                        suggestion = species.editableInstructions
                        message = "Wczytano instrukcje z atlasu aplikacji — Gemini nie zostało użyte."
                        return
                    }
                    let result = try await LocalPlantAIClient.shared.careProfile(speciesName: requestedSpecies)
                    guard requestedSpecies == speciesName.trimmingCharacters(in: .whitespacesAndNewlines) else {
                        message = "Gatunek zmienił się podczas generowania. Uruchom ponownie dla nowego gatunku."
                        return
                    }
                    suggestion = result.requirements
                } catch { message = error.localizedDescription }
            }
        }.disabled(generating || speciesName.trimmingCharacters(in: .whitespacesAndNewlines).count < 2)
        .onChange(of: speciesName) { _, _ in suggestion = nil }
        if generating { ProgressView() }
        if let message { Text(message).font(.footnote) }
        if let suggestion {
            Text("Propozycja AI — sprawdź przed użyciem").font(.headline)
            Text(suggestion).textSelection(.enabled)
            Button("Zastąp instrukcje tą propozycją") {
                instructions = suggestion
                self.suggestion = nil
                message = "Propozycja przeniesiona do edytora. Możesz ją poprawić przed zapisaniem."
            }
            Button("Odrzuć propozycję", role: .cancel) { self.suggestion = nil }
        }
    }
}

struct EditPlantInstructionsView: View {
    let plant: Plant
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var speciesName: String
    @State private var room: String
    @State private var instructions: String
    @State private var error: String?

    init(plant: Plant) {
        self.plant = plant
        _name = State(initialValue: plant.name)
        _speciesName = State(initialValue: plant.speciesName)
        _room = State(initialValue: plant.room)
        _instructions = State(initialValue: plant.customRequirements ?? PlantSpecies.match(plant.speciesName)?.editableInstructions ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Roślina") {
                    TextField("Własna nazwa", text: $name)
                    TextField("Gatunek lub odmiana", text: $speciesName)
                    TextField("Pomieszczenie", text: $room)
                }
                Section("Instrukcje pielęgnacji") {
                    CareInstructionsEditor(speciesName: speciesName, instructions: $instructions)
                    Text("Zmiany dotyczą tej rośliny. Historia, terminy kontroli i wspólny atlas pozostają bez zmian.").font(.footnote)
                }
                if let error { Text(error).foregroundStyle(Palette.terracotta) }
            }
            .navigationTitle("Edytuj roślinę")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Anuluj") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Zapisz") {
                        let old = (plant.name, plant.speciesName, plant.room, plant.customRequirements)
                        plant.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        plant.speciesName = speciesName.trimmingCharacters(in: .whitespacesAndNewlines)
                        plant.room = room.trimmingCharacters(in: .whitespacesAndNewlines)
                        plant.customRequirements = instructions.trimmingCharacters(in: .whitespacesAndNewlines)
                        do { try context.save(); dismiss() }
                        catch {
                            (plant.name, plant.speciesName, plant.room, plant.customRequirements) = old
                            self.error = "Nie udało się zapisać zmian. Twoja wersja pozostała w edytorze."
                        }
                    }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}
