import XCTest
@testable import Ananta

final class AnantaTests: XCTestCase {
    private func content() throws -> ContentBundle {
        try ContentBundle.load(bundle: .main)
    }

    private func searchEngine() throws -> SearchEngine {
        let url = try XCTUnwrap(Bundle.main.url(forResource: "search", withExtension: "sqlite"), "The offline FTS database must ship inside the app.")
        return SearchEngine(databaseURL: url)
    }

    func testBundledCorpusHasSubstantialReadableTextsAndHonestCoverage() throws {
        let corpus = try content()
        XCTAssertGreaterThanOrEqual(corpus.books.count, 40)
        XCTAssertGreaterThanOrEqual(corpus.books.filter(\.isReadable).count, 6)

        let gita = try XCTUnwrap(corpus.books.first { $0.id == "bhagavad-gita" })
        XCTAssertEqual(gita.chapters.count, 18, "Every Gita chapter must be readable offline.")
        XCTAssertTrue(gita.chapters.allSatisfy { !$0.passages.isEmpty })

        let yoga = try XCTUnwrap(corpus.books.first { $0.id == "yoga-sutras" })
        XCTAssertEqual(yoga.chapters.count, 4)
        XCTAssertEqual(yoga.chapters.map { $0.passages.filter { $0.id.hasSuffix("-sutra") }.count }, [51, 55, 55, 34], "Johnston's edition contains 195 aphorisms, with commentary kept separate.")

        let rigveda = try XCTUnwrap(corpus.books.first { $0.id == "rig-veda" })
        XCTAssertEqual(rigveda.chapters.count, 1_028)
        let mahabharata = try XCTUnwrap(corpus.books.first { $0.id == "mahabharata" })
        XCTAssertGreaterThan(mahabharata.chapters.count, 2_000)
        let ramayana = try XCTUnwrap(corpus.books.first { $0.id == "ramayana" })
        XCTAssertGreaterThan(ramayana.chapters.count, 400)
        XCTAssertEqual(ramayana.coverage, "Selected translation", "The omitted Uttara Kanda must not be presented as bundled.")
        let upanishads = try XCTUnwrap(corpus.books.first { $0.id == "upanishads" })
        XCTAssertEqual(upanishads.chapters.count, 3)
        XCTAssertEqual(upanishads.coverage, "Selected translation")

        let totalCharacters = corpus.books.reduce(0) { sum, book in
            sum + book.chapters.reduce(0) { subtotal, chapter in
                subtotal + chapter.passages.reduce(0) { $0 + $1.text.count }
            }
        }
        XCTAssertGreaterThan(totalCharacters, 5_000_000, "Catalog descriptions alone do not satisfy the offline reading promise.")
        for book in corpus.books where !book.isReadable {
            XCTAssertEqual(book.coverage, "Catalog guide", "\(book.id) has no offline passages and must be labeled as a guide.")
        }
    }

    func testEveryContentIdentifierIsUniqueAndEveryReadablePassageHasText() throws {
        let corpus = try content()
        assertUnique(corpus.books.map(\.id), kind: "book")
        assertUnique(corpus.entries.map(\.id), kind: "wiki entry")
        assertUnique(corpus.lessons.map(\.id), kind: "lesson")
        let chapters = corpus.books.flatMap(\.chapters)
        assertUnique(chapters.map(\.id), kind: "chapter")
        assertUnique(chapters.flatMap(\.passages).map(\.id), kind: "passage")
        for chapter in chapters {
            XCTAssertFalse(chapter.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, chapter.id)
            XCTAssertFalse(chapter.passages.isEmpty, "Empty chapter: \(chapter.id)")
            for passage in chapter.passages {
                XCTAssertFalse(passage.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, "Empty passage: \(passage.id)")
                XCTAssertFalse(passage.reference.isEmpty, "Uncitable passage: \(passage.id)")
            }
        }
    }

