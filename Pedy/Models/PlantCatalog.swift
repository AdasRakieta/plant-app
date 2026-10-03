import Foundation

struct PlantSpecies: Identifiable, Hashable {
    let id: String
    let commonName: String
    let latinName: String
    let light: String
    let watering: String
    let intervalDays: Int
    let summary: String
    let petSafety: String

    var imageName: String { id == "aglaonema" ? "PlantHero" : "Plant-\(id)" }

    var difficulty: String {
        switch id {
        case "sansewieria", "zamiokulkas", "zielistka", "epipremnum", "fikus-sprężysty", "dracena", "aloes", "grubosz", "hoja": "Łatwa"
        case "calathea", "maranta", "paprotka", "anturium": "Wymagająca"
        default: "Umiarkowana"
        }
    }

    var fertilizer: String {
        switch id {
        case "aloes", "grubosz", "sansewieria", "zamiokulkas": "Od kwietnia do sierpnia co 4–6 tygodni, połową dawki nawozu do sukulentów."
        case "calathea", "maranta", "paprotka", "skrzydłokwiat": "Od marca do września co 4 tygodnie, połową dawki nawozu do roślin zielonych."
        default: "Od marca do września co 2–4 tygodnie, nawozem do roślin zielonych według etykiety."
        }
    }

    var soil: String {
        switch id {
        case "aloes", "grubosz", "sansewieria", "zamiokulkas": "Przepuszczalne podłoże do kaktusów i sukulentów z perlitem lub pumeksem."
        case "calathea", "maranta", "paprotka", "skrzydłokwiat": "Lekka mieszanka do roślin zielonych z włóknem kokosowym i perlitem, stale lekko wilgotna."
        case "anturium", "monstera", "epipremnum", "hoja": "Przewiewna mieszanka aroidowa: ziemia, kora, perlit i włókno kokosowe."
        default: "Dobrej jakości, przepuszczalne podłoże do roślin zielonych z dodatkiem perlitu."
        }
    }

    var pot: String {
        switch id {
        case "calathea", "maranta", "paprotka", "skrzydłokwiat": "Doniczka z odpływem; osłonka nie może zatrzymywać wody przy korzeniach."
        default: "Doniczka z otworem odpływowym, tylko 2–3 cm szersza od bryły korzeniowej."
        }
    }

