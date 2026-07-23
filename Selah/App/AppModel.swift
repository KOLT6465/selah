import AppKit
import Foundation
import ServiceManagement

@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var displayedVerse: Verse
    @Published private(set) var todayVerse: Verse
    @Published private(set) var preferences: AppPreferences
    @Published private(set) var notice: String?
    @Published private(set) var isShowingToday = true

    private let repository: BibleRepository
    private let selector: DailyVerseSelector
    private let persistence: PersistenceStore
    private let noticeDurationNanoseconds: UInt64
    private var todayKey: DateComponents
    private var noticeDismissTask: Task<Void, Never>?

    init(
        repository: BibleRepository = BibleRepository(),
        selector: DailyVerseSelector = DailyVerseSelector(),
        persistence: PersistenceStore = PersistenceStore(),
        now: Date = Date(),
        calendar: Calendar = .current,
        noticeDurationNanoseconds: UInt64 = 2_000_000_000
    ) {
        self.repository = repository
        self.selector = selector
        self.persistence = persistence
        self.noticeDurationNanoseconds = noticeDurationNanoseconds
        preferences = persistence.load()
        let daily = selector.verse(for: now, calendar: calendar, from: repository.verses)
        displayedVerse = daily
        todayVerse = daily
        todayKey = calendar.dateComponents([.year, .month, .day], from: now)
        let initialNotice = repository.warning ?? (persistence.recoveredCorruptData ? "Your saved preferences were reset safely." : nil)
        notice = nil
        recordRecent(daily.id)
        applyAppearance(preferences.appearance)
        if let initialNotice { presentNotice(initialNotice) }
    }

    var favoriteVerses: [Verse] {
        let lookup = Dictionary(uniqueKeysWithValues: repository.verses.map { ($0.id, $0) })
        return preferences.favoriteIDs.compactMap { lookup[$0] }
    }

    var isFavorite: Bool { preferences.favoriteIDs.contains(displayedVerse.id) }

    func toggleFavorite() {
        if let index = preferences.favoriteIDs.firstIndex(of: displayedVerse.id) {
            preferences.favoriteIDs.remove(at: index)
            presentNotice("Removed from saved verses")
        } else {
            preferences.favoriteIDs.insert(displayedVerse.id, at: 0)
            presentNotice("Saved for later")
        }
        persist()
    }

    func removeFavorite(_ verse: Verse) {
        guard preferences.favoriteIDs.contains(verse.id) else { return }
        preferences.favoriteIDs.removeAll { $0 == verse.id }
        persist()
        presentNotice("Removed from saved verses")
    }

    func showAnotherVerse() {
        var generator = SystemRandomNumberGenerator()
        let exclusions = Set(preferences.recentIDs.prefix(20)).union([displayedVerse.id])
        displayedVerse = selector.randomVerse(from: repository.verses, excluding: exclusions, using: &generator)
        isShowingToday = false
        recordRecent(displayedVerse.id)
    }

    func showToday() {
        displayedVerse = todayVerse
        isShowingToday = true
        recordRecent(displayedVerse.id)
    }

    func show(_ verse: Verse) {
        displayedVerse = verse
        isShowingToday = verse.id == todayVerse.id
        recordRecent(verse.id)
    }

    func refreshTodayIfNeeded(now: Date = Date(), calendar: Calendar = .current) {
        let key = calendar.dateComponents([.year, .month, .day], from: now)
        guard key != todayKey else { return }
        todayKey = key
        todayVerse = selector.verse(for: now, calendar: calendar, from: repository.verses)
        if isShowingToday { showToday() }
    }

    func copyVerse() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(displayedVerse.shareText, forType: .string)
        presentNotice("Copied to clipboard")
    }

    func setAppearance(_ appearance: AppAppearance) {
        preferences.appearance = appearance
        applyAppearance(appearance)
        persist()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
            preferences.launchAtLogin = enabled
            persist()
        } catch {
            preferences.launchAtLogin = SMAppService.mainApp.status == .enabled
            presentNotice("macOS couldn’t change the login setting. You can review Login Items in System Settings.")
        }
    }

    func dismissNotice() {
        noticeDismissTask?.cancel()
        notice = nil
    }

    func quit() { NSApplication.shared.terminate(nil) }

    private func recordRecent(_ id: String) {
        preferences.recentIDs.removeAll { $0 == id }
        preferences.recentIDs.insert(id, at: 0)
        preferences.recentIDs = Array(preferences.recentIDs.prefix(50))
        persist()
    }

    private func persist() { persistence.save(preferences) }

    private func presentNotice(_ message: String) {
        noticeDismissTask?.cancel()
        notice = message
        noticeDismissTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: self.noticeDurationNanoseconds)
            guard !Task.isCancelled else { return }
            self.notice = nil
        }
    }

    private func applyAppearance(_ appearance: AppAppearance) {
        NSApplication.shared.appearance = switch appearance {
        case .system: nil
        case .light: NSAppearance(named: .aqua)
        case .dark: NSAppearance(named: .darkAqua)
        }
    }
}