    func testAllWikiBookAndLessonLinksResolve() throws {
        let corpus = try content()
        let bookIDs = Set(corpus.books.map(\.id))
        let entryIDs = Set(corpus.entries.map(\.id))
        XCTAssertFalse(corpus.entries.isEmpty)
        XCTAssertFalse(corpus.lessons.isEmpty)
        for entry in corpus.entries {
            for relatedID in entry.relatedIDs {
                XCTAssertTrue(entryIDs.contains(relatedID), "Wiki \(entry.id) links to missing entry \(relatedID)")
            }
            for bookID in entry.bookIDs {
                XCTAssertTrue(bookIDs.contains(bookID), "Wiki \(entry.id) links to missing book \(bookID)")
            }
        }
        for book in corpus.books {
            for entityID in book.relatedEntityIDs {
                XCTAssertTrue(entryIDs.contains(entityID), "Book \(book.id) links to missing entry \(entityID)")
            }
        }
        for lesson in corpus.lessons {
            for termID in lesson.keyTerms {
                XCTAssertTrue(entryIDs.contains(termID), "Lesson \(lesson.id) links to missing key term \(termID)")
            }
            for bookID in lesson.bookIDs {
                XCTAssertTrue(bookIDs.contains(bookID), "Lesson \(lesson.id) links to missing book \(bookID)")
            }
        }
    }

    func testLessonsHaveValidQuizzesAndAnUnambiguousSequence() throws {
        let lessons = try content().lessons
        XCTAssertGreaterThanOrEqual(lessons.count, 6)
        XCTAssertEqual(Set(lessons.map(\.number)).count, lessons.count)
        for lesson in lessons {
            XCTAssertGreaterThan(lesson.minutes, 0, lesson.id)
            XCTAssertFalse(lesson.sections.isEmpty, lesson.id)
            XCTAssertFalse(lesson.question.isEmpty, lesson.id)
            XCTAssertGreaterThanOrEqual(lesson.answers.count, 2, lesson.id)
            XCTAssertTrue(lesson.answers.indices.contains(lesson.correctAnswer), "Invalid answer index for \(lesson.id)")
            XCTAssertFalse(lesson.answers.contains { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }, lesson.id)
            XCTAssertEqual(Set(lesson.answers).count, lesson.answers.count, "Duplicate choices in \(lesson.id)")
            XCTAssertFalse(lesson.explanation.isEmpty, "A new learner needs feedback for \(lesson.id)")
        }
    }

    func testEducationalContentHasUsableSourceLinks() throws {
        let corpus = try content()
        for book in corpus.books {
            assertWebURL(book.sourceURL, label: book.id)
            XCTAssertFalse(book.translation.isEmpty, book.id)
            XCTAssertFalse(book.license.isEmpty, book.id)
        }
        for entry in corpus.entries {
            XCTAssertFalse(entry.sources.isEmpty, "No source for wiki entry \(entry.id)")
            for source in entry.sources { assertWebURL(source.url, label: entry.id) }
        }
        for lesson in corpus.lessons {
            XCTAssertFalse(lesson.sources.isEmpty, "No source for lesson \(lesson.id)")
            for source in lesson.sources { assertWebURL(source.url, label: lesson.id) }
        }
    }

    func testSearchExpressionTreatsPunctuationAndFTSOperatorsAsText() {
        XCTAssertEqual(SearchEngine.expression(for: " \n\t "), "")
        XCTAssertEqual(SearchEngine.expression(for: "\"'(){}[]:*+-;\\"), "")
        XCTAssertEqual(SearchEngine.expression(for: "dharma"), "\"dharma\"*")
        XCTAssertEqual(SearchEngine.expression(for: "dharma OR karma"), "\"dharma\"* AND \"OR\"* AND \"karma\"*")
        XCTAssertEqual(SearchEngine.expression(for: "  dharma \"OR\" (karma) -śiva*  "), "\"dharma\"* AND \"OR\"* AND \"karma\"* AND \"śiva\"*")
        XCTAssertEqual(SearchEngine.expression(for: "Kṛṣṇa"), "\"Kṛṣṇa\"*")
        XCTAssertEqual(SearchEngine.expression(for: "dharma'); DROP TABLE search;--"), "\"dharma\"* AND \"DROP\"* AND \"TABLE\"* AND \"search\"*")
        let longQuery = (1...30).map { "word\($0)" }.joined(separator: " ")
        XCTAssertEqual(SearchEngine.expression(for: longQuery).components(separatedBy: " AND ").count, 12)
    }

