import SwiftUI
import SwiftData

struct CareDetailView: View {
    let plant: Plant
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var selection: CareEvent.Kind?
    @State private var dryRecorded = false
    @State private var saveError: String?
    @State private var confirmation: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(spacing: 14) {
                    PlantThumbnail(species: PlantSpecies.match(plant.speciesName))
                    VStack(alignment: .leading) {
                        Text(plant.name).font(.title2.bold())
                        Text(plant.room.isEmpty ? "Moja roślina" : plant.room)
                            .foregroundStyle(.secondary)
                    }
                }

                Text("Sprawdź podłoże")
                    .font(.largeTitle.bold())
                Text("Zanim zdecydujesz o podlewaniu")
                    .foregroundStyle(.secondary)

                VStack(alignment: .leading, spacing: 10) {
                    Image(PlantSpecies.match(plant.speciesName)?.imageName ?? "PlantHero").resizable().scaledToFill().frame(height: 170).clipped().clipShape(RoundedRectangle(cornerRadius: 14))
                    Text("Jak to sprawdzić?").font(.title3.bold()).foregroundStyle(Palette.terracotta)
                    Text("Sprawdź podłoże także pod powierzchnią. Oceń, czy jest nadal wilgotne, czy już suche. \(PlantSpecies.match(plant.speciesName)?.watering ?? "Nie podlewaj tylko według kalendarza.")")
                    if let requirements = plant.customRequirements, !requirements.isEmpty {
                        Divider()
                        Label("Własne wymagania", systemImage: "list.bullet.clipboard")
                            .font(.headline)
                        Text(requirements).font(.subheadline)
                    }
                    if plant.speciesName.isEmpty {
                        Text("Gatunek tej rośliny nie został jeszcze określony.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: 20))

                Text("Co czujesz?").font(.title2.bold())
                choice(.moist, subtitle: "Zapisz obserwację i odłóż kontrolę")
                choice(.dry, subtitle: "Zapisz obserwację i sprawdź podlewanie")
                choice(.uncertain, subtitle: "Wróć do kontroli jutro")

                if dryRecorded {
                    Text("Podłoże zapisane jako suche. Podlej tylko, jeśli to właściwe dla tej rośliny.")
                        .font(.subheadline)
                    Button("Podlano") { recordWatering() }
                        .buttonStyle(PrimaryButtonStyle())
                    Button("Nie podlewam teraz") { confirmation = "Zapisano: podłoże suche. Kontrola wróci jutro, a podlewanie nie zostało zapisane." }
                        .frame(maxWidth: .infinity)
                } else {
                    Button("Zapisz obserwację") { saveObservation() }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(selection == nil)
                }

                Divider()
                Label("Jak powinny wyglądać liście?", systemImage: "leaf")
                    .font(.headline)
                Text("Zdjęcia porównawcze właściwego gatunku pojawią się w atlasie. Jeśli coś Cię niepokoi, możesz na razie zapisać obserwację w historii.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(Palette.forest)
            .padding(20)
        }
        .background(Palette.background.ignoresSafeArea())
        .navigationTitle("Szczegóły zadania")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Błąd zapisu", isPresented: Binding(
            get: { saveError != nil },
            set: { if !$0 { saveError = nil } }
        )) {
            Button("OK", role: .cancel) { saveError = nil }
        } message: {
            Text(saveError ?? "")
        }
        .alert("Zapisano", isPresented: Binding(
            get: { confirmation != nil },
            set: { if !$0 { confirmation = nil } }
        )) {
            Button("Gotowe") { dismiss() }
        } message: {
            Text(confirmation ?? "")
        }
    }

    private func choice(_ kind: CareEvent.Kind, subtitle: String) -> some View {
        Button {
            selection = kind
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selection == kind ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(Palette.terracotta)
                VStack(alignment: .leading, spacing: 4) {
                    Text(kind == .moist ? "Jeszcze wilgotne" : kind == .dry ? "Suche" : "Nie wiem")
                        .font(.headline)
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(16)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selection == kind ? .isSelected : [])
    }

    private func saveObservation() {
        guard let selection else { return }
        let now = Date()
        context.insert(CareEvent(plantID: plant.id, kind: selection, occurredAt: now))
        switch selection {
        case .moist:
            plant.nextCheckDate = CarePlanner.nextCheck(after: now, intervalDays: plant.checkIntervalDays)
        case .uncertain:
            plant.nextCheckDate = CarePlanner.nextCheck(after: now, intervalDays: 1)
        case .dry:
            plant.nextCheckDate = CarePlanner.nextCheck(after: now, intervalDays: 1)
        case .watered:
            break
        }
        do {
            try context.save()
            switch selection {
            case .dry:
                dryRecorded = true
            case .moist:
                confirmation = "Zapisano: podłoże nadal wilgotne. Następna kontrola została zaplanowana."
            case .uncertain:
                confirmation = "Zapisano: ocena jest niepewna. Przypomnę o kontroli jutro."
            case .watered:
                break
            }
        } catch {
            context.rollback()
            saveError = "Nie udało się zapisać obserwacji. Spróbuj ponownie."
        }
    }

    private func recordWatering() {
        let now = Date()
        context.insert(CareEvent(plantID: plant.id, kind: .watered, occurredAt: now))
        plant.lastWateredAt = now
        plant.nextCheckDate = CarePlanner.nextCheck(after: now, intervalDays: plant.checkIntervalDays)
        do {
            try context.save()
            confirmation = "Zapisano podlewanie i wyznaczono następną kontrolę."
        } catch {
            context.rollback()
            saveError = "Nie udało się zapisać podlewania. Spróbuj ponownie."
        }
    }
}
