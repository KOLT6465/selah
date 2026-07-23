import AppKit
import XCTest
@testable import Selah

final class DailyVerseSelectorTests: XCTestCase {
    private let verses = [
        Verse(id: "A.1.1", book: "A", bookCode: "A", chapter: 1, verse: 1, text: String(repeating: "A", count: 60)),
        Verse(id: "B.1.1", book: "B", bookCode: "B", chapter: 1, verse: 1, text: String(repeating: "B", count: 60)),
        Verse(id: "C.1.1", book: "C", bookCode: "C", chapter: 1, verse: 1, text: String(repeating: "C", count: 60)),
    ]

    func testSameLocalDayIsStable() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Chicago")!
        let morning = Date(timeIntervalSince1970: 1_725_191_400)
        let evening = morning.addingTimeInterval(10 * 60 * 60)
        let selector = DailyVerseSelector()
        XCTAssertEqual(selector.verse(for: morning, calendar: calendar, from: verses), selector.verse(for: evening, calendar: calendar, from: verses))
    }

    func testTimezoneUsesLocalCalendarDate() {
        let date = ISO8601DateFormatter().date(from: "2026-07-14T01:00:00Z")!
        var chicago = Calendar(identifier: .gregorian)
        chicago.timeZone = TimeZone(identifier: "America/Chicago")!
        var tokyo = Calendar(identifier: .gregorian)
        tokyo.timeZone = TimeZone(identifier: "Asia/Tokyo")!
        let selector = DailyVerseSelector()
        let chicagoAgain = selector.verse(for: date, calendar: chicago, from: verses)
        XCTAssertEqual(chicagoAgain, selector.verse(for: date, calendar: chicago, from: verses))
        XCTAssertNotEqual(chicago.dateComponents([.day], from: date), tokyo.dateComponents([.day], from: date))
    }

    func testSelectionVariesAcrossCalendarDays() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let selectedIDs = Set((0..<31).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: start)!
            return DailyVerseSelector().verse(for: date, calendar: calendar, from: verses).id
        })

        XCTAssertGreaterThan(selectedIDs.count, 1)
    }

    func testEveryConsecutiveDayUsesADifferentVerse() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Chicago")!
        let start = calendar.date(from: DateComponents(year: 2026, month: 1, day: 1))!
        let selector = DailyVerseSelector()
        var previousID: String?

        for offset in 0..<5_000 {
            let date = calendar.date(byAdding: .day, value: offset, to: start)!
            let currentID = selector.verse(for: date, calendar: calendar, from: verses).id
            XCTAssertNotEqual(currentID, previousID, "Repeated verse after day offset \(offset)")
            previousID = currentID
        }
    }

    func testRandomSelectionHonorsExclusions() {
        var generator = SeededGenerator(seed: 42)
        let result = DailyVerseSelector().randomVerse(from: verses, excluding: ["A.1.1", "B.1.1"], using: &generator)
        XCTAssertEqual(result.id, "C.1.1")
    }
}

final class BibleRepositoryTests: XCTestCase {
    func testDecodesValidResource() throws {
        let verse = Verse(id: "JHN.1.1", book: "John", bookCode: "JHN", chapter: 1, verse: 1, text: "In the beginning was the Word, and the Word was with God, and the Word was God.")
        let resource = BibleResource(schemaVersion: 1, translation: "World English Bible", translationAbbreviation: "WEB", source: "test", license: "Public Domain", verses: [verse])
        let repository = try BibleRepository(data: JSONEncoder().encode(resource))
        XCTAssertEqual(repository.verses, [verse])
    }

    func testRejectsDuplicateIdentifiers() throws {
        let verse = Verse(id: "JHN.1.1", book: "John", bookCode: "JHN", chapter: 1, verse: 1, text: "In the beginning was the Word, and the Word was with God, and the Word was God.")
        let resource = BibleResource(schemaVersion: 1, translation: "WEB", translationAbbreviation: "WEB", source: "test", license: "Public Domain", verses: [verse, verse])
        XCTAssertThrowsError(try BibleRepository(data: JSONEncoder().encode(resource)))
    }
}

