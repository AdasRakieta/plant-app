import Foundation
import SwiftData

@Model
final class Plant {
    @Attribute(.unique) var id: UUID
    var name: String
    var speciesName: String
    var room: String
    var nextCheckDate: Date
    var checkIntervalDays: Int
    var lastWateredAt: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        speciesName: String = "",
        room: String = "",
        nextCheckDate: Date = .now,
        checkIntervalDays: Int = 3,
        lastWateredAt: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.speciesName = speciesName
        self.room = room
        self.nextCheckDate = nextCheckDate
        self.checkIntervalDays = checkIntervalDays
        self.lastWateredAt = lastWateredAt
        self.createdAt = createdAt
    }
}

@Model
final class CareEvent {
    @Attribute(.unique) var id: UUID
    var plantID: UUID
    var kind: String
    var occurredAt: Date
    var note: String

    init(id: UUID = UUID(), plantID: UUID, kind: Kind, occurredAt: Date = .now, note: String = "") {
        self.id = id
        self.plantID = plantID
        self.kind = kind.rawValue
        self.occurredAt = occurredAt
        self.note = note
    }

    enum Kind: String {
        case moist
        case dry
        case uncertain
        case watered

        var title: String {
            switch self {
            case .moist: "Podłoże nadal wilgotne"
            case .dry: "Podłoże suche"
            case .uncertain: "Nie udało się ocenić"
            case .watered: "Podlano"
            }
        }
    }
}