    func testEmptySearchDoesNotRequireAnIndexAndMissingIndexFailsClearly() async throws {
        let engine = SearchEngine(databaseURL: nil)
        let empty = try await engine.search("\"()* : -")
        XCTAssertEqual(empty.total, 0)
        XCTAssertTrue(empty.hits.isEmpty)
        do {
            _ = try await engine.search("dharma")
            XCTFail("A missing database must surface a recoverable error.")
        } catch SearchFailure.unavailable {
            // Expected: this is distinct from a valid search with no results.
        }
    }

    func testOfflineSearchFindsDharmaAndPassageResultsNavigateToRealText() async throws {
        let corpus = try content()
        let engine = try searchEngine()
        let response = try await engine.search("dharma", scope: "Passage", limit: 8)
        XCTAssertGreaterThan(response.total, 0)
        XCTAssertFalse(response.hits.isEmpty)
        XCTAssertLessThanOrEqual(response.hits.count, 8)
        XCTAssertGreaterThanOrEqual(response.total, response.hits.count)
        for hit in response.hits {
            XCTAssertEqual(hit.kind, "Passage")
            XCTAssertFalse(hit.excerpt.isEmpty)
            guard case let .reader(bookID, chapterID, passageID) = hit.route else {
                XCTFail("A passage result must navigate to its reader location.")
                continue
            }
            let book = try XCTUnwrap(corpus.books.first { $0.id == bookID }, "Search points to missing book \(bookID)")
            let chapter = try XCTUnwrap(book.chapters.first { $0.id == chapterID }, "Search points to missing chapter \(chapterID)")
            let passage = try XCTUnwrap(chapter.passages.first { $0.id == passageID }, "Search points to missing passage \(passageID ?? "nil")")
            XCTAssertEqual(passage.id, hit.passageID)
        }
    }

    func testSearchScopesDiacriticsAndNoResultState() async throws {
        let engine = try searchEngine()
        let books = try await engine.search("Bhagavad", scope: "Book")
        XCTAssertFalse(books.hits.isEmpty)
        XCTAssertTrue(books.hits.allSatisfy { $0.kind == "Book" })
        XCTAssertTrue(books.hits.contains { $0.route == .book("bhagavad-gita") })

        let plain = try await engine.search("Krishna", limit: 200)
        let diacritics = try await engine.search("Kṛṣṇa", limit: 200)
        XCTAssertGreaterThan(plain.total, 0)
        XCTAssertEqual(plain.total, diacritics.total, "Beginners should find the same content without entering diacritics.")
        XCTAssertEqual(Set(plain.hits.map(\.id)), Set(diacritics.hits.map(\.id)))
        XCTAssertTrue(plain.hits.contains { $0.route == .entity("krishna") })

        let nothing = try await engine.search("qzxvnonexistentterm8675309")
        XCTAssertEqual(nothing.total, 0)
        XCTAssertTrue(nothing.hits.isEmpty)
        let punctuation = try await engine.search("dharma\" (karma):*")
        XCTAssertGreaterThanOrEqual(punctuation.total, punctuation.hits.count, "Punctuation must not produce an FTS parser error.")
    }

