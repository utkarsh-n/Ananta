import SwiftUI

struct SearchView: View {
    @Environment(LearningStore.self) private var store
    @State private var query = ""
    @State private var scope = "All"
    @State private var hits: [SearchHit] = []
    @State private var total = 0
    @State private var isSearching = false
    @State private var error: String?
    private let scopes = ["All", "Passage", "Book", "Atlas", "Lesson"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PageHeading(eyebrow: "Follow a question", title: "Seek, and connect.", subtitle: "Search the offline texts, atlas, and lessons together. Every result leads back to its context.")
                if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    discovery
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) { ForEach(scopes, id: \.self) { item in Button { scope = item } label: { Pill(title: item == "Passage" ? "Texts" : item == "Book" ? "Books" : item == "Lesson" ? "Lessons" : item, selected: scope == item) }.buttonStyle(.plain) } }
                    }
                    if isSearching {
                        ProgressView("Searching your library…").frame(maxWidth: .infinity).padding(30)
                    } else if let error {
                        EmptyState(symbol: "exclamationmark.magnifyingglass", title: "Search unavailable", detail: error)
                    } else if hits.isEmpty {
                        EmptyState(symbol: "magnifyingglass", title: "A question worth keeping", detail: "No matches for “\(query)”. Try a shorter word, an alternate spelling, or the All filter.")
                    } else {
                        SectionHeading(title: "\(total.formatted()) matches", trailing: total > hits.count ? "First \(hits.count) shown" : "Offline search")
                        LazyVStack(spacing: 0) {
                            ForEach(hits) { hit in
                                NavigationLink(value: hit.route) { resultRow(hit) }.buttonStyle(.plain)
                                Divider().overlay(Palette.line)
                            }
                        }
                        if total > hits.count { Text("Add another word to narrow your search. Results match all entered words, including word prefixes.").font(.caption).foregroundStyle(Palette.muted).lineSpacing(4) }
                    }
                }
            }.padding(24).frame(maxWidth: 780).frame(maxWidth: .infinity)
        }.readingPage().navigationTitle("Search").navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Try karma, Krishna, or creation")
            .autocorrectionDisabled()
            .task(id: "\(query)|\(scope)") { await runSearch() }
    }

    private var discovery: some View {
        VStack(alignment: .leading, spacing: 25) {
            VStack(alignment: .leading, spacing: 16) {
                SectionHeading(title: "Where will curiosity take you?")
                ForEach([("dharma", "How should we live?"), ("Krishna", "A teacher, a friend, a beloved deity"), ("creation", "How does a universe begin?"), ("self", "Who am I?")], id: \.0) { term, subtitle in
                    Button { query = term } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(term.capitalized).font(.system(.title3, design: .serif)).foregroundStyle(Palette.ink)
                                Text(subtitle).font(.caption).foregroundStyle(Palette.muted)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.left").font(.subheadline).foregroundStyle(Palette.gold)
                        }.padding(19).background(Palette.card, in: RoundedRectangle(cornerRadius: 17))
                    }.buttonStyle(.plain)
                }
            }
            VStack(alignment: .leading, spacing: 10) {
                Label("A library in your pocket", systemImage: "externaldrive.badge.checkmark").font(.subheadline.weight(.medium)).foregroundStyle(Palette.ink)
                Text("\(store.books.filter(\.isReadable).count) offline works and collections · \(store.entries.count) atlas entries · \(store.lessons.count) lessons").font(.caption).foregroundStyle(Palette.muted).lineSpacing(4)
                Text("Search is insensitive to case and diacritics. Historical spellings vary; try an alternate name when needed.").font(.caption).foregroundStyle(Palette.muted).lineSpacing(4)
            }.padding(20).background(Palette.paleGold.opacity(0.23), in: RoundedRectangle(cornerRadius: 18))
        }
    }

    private func resultRow(_ hit: SearchHit) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Eyebrow(text: hit.kind == "Passage" ? "Primary text" : hit.kind)
                Spacer()
                Image(systemName: "arrow.up.right").font(.caption2).foregroundStyle(Palette.gold)
            }
            Text(hit.title).font(.system(.title3, design: .serif)).foregroundStyle(Palette.ink)
            Text(hit.subtitle).font(.caption).foregroundStyle(Palette.muted).lineLimit(2)
            Text(hit.excerpt).font(.subheadline).foregroundStyle(Palette.ink.opacity(0.8)).lineSpacing(4).lineLimit(4)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 20).contentShape(Rectangle())
    }

    @MainActor private func runSearch() async {
        let cleaned = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { hits = []; total = 0; error = nil; isSearching = false; return }
        isSearching = true; error = nil
        do {
            try await Task.sleep(for: .milliseconds(220))
            try Task.checkCancellation()
            let response = try await SearchEngine.shared.search(cleaned, scope: scope)
            try Task.checkCancellation()
            hits = response.hits; total = response.total; isSearching = false
        } catch is CancellationError { }
        catch { if !Task.isCancelled { self.error = error.localizedDescription; isSearching = false } }
    }
}
