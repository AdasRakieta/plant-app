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
    let aliases: [String] = []

    var imageName: String { id == "aglaonema" ? "PlantHero" : "Plant-\(id)" }

    var editableInstructions: String {
        "\(summary)\n\nŚwiatło: \(light)\nPodlewanie: \(watering)\nPodłoże: \(soil)\nDoniczka: \(pot)\nNawożenie: \(fertilizer)\nTrudność: \(difficulty)\nZwierzęta: \(petSafety)"
    }

    var difficulty: String {
        switch id {
        case "sansewieria", "zamiokulkas", "zielistka", "epipremnum", "fikus-sprężysty", "dracena", "aloes", "grubosz", "hoja", "peperomia", "cissus", "pachira", "kaktus": "Łatwa"
        case "calathea", "maranta", "paprotka", "anturium", "fitonia", "kroton", "gardenia", "kaladium": "Wymagająca"
        default: "Umiarkowana"
        }
    }

    var fertilizer: String {
        switch id {
        case "aloes", "grubosz", "sansewieria", "zamiokulkas", "kaktus", "nolina": "Od kwietnia do sierpnia co 4–6 tygodni, połową dawki nawozu do sukulentów."
        case "calathea", "maranta", "paprotka", "skrzydłokwiat": "Od marca do września co 4 tygodnie, połową dawki nawozu do roślin zielonych."
        default: "Od marca do września co 2–4 tygodnie, nawozem do roślin zielonych według etykiety."
        }
    }

    var soil: String {
        switch id {
        case "aloes", "grubosz", "sansewieria", "zamiokulkas", "kaktus", "nolina": "Przepuszczalne podłoże do kaktusów i sukulentów z perlitem lub pumeksem."
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
        .init(id: "aglaonema", commonName: "Aglaonema", latinName: "Aglaonema commutatum", light: "Jasne, rozproszone lub półcień", watering: "Gdy przeschną 2–4 cm podłoża", intervalDays: 7, summary: "Barwna roślina o lancetowatych liściach; odmiany czerwono-zielone wymagają jasnego, rozproszonego światła.", petSafety: "Toksyczna dla zwierząt"),
        .init(id: "fikus-tepy", commonName: "Fikus tępy (Ginseng)", latinName: "Ficus microcarpa", light: "Jasne, rozproszone", watering: "Gdy przeschnie wierzch podłoża", intervalDays: 7, summary: "Popularny figowiec bonsai o zgrubiałych korzeniach.", petSafety: "Toksyczny dla zwierząt", aliases: ["Figowiec tępy", "Fikus Ginseng", "Ficus microcarpa Ginseng"]),
        .init(id: "fitonia", commonName: "Fitonia", latinName: "Fittonia albivenis", light: "Półcień", watering: "Lekko wilgotne podłoże", intervalDays: 4, summary: "Niska roślina o dekoracyjnym unerwieniu liści.", petSafety: "Bezpieczna dla zwierząt"),
        .init(id: "kroton", commonName: "Kroton", latinName: "Codiaeum variegatum", light: "Bardzo jasne, rozproszone", watering: "Gdy przeschnie wierzch", intervalDays: 6, summary: "Barwne liście wymagają dużo światła i stabilnych warunków.", petSafety: "Toksyczny dla zwierząt"),
        .init(id: "bluszcz", commonName: "Bluszcz", latinName: "Hedera helix", light: "Jasne lub półcień", watering: "Gdy przeschnie wierzch", intervalDays: 6, summary: "Pnącze dobrze wyglądające na półce lub podporze.", petSafety: "Toksyczny dla zwierząt"),
        .init(id: "begonia", commonName: "Begonia maculata", latinName: "Begonia maculata", light: "Jasne, rozproszone", watering: "Gdy przeschnie wierzch", intervalDays: 6, summary: "Begonia o liściach w charakterystyczne kropki.", petSafety: "Toksyczna dla zwierząt"),
        .init(id: "peperomia", commonName: "Peperomia", latinName: "Peperomia obtusifolia", light: "Jasne, rozproszone", watering: "Po lekkim przeschnięciu", intervalDays: 8, summary: "Kompaktowa roślina o mięsistych liściach.", petSafety: "Bezpieczna dla zwierząt"),
        .init(id: "juka", commonName: "Juka", latinName: "Yucca elephantipes", light: "Bardzo jasne", watering: "Po przeschnięciu większości podłoża", intervalDays: 12, summary: "Odporna roślina o sztywnych liściach i pniu.", petSafety: "Toksyczna dla zwierząt"),
        .init(id: "chamedora", commonName: "Palma koralowa", latinName: "Chamaedorea elegans", light: "Półcień", watering: "Gdy przeschnie wierzch", intervalDays: 7, summary: "Niewielka palma dobrze znosząca mniej światła.", petSafety: "Bezpieczna dla zwierząt"),
        .init(id: "areka", commonName: "Areka", latinName: "Dypsis lutescens", light: "Jasne, rozproszone", watering: "Gdy przeschnie wierzch", intervalDays: 6, summary: "Pierzaście ulistniona palma do jasnych pomieszczeń.", petSafety: "Bezpieczna dla zwierząt"),
        .init(id: "kencja", commonName: "Kencja", latinName: "Howea forsteriana", light: "Jasne lub półcień", watering: "Gdy przeschnie wierzch", intervalDays: 8, summary: "Wolno rosnąca palma o eleganckich liściach.", petSafety: "Bezpieczna dla zwierząt"),
        .init(id: "nolina", commonName: "Nolina", latinName: "Beaucarnea recurvata", light: "Bardzo jasne", watering: "Po pełnym przeschnięciu", intervalDays: 16, summary: "Roślina magazynująca wodę w zgrubiałej podstawie.", petSafety: "Bezpieczna dla zwierząt"),
        .init(id: "pachira", commonName: "Pachira", latinName: "Pachira aquatica", light: "Jasne, rozproszone", watering: "Gdy przeschnie wierzch", intervalDays: 7, summary: "Drzewko o często splecionym pniu i dłoniastych liściach.", petSafety: "Bezpieczna dla zwierząt"),
        .init(id: "trzykrotka", commonName: "Trzykrotka", latinName: "Tradescantia zebrina", light: "Jasne, rozproszone", watering: "Gdy przeschnie wierzch", intervalDays: 5, summary: "Szybko rosnące pnącze o pasiastych liściach.", petSafety: "Może podrażniać zwierzęta"),
        .init(id: "eszynantus", commonName: "Eszynantus", latinName: "Aeschynanthus radicans", light: "Jasne, rozproszone", watering: "Gdy przeschnie wierzch", intervalDays: 7, summary: "Zwieszająca się roślina, która może tworzyć rurkowate kwiaty.", petSafety: "Brak potwierdzonych danych"),
        .init(id: "cissus", commonName: "Cissus rombolistny", latinName: "Cissus rhombifolia", light: "Jasne lub półcień", watering: "Gdy przeschnie wierzch", intervalDays: 7, summary: "Łatwe pnącze o trójdzielnych liściach.", petSafety: "Bezpieczny dla zwierząt"),
        .init(id: "asparagus", commonName: "Szparag Sprengera", latinName: "Asparagus densiflorus", light: "Jasne, rozproszone", watering: "Gdy przeschnie wierzch", intervalDays: 6, summary: "Delikatne, pierzaste pędy tworzą lekką kaskadę.", petSafety: "Toksyczny dla zwierząt"),
        .init(id: "kalanchoe", commonName: "Kalanchoe", latinName: "Kalanchoe blossfeldiana", light: "Bardzo jasne", watering: "Po przeschnięciu", intervalDays: 10, summary: "Kwitnący sukulent o mięsistych liściach.", petSafety: "Toksyczne dla zwierząt"),
        .init(id: "cyklamen", commonName: "Cyklamen", latinName: "Cyclamen persicum", light: "Jasne i chłodniejsze", watering: "Gdy przeschnie wierzch", intervalDays: 5, summary: "Sezonowo kwitnąca roślina, która nie lubi gorąca.", petSafety: "Toksyczny dla zwierząt"),
        .init(id: "gardenia", commonName: "Gardenia", latinName: "Gardenia jasminoides", light: "Jasne, rozproszone", watering: "Lekko wilgotne", intervalDays: 4, summary: "Pachnąca roślina kwitnąca, wrażliwa na zmianę warunków.", petSafety: "Bezpieczna dla zwierząt"),
        .init(id: "kaladium", commonName: "Kaladium", latinName: "Caladium bicolor", light: "Jasne, rozproszone", watering: "Lekko wilgotne", intervalDays: 4, summary: "Roślina o dużych, barwnych liściach.", petSafety: "Toksyczne dla zwierząt"),
        .init(id: "kaktus", commonName: "Kaktus", latinName: "Echinopsis", light: "Bardzo jasne", watering: "Po pełnym przeschnięciu", intervalDays: 18, summary: "Sukulenta wymagająca bardzo przepuszczalnego podłoża.", petSafety: "Brak pełnych danych")
    ]

    static func match(_ name: String) -> PlantSpecies? {
        let needle = name.folding(options: .diacriticInsensitive, locale: .current).lowercased()
        return catalog.first {
            $0.commonName.folding(options: .diacriticInsensitive, locale: .current).lowercased() == needle ||
            $0.latinName.folding(options: .diacriticInsensitive, locale: .current).lowercased() == needle ||
            $0.aliases.contains { $0.folding(options: .diacriticInsensitive, locale: .current).lowercased() == needle }
        }
    }
}