    @MainActor
    func testBookmarksPersistAllRouteTypesAndTogglingRemovesOnlyTheChosenItem() throws {
        let suite = "AnantaTests.bookmarks.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = LearningStore(preferences: defaults)
        let routes: [Route] = [.book("bhagavad-gita"), .reader(book: "bhagavad-gita", chapter: "bhagavad-gita-01", passage: "bhagavad-gita-01-p0001"), .entity("krishna"), .lesson("first-steps")]
        for (index, route) in routes.enumerated() {
            store.toggleSave(id: "saved-\(index)", title: "Title \(index)", subtitle: "Subtitle \(index)", route: route)
        }
        let restored = LearningStore(preferences: defaults)
        XCTAssertEqual(restored.saved.count, routes.count)
        for (index, route) in routes.enumerated() {
            let item = try XCTUnwrap(restored.saved.first { $0.id == "saved-\(index)" })
            XCTAssertEqual(item.route, route)
            XCTAssertEqual(item.title, "Title \(index)")
            XCTAssertTrue(restored.isSaved(item.id))
        }
        restored.toggleSave(id: "saved-1", title: "Unused", subtitle: "Unused", route: routes[1])
        let afterRemoval = LearningStore(preferences: defaults)
        XCTAssertFalse(afterRemoval.isSaved("saved-1"))
        XCTAssertEqual(afterRemoval.saved.count, 3)
        XCTAssertTrue(afterRemoval.isSaved("saved-0"))
    }

    @MainActor
    func testLessonCompletionPersistsAndNextLessonAdvancesWithoutDoubleCounting() async throws {
        let suite = "AnantaTests.lessons.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = LearningStore(preferences: defaults)
        await store.load()
        XCTAssertTrue(store.isLoaded, store.loadError ?? "Content was not loaded")
        let lesson = try XCTUnwrap(store.nextLesson)
        XCTAssertEqual(store.progress, 0)
        store.complete(lesson)
        store.complete(lesson)
        XCTAssertEqual(store.completedLessons, [lesson.id])
        XCTAssertEqual(store.progress, 1 / Double(store.lessons.count), accuracy: 0.000_001)
        XCTAssertNotEqual(store.nextLesson?.id, lesson.id)
        let restored = LearningStore(preferences: defaults)
        await restored.load()
        XCTAssertTrue(restored.completedLessons.contains(lesson.id))
        XCTAssertEqual(restored.progress, store.progress)
        XCTAssertEqual(restored.nextLesson?.id, store.nextLesson?.id)
        for item in restored.lessons { restored.complete(item) }
        XCTAssertEqual(restored.progress, 1)
        XCTAssertNil(restored.nextLesson)
    }

    @MainActor
    func testReadingPositionAndReaderPreferencesSurviveRelaunch() throws {
        let suite = "AnantaTests.reader.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let corpus = try content()
        let book = try XCTUnwrap(corpus.books.first { $0.id == "bhagavad-gita" })
        let chapter = try XCTUnwrap(book.chapters.first)
        let passage = try XCTUnwrap(chapter.passages.first)
        let store = LearningStore(preferences: defaults)
        XCTAssertNil(store.lastRead)
        XCTAssertEqual(store.fontScale, 1)
        XCTAssertTrue(store.readerSepia)
        store.fontScale = 1.3
        store.readerSepia = false
        store.remember(book: book, chapter: chapter, passage: passage.id)
        let restored = LearningStore(preferences: defaults)
        XCTAssertEqual(restored.fontScale, 1.3, accuracy: 0.000_001)
        XCTAssertFalse(restored.readerSepia)
        XCTAssertEqual(restored.lastRead?.bookID, book.id)
        XCTAssertEqual(restored.lastRead?.chapterID, chapter.id)
        XCTAssertEqual(restored.lastRead?.passageID, passage.id)
        XCTAssertEqual(restored.lastRead?.title, book.title)
    }

    private func assertUnique(_ ids: [String], kind: String, file: StaticString = #filePath, line: UInt = #line) {
        var seen = Set<String>()
        for id in ids {
            XCTAssertFalse(id.isEmpty, "Empty \(kind) ID", file: file, line: line)
            XCTAssertTrue(seen.insert(id).inserted, "Duplicate \(kind) ID: \(id)", file: file, line: line)
        }
    }

    private func assertWebURL(_ value: String, label: String, file: StaticString = #filePath, line: UInt = #line) {
        guard let url = URL(string: value), let host = url.host else {
            XCTFail("Malformed source URL for \(label): \(value)", file: file, line: line)
            return
        }
        XCTAssertFalse(host.isEmpty, label, file: file, line: line)
        XCTAssertTrue(["https", "http"].contains(url.scheme ?? ""), "Source for \(label) must open on the web", file: file, line: line)
    }
}
