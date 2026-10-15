import Foundation
import SQLite3

struct SearchHit: Identifiable, Hashable {
    let id: String
    let kind: String
    let title: String
    let subtitle: String
    let excerpt: String
    let bookID: String
    let chapterID: String
    let passageID: String

    var route: Route {
        switch kind {
        case "Passage": return .reader(book: bookID, chapter: chapterID, passage: passageID)
        case "Book": return .book(id)
        case "Lesson": return .lesson(id)
        default: return .entity(id)
        }
    }
}

struct SearchResponse {
    let hits: [SearchHit]
    let total: Int
}

enum SearchFailure: LocalizedError {
    case unavailable, query(String)
    var errorDescription: String? {
        switch self {
        case .unavailable: return "The offline search index could not be opened. Rebuild the app with its content resources."
        case .query(let message): return "Search could not finish: \(message)"
        }
    }
}

actor SearchEngine {
    static let shared = SearchEngine()
    private var database: OpaquePointer?
    private let databaseURL: URL?

    init(databaseURL: URL? = Bundle.main.url(forResource: "search", withExtension: "sqlite")) { self.databaseURL = databaseURL }
    deinit { if let database { sqlite3_close(database) } }

    static func expression(for query: String) -> String {
        query.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }.prefix(12)
            .map { "\"\($0)\"*" }.joined(separator: " AND ")
    }

    // ISO transliteration and common English spellings refer to the same names.
    // Keep SQL syntax construction separate from this small, explicit alias map.
    static func canonicalQuery(_ query: String) -> String {
        let aliases = ["krsna": "krishna", "siva": "shiva", "visnu": "vishnu", "laksmi": "lakshmi", "rsi": "rishi", "rsis": "rishis", "brhadaranyaka": "brihadaranyaka", "rta": "rita"]
        return query.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
            .map { aliases[$0] ?? $0 }.joined(separator: " ")
    }

    func search(_ query: String, scope: String = "All", limit: Int = 60) throws -> SearchResponse {
        let expression = Self.expression(for: Self.canonicalQuery(query))
        guard !expression.isEmpty else { return SearchResponse(hits: [], total: 0) }
        if database == nil {
            guard let databaseURL, sqlite3_open_v2(databaseURL.path, &database, SQLITE_OPEN_READONLY | SQLITE_OPEN_NOMUTEX, nil) == SQLITE_OK else { throw SearchFailure.unavailable }
        }
        let filter = scope == "All" ? "" : " AND kind = ?"
        let sql = "SELECT id, kind, title, subtitle, snippet(search, 4, '', '', ' … ', 36), bookID, chapterID, passageID FROM search WHERE search MATCH ?\(filter) ORDER BY bm25(search, 0, 0, 8, 3, 1, 0, 0, 0) LIMIT ?"
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &statement, nil) == SQLITE_OK else { throw failure() }
        defer { sqlite3_finalize(statement) }
        bind(expression, index: 1, to: statement)
        let limitIndex: Int32 = scope == "All" ? 2 : 3
        if scope != "All" { bind(scope, index: 2, to: statement) }
        sqlite3_bind_int(statement, limitIndex, Int32(limit))
        var hits: [SearchHit] = []
        var result = sqlite3_step(statement)
        while result == SQLITE_ROW {
            func column(_ index: Int32) -> String { sqlite3_column_text(statement, index).map { String(cString: $0) } ?? "" }
            hits.append(SearchHit(id: column(0), kind: column(1), title: column(2), subtitle: column(3), excerpt: column(4), bookID: column(5), chapterID: column(6), passageID: column(7)))
            result = sqlite3_step(statement)
        }
        guard result == SQLITE_DONE else { throw failure() }
        var count: OpaquePointer?
        guard sqlite3_prepare_v2(database, "SELECT count(*) FROM search WHERE search MATCH ?\(filter)", -1, &count, nil) == SQLITE_OK else { throw failure() }
        defer { sqlite3_finalize(count) }
        bind(expression, index: 1, to: count)
        if scope != "All" { bind(scope, index: 2, to: count) }
        let total = sqlite3_step(count) == SQLITE_ROW ? Int(sqlite3_column_int(count, 0)) : hits.count
        return SearchResponse(hits: hits, total: total)
    }

    private func bind(_ text: String, index: Int32, to statement: OpaquePointer?) {
        _ = text.withCString { sqlite3_bind_text(statement, index, $0, -1, unsafeBitCast(-1, to: sqlite3_destructor_type.self)) }
    }

    private func failure() -> SearchFailure { .query(database.map { String(cString: sqlite3_errmsg($0)) } ?? "Database unavailable") }
}
