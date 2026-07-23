import Foundation

struct AppPreferences: Codable, Equatable, Sendable {
    static let currentSchemaVersion = 1

    var schemaVersion = currentSchemaVersion
    var favoriteIDs: [String] = []
    var recentIDs: [String] = []
    var appearance: AppAppearance = .system
    var launchAtLogin = false
}

@MainActor
final class PersistenceStore {
    private let defaults: UserDefaults
    private let key = "selah.preferences"
    private(set) var recoveredCorruptData = false

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load() -> AppPreferences {
        guard let data = defaults.data(forKey: key) else { return AppPreferences() }
        do {
            var preferences = try JSONDecoder().decode(AppPreferences.self, from: data)
            guard preferences.schemaVersion <= AppPreferences.currentSchemaVersion else {
                throw CocoaError(.coderReadCorrupt)
            }
            preferences.schemaVersion = AppPreferences.currentSchemaVersion
            preferences.favoriteIDs = unique(preferences.favoriteIDs)
            preferences.recentIDs = Array(unique(preferences.recentIDs).prefix(50))
            return preferences
        } catch {
            recoveredCorruptData = true
            return AppPreferences()
        }
    }

    func save(_ preferences: AppPreferences) {
        guard let data = try? JSONEncoder().encode(preferences) else { return }
        defaults.set(data, forKey: key)
    }

    private func unique(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { seen.insert($0).inserted }
    }
}
