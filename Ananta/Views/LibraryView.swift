import SwiftUI

struct LibraryView: View {
    @Environment(LearningStore.self) private var store
    @State private var category = "All"
    @State private var query = ""
    @State private var offlineOnly = false
    private var categories: [String] { ["All"] + Array(Set(store.books.map(\.category))).sorted() }
    private var filtered: [SacredBook] {
        store.books.filter { book in
            (category == "All" || book.category == category) && (!offlineOnly || book.isReadable) &&
            (query.isEmpty || "\(book.title) \(book.subtitle) \(book.tradition)".localizedStandardContains(query))
        }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                PageHeading(eyebrow: "The library", title: "Words across millennia.", subtitle: "Find your way through the texts. Read slowly. Follow the questions that stay with you.")
                HStack(spacing: 22) {
                    libraryStat("\(store.books.count)", "works & collections")
                    Rectangle().fill(Palette.line).frame(width: 1, height: 34)
                    libraryStat("\(store.books.filter(\.isReadable).count)", "available offline")
                    Spacer()
                    Image(systemName: "books.vertical").font(.system(size: 30, weight: .ultraLight)).foregroundStyle(Palette.gold)
                }.padding(20).background(Palette.paleGold.opacity(0.28), in: RoundedRectangle(cornerRadius: 20))
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 9) { ForEach(categories, id: \.self) { item in Button { category = item } label: { Pill(title: item, selected: category == item) }.buttonStyle(.plain) } }
                }
                Toggle(isOn: $offlineOnly) { Label("Ready to read offline", systemImage: "arrow.down.circle").font(.subheadline).foregroundStyle(Palette.muted) }.tint(Palette.ink)
                if filtered.isEmpty { EmptyState(symbol: "books.vertical", title: "No matching books", detail: "Try another title or category, or include catalog guides.") }
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 155), spacing: 18)], alignment: .leading, spacing: 26) {
                    ForEach(filtered) { book in
                        NavigationLink(value: Route.book(book.id)) {
                            VStack(alignment: .leading, spacing: 11) {
                                BookCover(book: book).frame(height: 215)
                                Text(book.title).font(.system(.headline, design: .serif)).foregroundStyle(Palette.ink).lineLimit(2)
                                Text(book.isReadable ? book.coverage : "Reading guide").font(.caption).foregroundStyle(Palette.muted)
                                if book.isReadable { Label("Offline", systemImage: "checkmark.circle.fill").font(.system(size: 10, weight: .medium)).foregroundStyle(Palette.ink.opacity(0.75)) }
                            }.frame(maxWidth: .infinity, alignment: .topLeading)
                        }.buttonStyle(.plain).accessibilityIdentifier("book-\(book.id)")
                    }
                }
            }.padding(24).frame(maxWidth: 900).frame(maxWidth: .infinity)
        }.readingPage().navigationTitle("Library").navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Find a title or tradition")
    }
    private func libraryStat(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.editorial(28)).foregroundStyle(Palette.ink)
            Text(label).font(.caption2).foregroundStyle(Palette.muted)
        }
    }
}

