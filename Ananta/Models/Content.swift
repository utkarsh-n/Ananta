import Foundation

struct SourceLink: Codable, Hashable {
    let title: String
    let url: String
}

struct ArticleSection: Codable, Hashable {
    let title: String
    let text: String
}

struct Passage: Codable, Identifiable, Hashable {
    let id: String
    let reference: String
    let text: String
}

struct Chapter: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let passages: [Passage]
}

struct SacredBook: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let category: String
    let tradition: String
    let summary: String
    let whyRead: String
    let translation: String
    let sourceURL: String
    let license: String
    let coverage: String
    let symbol: String
    let chapters: [Chapter]
    let relatedEntityIDs: [String]

    var isReadable: Bool { chapters.contains { !$0.passages.isEmpty } }
    var passageCount: Int { chapters.reduce(0) { $0 + $1.passages.count } }
}

struct WikiEntry: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let sanskrit: String
    let kind: String
    let subtitle: String
    let summary: String
    let body: [ArticleSection]
    let traditions: [String]
    let aliases: [String]
    let relatedIDs: [String]
    let bookIDs: [String]
    let sources: [SourceLink]
    let symbol: String
}

struct Lesson: Codable, Identifiable, Hashable {
    let id: String
    let number: Int
    let title: String
    let subtitle: String
    let minutes: Int
    let sections: [ArticleSection]
    let keyTerms: [String]
    let bookIDs: [String]
    let question: String
    let answers: [String]
    let correctAnswer: Int
    let explanation: String
    let sources: [SourceLink]
}

enum Route: Hashable, Codable {
    case book(String)
    case reader(book: String, chapter: String, passage: String?)
    case entity(String)
    case lesson(String)
}

struct SavedItem: Codable, Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let route: Route
    let savedAt: Date
}

struct ReadingPosition: Codable {
    let bookID: String
    let chapterID: String
    let passageID: String?
    let title: String
}

struct ContentBundle {
    let books: [SacredBook]
    let entries: [WikiEntry]
    let lessons: [Lesson]

    static func load(bundle: Bundle = .main) throws -> ContentBundle {
        func decode<T: Decodable>(_ name: String) throws -> T {
            guard let url = bundle.url(forResource: name, withExtension: "json") else {
                throw CocoaError(.fileNoSuchFile, userInfo: [NSLocalizedDescriptionKey: "Missing content: \(name).json"])
            }
            return try JSONDecoder().decode(T.self, from: Data(contentsOf: url))
        }
        return try ContentBundle(books: decode("library"), entries: decode("knowledge"), lessons: decode("lessons"))
    }
}
