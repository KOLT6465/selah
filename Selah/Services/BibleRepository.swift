import Foundation

enum BibleRepositoryError: LocalizedError {
    case missingResource
    case invalidResource

    var errorDescription: String? {
        switch self {
        case .missingResource: "The Scripture library could not be found. Selah is using its recovery collection."
        case .invalidResource: "The Scripture library could not be read. Selah is using its recovery collection."
        }
    }
}

struct BibleRepository: Sendable {
    let resource: BibleResource
    let warning: String?

    init(bundle: Bundle = .main) {
        do {
            guard let url = bundle.url(forResource: "bible_web", withExtension: "json") else {
                throw BibleRepositoryError.missingResource
            }
            self = try Self(data: Data(contentsOf: url))
        } catch {
            resource = Self.fallbackResource
            warning = (error as? LocalizedError)?.errorDescription ?? BibleRepositoryError.invalidResource.errorDescription
        }
    }

    init(data: Data) throws {
        let decoded = try JSONDecoder().decode(BibleResource.self, from: data)
        guard decoded.schemaVersion == 1, !decoded.verses.isEmpty else {
            throw BibleRepositoryError.invalidResource
        }
        let unique = Set(decoded.verses.map(\.id))
        guard unique.count == decoded.verses.count else {
            throw BibleRepositoryError.invalidResource
        }
        resource = decoded
        warning = nil
    }

    var verses: [Verse] { resource.verses }

    private static let fallbackResource = BibleResource(
        schemaVersion: 1,
        translation: "World English Bible",
        translationAbbreviation: "WEB",
        source: "https://ebible.org/engwebp/",
        license: "Public Domain",
        verses: [
            Verse(id: "PSA.46.10", book: "Psalms", bookCode: "PSA", chapter: 46, verse: 10, text: "Be still, and know that I am God. I will be exalted among the nations. I will be exalted in the earth."),
            Verse(id: "MIC.6.8", book: "Micah", bookCode: "MIC", chapter: 6, verse: 8, text: "He has shown you, O man, what is good. What does Yahweh require of you, but to act justly, to love mercy, and to walk humbly with your God?"),
            Verse(id: "JHN.3.16", book: "John", bookCode: "JHN", chapter: 3, verse: 16, text: "For God so loved the world, that he gave his one and only Son, that whoever believes in him should not perish, but have eternal life."),
            Verse(id: "PHP.4.6", book: "Philippians", bookCode: "PHP", chapter: 4, verse: 6, text: "In nothing be anxious, but in everything, by prayer and petition with thanksgiving, let your requests be made known to God."),
            Verse(id: "ROM.12.12", book: "Romans", bookCode: "ROM", chapter: 12, verse: 12, text: "Rejoicing in hope, enduring in troubles, continuing steadfastly in prayer."),
        ]
    )
}
