import Foundation

struct CareWindow: Identifiable, Equatable {
    let id: UUID
    let plantID: UUID
    let plantName: String
    let earliest: Date
    let latest: Date
}

struct CareSession: Identifiable {
    let date: Date
    let tasks: [CareWindow]
    var id: Date { date }
}

enum CarePlanner {
    static func tasks(for plants: [Plant], calendar: Calendar = .current) -> [CareWindow] {
        plants.map { plant in
            let earliest = calendar.startOfDay(for: plant.nextCheckDate)
            return CareWindow(
                id: plant.id,
                plantID: plant.id,
                plantName: plant.name,
                earliest: earliest,
                latest: calendar.date(byAdding: .day, value: 2, to: earliest) ?? earliest
            )
        }
    }

    /// Each task is assigned exactly once to a day within its own window.
    /// A preferred weekday breaks ties but never exceeds a task's latest day.
    static func sessions(
        for windows: [CareWindow],
        preferredWeekday: Int = 7,
        calendar: Calendar = .current
    ) -> [CareSession] {
        var remaining = windows.sorted {
            $0.latest == $1.latest ? $0.earliest < $1.earliest : $0.latest < $1.latest
        }
        var result: [CareSession] = []

        while let first = remaining.first {
            let start = calendar.startOfDay(for: first.earliest)
            let end = calendar.startOfDay(for: first.latest)
            var bestDay = start
            var bestScore = Int.min
            var candidate = start

            while candidate <= end {
                let count = remaining.filter { $0.earliest <= candidate && candidate <= $0.latest }.count
                let distance = calendar.dateComponents([.day], from: start, to: candidate).day ?? 0
                let preferred = calendar.component(.weekday, from: candidate) == preferredWeekday ? 10 : 0
                let score = count * 100 + preferred - distance
                if score > bestScore {
                    bestScore = score
                    bestDay = candidate
                }
                guard let next = calendar.date(byAdding: .day, value: 1, to: candidate) else { break }
                candidate = next
            }

            let grouped = remaining.filter { $0.earliest <= bestDay && bestDay <= $0.latest }
            let assigned = Set(grouped.map(\.id))
            remaining.removeAll { assigned.contains($0.id) }
            result.append(CareSession(date: bestDay, tasks: grouped))
        }
        return result.sorted { $0.date < $1.date }
    }

    static func nextCheck(after observation: Date, intervalDays: Int, calendar: Calendar = .current) -> Date {
        let days = max(1, intervalDays)
        return calendar.date(byAdding: .day, value: days, to: calendar.startOfDay(for: observation)) ?? observation
    }
}
