import Foundation

/// Wertet die häufigsten OSM-`opening_hours`-Formate aus, z. B.
/// `Mo-Fr 08:00-18:00; Sa 09:00-13:00`, `Mo-Fr 08:00-12:00,14:00-18:00`, `24/7`, `Su off`.
/// Nicht unterstützte Angaben (Monate, Feiertagslogik, sunrise …) liefern `nil` –
/// die App zeigt dann den Originaltext an.
public enum OSMOpeningHoursParser {
    private static let dayIndex: [String: Int] = ["Mo": 1, "Tu": 2, "We": 3, "Th": 4, "Fr": 5, "Sa": 6, "Su": 7]

    public static func parse(_ text: String) -> [OpeningPeriod]? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if trimmed == "24/7" {
            return (1...7).map { OpeningPeriod(weekday: $0, opensMinute: 0, closesMinute: 1440) }
        }

        var periods: [OpeningPeriod] = []
        for rawRule in trimmed.split(separator: ";") {
            let rule = rawRule.trimmingCharacters(in: .whitespaces)
            guard !rule.isEmpty else { continue }
            let parts = rule.split(separator: " ", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { return nil }

            // Feiertagsregeln („PH off“, „PH 10:00-12:00“) werden ignoriert.
            if parts[0] == "PH" { continue }
            guard let days = parseDays(parts[0]) else { return nil }

            let timeSpec = parts[1].trimmingCharacters(in: .whitespaces)
            // Spätere Regeln überschreiben frühere für dieselben Tage (OSM-Semantik).
            periods.removeAll { days.contains($0.weekday) }
            if timeSpec == "off" || timeSpec == "closed" { continue }

            guard let ranges = parseTimeRanges(timeSpec) else { return nil }
            for day in days {
                for range in ranges {
                    periods.append(OpeningPeriod(weekday: day, opensMinute: range.opens, closesMinute: range.closes))
                }
            }
        }
        guard !periods.isEmpty else { return nil }
        return periods.sorted { ($0.weekday, $0.opensMinute) < ($1.weekday, $1.opensMinute) }
    }

    static func parseDays(_ spec: String) -> [Int]? {
        var days: [Int] = []
        for item in spec.split(separator: ",") {
            let bounds = item.split(separator: "-").map(String.init)
            if bounds.count == 1, let day = dayIndex[bounds[0]] {
                days.append(day)
            } else if bounds.count == 2, let start = dayIndex[bounds[0]], let end = dayIndex[bounds[1]] {
                // Auch über das Wochenende hinweg, z. B. „Fr-Mo“.
                var day = start
                while true {
                    days.append(day)
                    if day == end { break }
                    day = day % 7 + 1
                }
            } else {
                return nil
            }
        }
        return days.isEmpty ? nil : days
    }

    static func parseTimeRanges(_ spec: String) -> [(opens: Int, closes: Int)]? {
        var ranges: [(opens: Int, closes: Int)] = []
        for item in spec.split(separator: ",") {
            let bounds = item.trimmingCharacters(in: .whitespaces).split(separator: "-").map(String.init)
            guard bounds.count == 2,
                  let opens = minutes(bounds[0]),
                  let closes = minutes(bounds[1]),
                  closes > opens
            else { return nil }
            ranges.append((opens, closes))
        }
        return ranges.isEmpty ? nil : ranges
    }

    static func minutes(_ time: String) -> Int? {
        let parts = time.split(separator: ":")
        guard parts.count == 2, let hour = Int(parts[0]), let minute = Int(parts[1]),
              (0...24).contains(hour), (0...59).contains(minute), hour * 60 + minute <= 1440
        else { return nil }
        return hour * 60 + minute
    }
}
