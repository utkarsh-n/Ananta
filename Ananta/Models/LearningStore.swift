import Foundation
import Observation

@MainActor @Observable
final class LearningStore {
    private(set) var books: [SacredBook] = []
    private(set) var entries: [WikiEntry] = []
    private(set) var lessons: [Lesson] = []
    private(set) var completedLessons: Set<String> = []
    private(set) var saved: [SavedItem] = []
    private(set) var lastRead: ReadingPosition?
    private(set) var isLoaded = false
    private(set) var loadError: String?
    var fontScale: Double = 1 { didSet { preferences.set(fontScale, forKey: "reader.fontScale") } }
    var readerSepia = true { didSet { preferences.set(readerSepia, forKey: "reader.sepia") } }

    @ObservationIgnored private let preferences: UserDefaults
    @ObservationIgnored private var bookLookup: [String: SacredBook] = [:]
    @ObservationIgnored private var entityLookup: [String: WikiEntry] = [:]

    init(preferences: UserDefaults = .standard) {
        self.preferences = preferences
        completedLessons = Set(preferences.stringArray(forKey: "completedLessons") ?? [])
        if let data = preferences.data(forKey: "savedItems"), let values = try? JSONDecoder().decode([SavedItem].self, from: data) { saved = values }
        if let data = preferences.data(forKey: "lastRead") { lastRead = try? JSONDecoder().decode(ReadingPosition.self, from: data) }
        if preferences.object(forKey: "reader.fontScale") != nil { fontScale = preferences.double(forKey: "reader.fontScale") }
        if preferences.object(forKey: "reader.sepia") != nil { readerSepia = preferences.bool(forKey: "reader.sepia") }
    }

    func load() async {
        guard !isLoaded else { return }
        loadError = nil
        do {
            let content = try await Task.detached(priority: .userInitiated) { try ContentBundle.load() }.value
            books = content.books
            entries = content.entries
            lessons = content.lessons.sorted { $0.number < $1.number }
            bookLookup = Dictionary(uniqueKeysWithValues: books.map { ($0.id, $0) })
            entityLookup = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
            isLoaded = true
        } catch { loadError = error.localizedDescription }
    }

    func book(_ id: String) -> SacredBook? { bookLookup[id] }
    func entity(_ id: String) -> WikiEntry? { entityLookup[id] }
    func lesson(_ id: String) -> Lesson? { lessons.first { $0.id == id } }
    var nextLesson: Lesson? { lessons.first { !completedLessons.contains($0.id) } }
    var progress: Double { lessons.isEmpty ? 0 : Double(completedLessons.intersection(Set(lessons.map(\.id))).count) / Double(lessons.count) }

    func complete(_ lesson: Lesson) {
        completedLessons.insert(lesson.id)
        preferences.set(Array(completedLessons), forKey: "completedLessons")
    }

    func isSaved(_ id: String) -> Bool { saved.contains { $0.id == id } }

    func toggleSave(id: String, title: String, subtitle: String, route: Route) {
        if isSaved(id) { saved.removeAll { $0.id == id } }
        else { saved.insert(SavedItem(id: id, title: title, subtitle: subtitle, route: route, savedAt: Date()), at: 0) }
        if let data = try? JSONEncoder().encode(saved) { preferences.set(data, forKey: "savedItems") }
    }

    func remember(book: SacredBook, chapter: Chapter, passage: String? = nil) {
        lastRead = ReadingPosition(bookID: book.id, chapterID: chapter.id, passageID: passage, title: book.title)
        if let data = try? JSONEncoder().encode(lastRead) { preferences.set(data, forKey: "lastRead") }
    }
}
