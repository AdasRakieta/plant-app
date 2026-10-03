import SwiftUI
import PhotosUI
import UIKit

struct DiagnosisView: View {
    @State private var photo: PhotosPickerItem?
    @State private var image: UIImage?
    @State private var symptom = ""
    @State private var result: PlantDiagnosis?
    @State private var isAnalysing = false
    @State private var errorMessage: String?
    private let symptoms = ["Żółte liście", "Brązowe końcówki", "Opadające liście", "Plamy na liściach", "Szkodniki"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Diagnoza").font(.largeTitle.bold()).foregroundStyle(Palette.forest)
                Text("Lokalne AI analizuje zdjęcie tylko na Twojej Malinie. Wynik jest hipotezą — zawsze sprawdź roślinę przed działaniem.")
                    .foregroundStyle(.secondary)
                PhotosPicker(selection: $photo, matching: .images) {
                    HStack {
                        if let image { Image(uiImage: image).resizable().scaledToFill().frame(width: 72, height: 72).clipShape(RoundedRectangle(cornerRadius: 14)) }
                        Label(photo == nil ? "Dodaj zdjęcie rośliny" : "Zmień zdjęcie", systemImage: "camera")
                        Spacer()
                    }.frame(maxWidth: .infinity).padding(14).background(Palette.surface, in: RoundedRectangle(cornerRadius: 20))
                }.buttonStyle(.plain)
                Text("Co widzisz?").font(.title2.bold()).foregroundStyle(Palette.forest)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(symptoms, id: \.self) { item in
                        Button(item) { symptom = item }
                            .padding(13).frame(maxWidth: .infinity)
                            .background(symptom == item ? Palette.terracotta : Palette.surface, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(symptom == item ? .white : Palette.forest)
                    }
                }
                Button { Task { await diagnose() } } label: {
                    if isAnalysing { HStack { ProgressView().tint(.white); Text("Analizuję lokalnie…") } }
                    else { Text("Pokaż bezpieczne kroki") }
                }.buttonStyle(PrimaryButtonStyle()).disabled(symptom.isEmpty || isAnalysing)
                if let errorMessage { Label(errorMessage, systemImage: "wifi.exclamationmark").foregroundStyle(Palette.terracotta).font(.subheadline) }
                if let result { DiagnosisResultCard(result: result) }
            }.padding(20)
        }
        .onChange(of: photo) { _, newValue in Task { await loadImage(newValue) } }
        .background(Palette.background.ignoresSafeArea())
    }

    @MainActor private func loadImage(_ item: PhotosPickerItem?) async {
        guard let data = try? await item?.loadTransferable(type: Data.self), let data, let loaded = UIImage(data: data) else { return }
        image = loaded
        result = nil
    }

    private func diagnose() async {
        await MainActor.run { isAnalysing = true; errorMessage = nil; result = nil }
        do {
            let diagnosis = try await LocalPlantAIClient.shared.diagnose(image: image, symptom: symptom)
            await MainActor.run { result = diagnosis }
        } catch {
            await MainActor.run { errorMessage = error.localizedDescription }
        }
        await MainActor.run { isAnalysing = false }
    }
}

private struct DiagnosisResultCard: View {
    let result: PlantDiagnosis
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Wynik pomocniczy", systemImage: "sparkles").font(.headline).foregroundStyle(Palette.forest)
            Text(result.uncertainty).font(.subheadline).foregroundStyle(.secondary)
            ForEach(result.hypotheses) { hypothesis in
                VStack(alignment: .leading, spacing: 6) {
                    Text(hypothesis.title).font(.headline)
                    Text("Prawdopodobieństwo: \(hypothesis.likelihood)").font(.caption).foregroundStyle(Palette.terracotta)
                    Text(hypothesis.evidence).font(.subheadline)
                    ForEach(hypothesis.safeChecks, id: \.self) { check in Label(check, systemImage: "checkmark.circle").font(.subheadline) }
                }.padding(.vertical, 5)
            }
            if !result.missingInformation.isEmpty { Text("Warto jeszcze sprawdzić: \(result.missingInformation.joined(separator: ", "))").font(.footnote).foregroundStyle(.secondary) }
        }.padding(18).background(Palette.surface, in: RoundedRectangle(cornerRadius: 18))
    }
}
