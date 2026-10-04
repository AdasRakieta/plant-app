import SwiftUI
import PhotosUI
import UIKit

struct SharedSpecies: Codable, Identifiable {
    let id: String
    let name: String
    let requirements: String
    let source: String
    let image: String
    let status: String
    var photo: UIImage? {
        guard let data = Data(base64Encoded: image) else { return nil }
        return UIImage(data: data)
    }
}
struct SharedAtlasResponse: Codable { let entries: [SharedSpecies] }
struct SharedAtlasPublication: Decodable { let entry: SharedSpecies; let message: String }

struct SharedAtlasView: View {
    @State private var entries: [SharedSpecies] = []
    @State private var status = ""
    @State private var query = ""
    @State private var loading = false
    private var cache: URL { URL.applicationSupportDirectory.appendingPathComponent("shared-atlas.json") }

    var body: some View {
        List {
            Section {
                Text("Wpisy społeczności są przechowywane na Malinie i dostępne dla użytkowników jej sieci LAN lub VPN. Wymagania nie są zweryfikowane przez eksperta.")
                NavigationLink("Dodaj nowy gatunek") { SharedAtlasForm() }
                Button("Synchronizuj teraz") { Task { await refresh() } }.disabled(loading)
                if loading { ProgressView() }
                Text(status).font(.footnote).foregroundStyle(.secondary)
            }
            ForEach(entries.filter { query.isEmpty || $0.name.localizedCaseInsensitiveContains(query) }) { entry in
                NavigationLink {
                    SharedSpeciesDetail(entry: entry)
                } label: {
                    HStack {
                        if let image = entry.photo {
                            Image(uiImage: image).resizable().scaledToFill().frame(width: 64, height: 64).clipped().clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        VStack(alignment: .leading) {
                            Text(entry.name).font(.headline)
                            Text("Wpis społeczności · niezweryfikowany").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle("Wspólny atlas")
        .searchable(text: $query, prompt: "Szukaj gatunku")
        .task {
            if let data = try? Data(contentsOf: cache), let stored = try? JSONDecoder().decode(SharedAtlasResponse.self, from: data) { entries = stored.entries }
            await refresh()
        }
        .refreshable { await refresh() }
    }

    @MainActor private func refresh() async {
        guard !loading else { return }
        loading = true
        defer { loading = false }
        do {
            let response = try await LocalPlantAIClient.shared.sharedAtlas()
            entries = response.entries
            try FileManager.default.createDirectory(at: URL.applicationSupportDirectory, withIntermediateDirectories: true)
            try JSONEncoder().encode(response).write(to: cache, options: .atomic)
            status = "Zsynchronizowano \(entries.count) gatunków. Kopia jest dostępna offline."
        } catch { status = "Nie udało się odświeżyć atlasu. Pokazuję ostatnią kopię. \(error.localizedDescription)" }
    }
}

private struct SharedSpeciesDetail: View {
    let entry: SharedSpecies
    @State private var adding = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if let image = entry.photo { Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 280) }
                Text(entry.name).font(.largeTitle.bold())
                Text("Wpis społeczności — wymagania i oznaczenie gatunku wymagają sprawdzenia.").foregroundStyle(.secondary)
                Text(entry.requirements)
                Text("Źródło: \(entry.source)").font(.footnote)
                Text("Bezpieczeństwo dla zwierząt: brak zweryfikowanych danych.").font(.footnote)
                Button("Dodaj do moich roślin") { adding = true }.buttonStyle(PrimaryButtonStyle())
            }.padding()
        }
        .sheet(isPresented: $adding) { AddPlantView(customSpeciesName: entry.name, customRequirements: entry.requirements, initialPhoto: entry.photo) }
    }
}

struct SharedAtlasForm: View {
    @State private var name: String
    @State private var requirements: String
    @State private var image: UIImage?
    @State private var source = ""
    @State private var photoItem: PhotosPickerItem?
    @State private var consent = false
    @State private var busy = false
    @State private var published = false
    @State private var message: String?

    init(plant: Plant? = nil) {
        _name = State(initialValue: plant?.speciesName ?? "")
        _requirements = State(initialValue: plant?.customRequirements ?? "")
        _image = State(initialValue: PlantPhotos.image(plant?.photoFilename))
    }

    var body: some View {
        Form {
            Section("Gatunek") {
                TextField("Nazwa gatunku lub odmiany", text: $name)
                Text("Wymagania: światło, podłoże, nawożenie, doniczka. Nieznane informacje oznacz jako brak danych.").font(.footnote)
                TextEditor(text: $requirements).frame(minHeight: 140)
                TextField("Źródło informacji lub własna obserwacja", text: $source)
                PhotosPicker(selection: $photoItem, matching: .images) { Label("Wybierz zdjęcie lub gotową grafikę", systemImage: "photo") }
                if let image { Image(uiImage: image).resizable().scaledToFit().frame(maxHeight: 180) }
            }
            Section("Udostępnienie") {
                Text("Wyślesz nazwę, wymagania, źródło i wybrany obraz na Malinę. Będą dostępne innym użytkownikom tego serwera. Nazwa egzemplarza, pomieszczenie i historia pielęgnacji pozostają prywatne.")
                Toggle("Mam prawa do obrazu i opisu oraz zgadzam się na udostępnienie", isOn: $consent)
                Button(busy ? "Zapisuję…" : "Zapisz we wspólnym atlasie") {
                    Task { await publish() }
                }.disabled(busy || published || !consent || name.trimmingCharacters(in: .whitespacesAndNewlines).count < 2 || requirements.trimmingCharacters(in: .whitespacesAndNewlines).count < 10 || source.trimmingCharacters(in: .whitespacesAndNewlines).count < 3)
                if let message { Text(message).font(.footnote) }
            }
        }
        .navigationTitle("Nowy wpis atlasu")
        .disabled(published)
        .onChange(of: photoItem) { _, item in
            Task { @MainActor in
                do {
                    guard let data = try await item?.loadTransferable(type: Data.self), let selected = UIImage(data: data) else { throw LocalPlantAIError.invalidImage }
                    image = selected
                } catch { message = "Nie udało się wczytać obrazu." }
            }
        }
    }

    @MainActor private func publish() async {
        busy = true
        defer { busy = false }
        do {
            let result = try await LocalPlantAIClient.shared.publishSpecies(name: name, requirements: requirements, source: source, image: image)
            message = result.message
            published = true
        } catch { message = error.localizedDescription }
    }
}