@MainActor
final class AppearanceTests: XCTestCase {
    func testAppModelRefreshesAcrossLocalMidnight() throws {
        let verses = [
            Verse(id: "PSA.23.1", book: "Psalms", bookCode: "PSA", chapter: 23, verse: 1, text: "The LORD is my shepherd; I shall lack nothing."),
            Verse(id: "PSA.46.10", book: "Psalms", bookCode: "PSA", chapter: 46, verse: 10, text: "Be still, and know that I am God."),
            Verse(id: "MIC.6.8", book: "Micah", bookCode: "MIC", chapter: 6, verse: 8, text: "Act justly, love mercy, and walk humbly with your God."),
        ]
        let resource = BibleResource(schemaVersion: 1, translation: "WEB", translationAbbreviation: "WEB", source: "test", license: "Public Domain", verses: verses)
        let repository = try BibleRepository(data: JSONEncoder().encode(resource))
        let defaults = UserDefaults(suiteName: "SelahMidnightTests.\(UUID().uuidString)")!
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/Chicago")!
        let beforeMidnight = calendar.date(from: DateComponents(year: 2026, month: 7, day: 22, hour: 23, minute: 59))!
        let afterMidnight = calendar.date(byAdding: .minute, value: 2, to: beforeMidnight)!
        let model = AppModel(repository: repository, persistence: PersistenceStore(defaults: defaults), now: beforeMidnight, calendar: calendar)
        let originalID = model.todayVerse.id

        model.refreshTodayIfNeeded(now: afterMidnight, calendar: calendar)

        XCTAssertNotEqual(model.todayVerse.id, originalID)
        XCTAssertEqual(model.displayedVerse, model.todayVerse)
        XCTAssertTrue(model.isShowingToday)
    }

    func testFavoriteCanBeRemovedDirectly() throws {
        let verse = Verse(id: "PSA.23.1", book: "Psalms", bookCode: "PSA", chapter: 23, verse: 1, text: "The LORD is my shepherd; I shall lack nothing.")
        let resource = BibleResource(schemaVersion: 1, translation: "WEB", translationAbbreviation: "WEB", source: "test", license: "Public Domain", verses: [verse])
        let repository = try BibleRepository(data: JSONEncoder().encode(resource))
        let defaults = UserDefaults(suiteName: "SelahFavoriteTests.\(UUID().uuidString)")!
        let model = AppModel(repository: repository, persistence: PersistenceStore(defaults: defaults))

        model.toggleFavorite()
        XCTAssertEqual(model.favoriteVerses, [verse])
        model.removeFavorite(verse)
        XCTAssertTrue(model.favoriteVerses.isEmpty)
    }

    func testAppearanceAppliesImmediatelyAndPersists() throws {
        defer { NSApplication.shared.appearance = nil }
        let verse = Verse(id: "PSA.1.1", book: "Psalms", bookCode: "PSA", chapter: 1, verse: 1, text: "Blessed is the man who doesn’t walk in the counsel of the wicked, nor stand on the path of sinners.")
        let resource = BibleResource(schemaVersion: 1, translation: "WEB", translationAbbreviation: "WEB", source: "test", license: "Public Domain", verses: [verse])
        let repository = try BibleRepository(data: JSONEncoder().encode(resource))
        let defaults = UserDefaults(suiteName: "SelahAppearanceTests.\(UUID().uuidString)")!
        let store = PersistenceStore(defaults: defaults)
        let model = AppModel(repository: repository, persistence: store)

        model.setAppearance(.dark)
        XCTAssertEqual(NSApplication.shared.appearance?.name, .darkAqua)
        XCTAssertEqual(store.load().appearance, .dark)

        model.setAppearance(.light)
        XCTAssertEqual(NSApplication.shared.appearance?.name, .aqua)
        XCTAssertEqual(store.load().appearance, .light)
    }

    func testTransientNoticeDismissesAutomatically() async throws {
        let verse = Verse(id: "PSA.46.10", book: "Psalms", bookCode: "PSA", chapter: 46, verse: 10, text: "Be still, and know that I am God. I will be exalted among the nations and in the earth.")
        let resource = BibleResource(schemaVersion: 1, translation: "WEB", translationAbbreviation: "WEB", source: "test", license: "Public Domain", verses: [verse])
        let repository = try BibleRepository(data: JSONEncoder().encode(resource))
        let defaults = UserDefaults(suiteName: "SelahNoticeTests.\(UUID().uuidString)")!
        let model = AppModel(
            repository: repository,
            persistence: PersistenceStore(defaults: defaults),
            noticeDurationNanoseconds: 10_000_000
        )

        model.copyVerse()
        XCTAssertEqual(model.notice, "Copied to clipboard")
        try await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertNil(model.notice)
    }
}

@MainActor
final class PersistenceStoreTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "SelahTests.\(UUID().uuidString)")!
        defaults.removePersistentDomain(forName: defaultsSuiteName)
    }

    func testRoundTripAndDeduplication() {
        let store = PersistenceStore(defaults: defaults)
        var preferences = AppPreferences()
        preferences.favoriteIDs = ["A", "A", "B"]
        store.save(preferences)
        XCTAssertEqual(store.load().favoriteIDs, ["A", "B"])
    }

    func testCorruptDataRecoversDefaults() {
        defaults.set(Data("not-json".utf8), forKey: "selah.preferences")
        let store = PersistenceStore(defaults: defaults)
        XCTAssertEqual(store.load(), AppPreferences())
        XCTAssertTrue(store.recoveredCorruptData)
    }

    private var defaultsSuiteName: String { defaults.volatileDomainNames.first ?? "" }
}

private struct SeededGenerator: RandomNumberGenerator {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state = state &* 6_364_136_223_846_793_005 &+ 1
        return state
    }
}
