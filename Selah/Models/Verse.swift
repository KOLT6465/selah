import Foundation

struct Verse: Codable, Hashable, Identifiable, Sendable {
    let id: String
    let book: String
    let bookCode: String
    let chapter: Int
    let verse: Int
    let text: String

    var reference: String { "\(book) \(chapter):\(verse)" }
    var shareText: String { "“\(text)”\n— \(reference) (WEB)" }
}

struct BibleResource: Codable, Sendable {
    let schemaVersion: Int
    let translation: String
    let translationAbbreviation: String
    let source: String
    let license: String
    let verses: [Verse]
}

enum AppAppearance: String, Codable, CaseIterable, Identifiable, Sendable {
    case system
    case light
    case dark

    var id: String { rawValue }
    var label: String { rawValue.capitalized }
}
