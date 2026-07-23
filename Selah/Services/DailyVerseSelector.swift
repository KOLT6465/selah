import Foundation

struct DailyVerseSelector: Sendable {
    private let salt = "selah.daily.v2"

    func verse(for date: Date, calendar: Calendar = .current, from verses: [Verse]) -> Verse {
        precondition(!verses.isEmpty)
        guard verses.count > 1 else { return verses[0] }

        let count = UInt64(verses.count)
        let localDay = localDayOrdinal(for: date, calendar: calendar)
        let day = UInt64((localDay % Int64(count) + Int64(count)) % Int64(count))
        let offset = stableHash("\(salt):offset") % count
        let step = coprimeStep(for: count)
        let index = Int((offset + ((day % count) * step) % count) % count)
        return verses[index]
    }

    func randomVerse<R: RandomNumberGenerator>(from verses: [Verse], excluding ids: Set<String>, using generator: inout R) -> Verse {
        precondition(!verses.isEmpty)
        let available = verses.filter { !ids.contains($0.id) }
        return (available.isEmpty ? verses : available).randomElement(using: &generator)!
    }

    private func stableHash(_ value: String) -> UInt64 {
        value.utf8.reduce(14_695_981_039_346_656_037) { hash, byte in
            (hash ^ UInt64(byte)) &* 1_099_511_628_211
        }
    }

    private func localDayOrdinal(for date: Date, calendar: Calendar) -> Int64 {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        var normalizedCalendar = calendar
        normalizedCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        if let normalizedDate = normalizedCalendar.date(from: components) {
            return Int64(floor(normalizedDate.timeIntervalSinceReferenceDate / 86_400))
        }
        let year = Int64(components.year ?? 0)
        let month = Int64(components.month ?? 0)
        let day = Int64(components.day ?? 0)
        return year * 10_000 + month * 100 + day
    }

    private func coprimeStep(for count: UInt64) -> UInt64 {
        var candidate = (stableHash("\(salt):step") % (count - 1)) + 1
        while greatestCommonDivisor(candidate, count) != 1 {
            candidate = candidate == count - 1 ? 1 : candidate + 1
        }
        return candidate
    }

    private func greatestCommonDivisor(_ lhs: UInt64, _ rhs: UInt64) -> UInt64 {
        var a = lhs
        var b = rhs
        while b != 0 {
            (a, b) = (b, a % b)
        }
        return a
    }
}
