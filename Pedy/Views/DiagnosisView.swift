import SwiftUI
import PhotosUI

struct DiagnosisView: View {
    @State private var photo: PhotosPickerItem?
    @State private var symptom = ""
    @State private var result: String?
    private let symptoms = ["Żółte liście", "Brązowe końcówki", "Opadające liście", "Plamy na liściach", "Szkodniki"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Diagnoza").font(.largeTitle.bold()).foregroundStyle(Palette.forest)
                Text("Zapisz objaw i sprawdź bezpieczne, pierwsze kroki. Zdjęcie zostaje na urządzeniu.").foregroundStyle(.secondary)
                PhotosPicker(selection: $photo, matching: .images) {
                    Label(photo == nil ? "Dodaj zdjęcie rośliny" : "Zmień zdjęcie", systemImage: "camera")
                        .frame(maxWidth: .infinity).padding(22).background(Palette.surface, in: RoundedRectangle(cornerRadius: 20))
                }.buttonStyle(.plain)
                Text("Co widzisz?").font(.title2.bold())
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                    ForEach(symptoms, id: \.self) { item in
                        Button(item) { symptom = item } .padding(13).frame(maxWidth: .infinity)
                            .background(symptom == item ? Palette.terracotta : Palette.surface, in: RoundedRectangle(cornerRadius: 14))
                            .foregroundStyle(symptom == item ? .white : Palette.forest)
                    }
                }
                Button("Pokaż bezpieczne kroki") { result = advice }.buttonStyle(PrimaryButtonStyle()).disabled(symptom.isEmpty)
                if let result { Text(result).padding(18).background(Palette.surface, in: RoundedRectangle(cornerRadius: 18)) }
            }.padding(20)
        }.background(Palette.background.ignoresSafeArea())
    }

    private var advice: String {
        switch symptom {
        case "Żółte liście": "Sprawdź wilgotność podłoża i odpływ w doniczce. Usuń tylko całkiem żółty liść; nie podlewaj dodatkowo bez sprawdzenia ziemi."
        case "Brązowe końcówki": "Sprawdź, czy podłoże nie przesycha całkowicie i czy roślina nie stoi przy grzejniku. Odetnij wyłącznie zaschniętą końcówkę czystymi nożyczkami."
        case "Szkodniki": "Odizoluj roślinę i obejrzyj spody liści. Zrób zdjęcie z bliska; nie stosuj preparatu, dopóki nie rozpoznasz problemu."
        default: "Sprawdź światło, wilgotność podłoża i spody liści. Zapisz obserwację, aby porównać zmianę za kilka dni."
        }
    }
}