    static let catalog: [PlantSpecies] = [
        .init(id: "monstera", commonName: "Monstera", latinName: "Monstera deliciosa", light: "Jasne, rozproszone", watering: "Gdy przeschną 3–5 cm podłoża", intervalDays: 7, summary: "Duże, perforowane liście. Lubi stabilne, jasne stanowisko.", petSafety: "Toksyczna dla zwierząt"),
        .init(id: "fikus-sprężysty", commonName: "Fikus sprężysty", latinName: "Ficus elastica", light: "Jasne, rozproszone", watering: "Gdy przeschnie wierzch podłoża", intervalDays: 8, summary: "Wytrzymały fikus o błyszczących liściach.", petSafety: "Toksyczny dla zwierząt"),
        .init(id: "sansewieria", commonName: "Sansewieria", latinName: "Dracaena trifasciata", light: "Od półcienia do jasnego", watering: "Dopiero po pełnym przeschnięciu", intervalDays: 14, summary: "Bardzo odporna roślina o sztywnych liściach.", petSafety: "Toksyczna dla zwierząt"),
        .init(id: "epipremnum", commonName: "Epipremnum", latinName: "Epipremnum aureum", light: "Półcień lub światło rozproszone", watering: "Gdy przeschnie wierzch", intervalDays: 7, summary: "Pnącze, które łatwo prowadzić po podporze lub z półki.", petSafety: "Toksyczne dla zwierząt"),
        .init(id: "zamiokulkas", commonName: "Zamiokulkas", latinName: "Zamioculcas zamiifolia", light: "Półcień", watering: "Po pełnym przeschnięciu", intervalDays: 16, summary: "Dobrze znosi rzadsze podlewanie i mniej światła.", petSafety: "Toksyczny dla zwierząt"),
        .init(id: "skrzydłokwiat", commonName: "Skrzydłokwiat", latinName: "Spathiphyllum wallisii", light: "Półcień", watering: "Lekko wilgotne, nie mokre", intervalDays: 5, summary: "Lubi podwyższoną wilgotność i równą pielęgnację.", petSafety: "Toksyczny dla zwierząt"),
        .init(id: "zielistka", commonName: "Zielistka", latinName: "Chlorophytum comosum", light: "Jasne, rozproszone", watering: "Gdy przeschnie wierzch", intervalDays: 7, summary: "Łatwa roślina z kaskadą wąskich liści.", petSafety: "Bezpieczna dla zwierząt"),
        .init(id: "pilea", commonName: "Pilea", latinName: "Pilea peperomioides", light: "Jasne, rozproszone", watering: "Gdy przeschnie 2–3 cm", intervalDays: 6, summary: "Okrągłe liście i kompaktowy pokrój.", petSafety: "Bezpieczna dla zwierząt"),
        .init(id: "calathea", commonName: "Kalatea", latinName: "Goeppertia orbifolia", light: "Półcień", watering: "Lekko wilgotne", intervalDays: 4, summary: "Dekoracyjne liście; nie lubi suchego powietrza.", petSafety: "Bezpieczna dla zwierząt"),
        .init(id: "maranta", commonName: "Maranta", latinName: "Maranta leuconeura", light: "Półcień", watering: "Lekko wilgotne", intervalDays: 4, summary: "Wieczorem unosi liście, lubi wilgotne powietrze.", petSafety: "Bezpieczna dla zwierząt"),
        .init(id: "dracena", commonName: "Dracena", latinName: "Dracaena marginata", light: "Jasne, rozproszone", watering: "Gdy przeschnie wierzch", intervalDays: 9, summary: "Smukła roślina o architektonicznym pokroju.", petSafety: "Toksyczna dla zwierząt"),
        .init(id: "aloes", commonName: "Aloes", latinName: "Aloe vera", light: "Bardzo jasne", watering: "Po pełnym przeschnięciu", intervalDays: 14, summary: "Sukulenta magazynująca wodę w mięsistych liściach.", petSafety: "Toksyczny dla zwierząt"),
        .init(id: "grubosz", commonName: "Grubosz", latinName: "Crassula ovata", light: "Bardzo jasne", watering: "Po pełnym przeschnięciu", intervalDays: 14, summary: "Sukulenta o grubych, owalnych liściach.", petSafety: "Toksyczny dla zwierząt"),
        .init(id: "paprotka", commonName: "Paprotka", latinName: "Nephrolepis exaltata", light: "Półcień", watering: "Podłoże lekko wilgotne", intervalDays: 4, summary: "Delikatne pierzaste liście, ceni wilgotne powietrze.", petSafety: "Bezpieczna dla zwierząt"),
        .init(id: "anturium", commonName: "Anturium", latinName: "Anthurium andraeanum", light: "Jasne, rozproszone", watering: "Gdy przeschnie wierzch", intervalDays: 6, summary: "Kwitnąca roślina o dekoracyjnych pochwach kwiatowych.", petSafety: "Toksyczne dla zwierząt"),
        .init(id: "hoja", commonName: "Hoja", latinName: "Hoya carnosa", light: "Jasne, rozproszone", watering: "Gdy przeschnie większość podłoża", intervalDays: 10, summary: "Pnącze o woskowych liściach i pachnących kwiatach.", petSafety: "Bezpieczna dla zwierząt"),
        .init(id: "aglaonema", commonName: "Aglaonema", latinName: "Aglaonema commutatum", light: "Jasne, rozproszone lub półcień", watering: "Gdy przeschną 2–4 cm podłoża", intervalDays: 7, summary: "Barwna roślina o lancetowatych liściach; odmiany czerwono-zielone wymagają jasnego, rozproszonego światła.", petSafety: "Toksyczna dla zwierząt")
    ]

    static func match(_ name: String) -> PlantSpecies? {
        let needle = name.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        return catalog.first { $0.commonName.lowercased() == needle || $0.latinName.lowercased() == needle }
    }
}