struct BookCover: View {
    let book: SacredBook
    var body: some View {
        ZStack {
            Palette.color(for: book.category)
            LinearGradient(colors: [.black.opacity(0.03), .black.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing)
            HStack(spacing: 0) { Color.black.opacity(0.16).frame(width: 7); Color.white.opacity(0.1).frame(width: 2); Spacer() }
            RoundedRectangle(cornerRadius: 2).stroke(Palette.paleGold.opacity(0.45), lineWidth: 0.7).padding(13)
            VStack(spacing: 13) {
                Text(book.category.uppercased()).font(.system(size: 8, weight: .medium)).tracking(1.7)
                Spacer(minLength: 0)
                Image(systemName: book.symbol).font(.system(size: 31, weight: .ultraLight))
                Text(book.title).font(.editorial(20)).multilineTextAlignment(.center).lineLimit(3).minimumScaleFactor(0.7).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                HStack(spacing: 6) { Rectangle().frame(width: 18, height: 0.6); Circle().frame(width: 3, height: 3); Rectangle().frame(width: 18, height: 0.6) }
                Text("HINDU APP LIBRARY").font(.system(size: 7, weight: .medium)).tracking(1.2).lineLimit(1).minimumScaleFactor(0.8)
            }.foregroundStyle(Palette.paleGold).padding(25)
        }.clipShape(.rect(topLeadingRadius: 3, bottomLeadingRadius: 3, bottomTrailingRadius: 12, topTrailingRadius: 12))
            .shadow(color: Palette.ink.opacity(0.12), radius: 9, x: 3, y: 6).accessibilityHidden(true)
    }
}

struct CompactBookRow: View {
    let book: SacredBook
    var body: some View {
        NavigationLink(value: Route.book(book.id)) {
            HStack(spacing: 13) {
                Image(systemName: book.symbol).font(.title3).foregroundStyle(Palette.color(for: book.category)).frame(width: 44, height: 49).background(Palette.line.opacity(0.4), in: RoundedRectangle(cornerRadius: 9))
                VStack(alignment: .leading, spacing: 5) {
                    Text(book.title).font(.system(.headline, design: .serif)).foregroundStyle(Palette.ink)
                    Text(book.coverage).font(.caption).foregroundStyle(Palette.muted)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption2).foregroundStyle(Palette.muted)
            }.padding(14).background(Palette.card, in: RoundedRectangle(cornerRadius: 16))
        }.buttonStyle(.plain)
    }
}

struct BookDetailView: View {
    @Environment(LearningStore.self) private var store
    let book: SacredBook
    @State private var chapterQuery = ""
    private var chapters: [Chapter] { book.chapters.filter { chapterQuery.isEmpty || $0.title.localizedStandardContains(chapterQuery) } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                HStack(alignment: .center, spacing: 22) {
                    BookCover(book: book).frame(width: 128, height: 185)
                    VStack(alignment: .leading, spacing: 12) {
                        Eyebrow(text: book.category)
                        Text(book.title).font(.editorial(29)).foregroundStyle(Palette.ink)
                        Text(book.subtitle).font(.subheadline).foregroundStyle(Palette.muted)
                        Text(book.coverage).font(.caption.weight(.medium)).foregroundStyle(Palette.ink).padding(9).background(Palette.paleGold.opacity(0.5), in: Capsule())
                    }
                }.frame(maxWidth: .infinity, alignment: .leading)
                if let first = book.chapters.first {
                    NavigationLink(value: Route.reader(book: book.id, chapter: first.id, passage: nil)) {
                        PrimaryLabel(title: "Begin reading", symbol: "book")
                    }.buttonStyle(.plain).accessibilityIdentifier("beginReading")
                }
                ArticleBlock(section: .init(title: "Before you begin", text: book.summary))
                ArticleBlock(section: .init(title: "Why read this?", text: book.whyRead))
                VStack(alignment: .leading, spacing: 12) {
                    Eyebrow(text: "This edition")
                    Text(book.translation).font(.subheadline.weight(.semibold)).foregroundStyle(Palette.ink)
                    Text(book.tradition).font(.footnote).foregroundStyle(Palette.muted)
                    Text(book.license).font(.footnote).foregroundStyle(Palette.muted).lineSpacing(4)
                    if let url = URL(string: book.sourceURL) { Link("Visit the source ↗", destination: url).font(.subheadline.weight(.medium)) }
                }.padding(20).background(Palette.paleGold.opacity(0.23), in: RoundedRectangle(cornerRadius: 18))
                if !book.relatedEntityIDs.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeading(title: "People & ideas")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack { ForEach(book.relatedEntityIDs, id: \.self) { id in if let entry = store.entity(id) { EntityChip(entry: entry) } } }
                        }
                    }
                }
                if book.isReadable {
                    SectionHeading(title: "Contents", trailing: "\(book.chapters.count) sections")
                    if book.chapters.count > 25 {
                        TextField("Filter contents", text: $chapterQuery).textFieldStyle(.roundedBorder).accessibilityLabel("Filter book contents")
                    }
                    LazyVStack(spacing: 0) {
                        ForEach(chapters) { chapter in
                            NavigationLink(value: Route.reader(book: book.id, chapter: chapter.id, passage: nil)) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(chapter.title).font(.system(.body, design: .serif)).foregroundStyle(Palette.ink)
                                        if !chapter.summary.isEmpty { Text(chapter.summary).font(.caption).foregroundStyle(Palette.muted).lineLimit(2) }
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.right").font(.caption).foregroundStyle(Palette.gold)
                                }.padding(.vertical, 16).contentShape(Rectangle())
                            }.buttonStyle(.plain)
                            Divider().overlay(Palette.line)
                        }
                    }
                } else {
                    EmptyState(symbol: "arrow.up.right.square", title: "A guide for further reading", detail: "This work is in the catalog. Its full text is not bundled in this edition. Follow the source link to explore an available edition.")
                }
            }.padding(24).frame(maxWidth: 740).frame(maxWidth: .infinity)
        }.readingPage().navigationTitle(book.title).navigationBarTitleDisplayMode(.inline)
            .toolbar { SaveButton(id: "book:\(book.id)", title: book.title, subtitle: book.translation, route: .book(book.id)) }
    }
}
