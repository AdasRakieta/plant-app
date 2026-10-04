import SwiftUI

struct CareGuide {
    let summary: String?
    let rows: [(String, String)]

    init(_ requirements: String) {
        var summary: String?
        var values: [String: String] = [:]
        var current: String?
        let labels = ["Opis", "Światło", "Podlewanie", "Trudność", "Nawożenie", "Podłoże", "Doniczka", "Zwierzęta", "Status"]
        for raw in requirements.components(separatedBy: .newlines) {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "### ", with: "")
                .replacingOccurrences(of: "**", with: "")
            guard !line.isEmpty else { continue }
            if let colon = line.firstIndex(of: ":") {
                let key = String(line[..<colon]).trimmingCharacters(in: .whitespaces)
                let value = String(line[line.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
                if labels.contains(key) {
                    current = key
                    values[key] = value
                    continue
                }
            }
            if labels.contains(line) { current = line; values[line] = ""; continue }
            if let current { values[current] = [values[current], line].compactMap { $0 }.joined(separator: " ") }
            else { summary = [summary, line].compactMap { $0 }.joined(separator: " ") }
        }
        self.summary = values["Opis"] ?? summary
        self.rows = ["Światło", "Podlewanie", "Trudność", "Nawożenie", "Podłoże", "Doniczka", "Zwierzęta"].compactMap {
            guard let value = values[$0], !value.isEmpty else { return nil }
            return ($0, value)
        }
    }
}

struct CareGuideCard: View {
    let requirements: String
    private var guide: CareGuide { CareGuide(requirements) }
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let summary = guide.summary, !summary.isEmpty { Text(summary) }
            Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 14) {
                ForEach(Array(guide.rows.enumerated()), id: \.offset) { _, row in
                    GridRow {
                        Text(row.0).foregroundStyle(.secondary)
                        Text(row.1)
                    }
                }
            }
            if guide.rows.isEmpty { Text(requirements) }
        }
    }
}
