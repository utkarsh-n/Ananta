import SwiftUI

struct ReaderView: View {
    @Environment(LearningStore.self) private var store
    let book: SacredBook
    let initialChapterID: String
    let initialPassageID: String?
    @State private var selectedChapterID = ""
    @State private var showContents = false
    @State private var showAppearance = false
    @State private var find = ""
    @State private var showFind = false
    @State private var matchIndex = 0
    @State private var selectedEntry: WikiEntry?
    @State private var showGlossary = false
    private var chapter: Chapter { book.chapters.first { $0.id == selectedChapterID } ?? book.chapters.first { $0.id == initialChapterID } ?? book.chapters[0] }
    private var chapterIndex: Int { book.chapters.firstIndex { $0.id == chapter.id } ?? 0 }
    private var matches: [Passage] { find.isEmpty ? [] : chapter.passages.filter { $0.text.localizedStandardContains(find) || $0.reference.localizedStandardContains(find) } }

    var body: some View {
        @Bindable var store = store
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 25) {
                    VStack(alignment: .leading, spacing: 14) {
                        Eyebrow(text: "\(book.title) · \(chapterIndex + 1) of \(book.chapters.count)")
                        Text(chapter.title).font(.system(.largeTitle, design: .serif)).foregroundStyle(Palette.ink)
                        Text(book.translation).font(.caption).foregroundStyle(Palette.muted)
                        Text("Linked names and ideas open the atlas.").font(.caption2).foregroundStyle(Palette.gold)
                        if !chapter.summary.isEmpty { Text(chapter.summary).font(.subheadline).foregroundStyle(Palette.muted).lineSpacing(4) }
                        Rectangle().fill(Palette.gold).frame(width: 40, height: 2).padding(.top, 6)
                    }.id("chapterTop")
                    ForEach(chapter.passages) { passage in
                        passageView(passage)
                            .id(passage.id)
                            .onAppear { store.remember(book: book, chapter: chapter, passage: passage.id) }
                    }
                    HStack {
                        if chapterIndex > 0 {
                            Button { selectChapter(book.chapters[chapterIndex - 1].id) } label: { Label("Previous", systemImage: "arrow.left") }
                        }
                        Spacer()
                        if chapterIndex + 1 < book.chapters.count {
                            Button { selectChapter(book.chapters[chapterIndex + 1].id) } label: { Label("Next section", systemImage: "arrow.right") }
                        }
                    }.font(.subheadline.weight(.semibold)).padding(.vertical, 22)
                    Text("\(book.coverage) · \(book.translation)").font(.caption2).foregroundStyle(Palette.muted)
                }.padding(26).frame(maxWidth: 740).frame(maxWidth: .infinity)
            }
            .background(store.readerSepia ? Palette.paper : Color.white)
            .safeAreaInset(edge: .top) {
                if showFind {
                    VStack(spacing: 8) {
                        HStack {
                            TextField("Find in this section", text: $find).textFieldStyle(.roundedBorder).autocorrectionDisabled().accessibilityIdentifier("readerFindField")
                            Button { showFind = false; find = "" } label: { Image(systemName: "xmark.circle.fill") }.accessibilityLabel("Close find")
                        }
                        if !find.isEmpty {
                            HStack {
                                Text("\(matches.count) matching passages").font(.caption).foregroundStyle(Palette.muted)
                                Spacer()
                                Button("Next match") {
                                    guard !matches.isEmpty else { return }
                                    proxy.scrollTo(matches[matchIndex % matches.count].id, anchor: .top)
                                    matchIndex += 1
                                }.font(.caption.weight(.semibold)).disabled(matches.isEmpty)
                            }
                        }
                    }.padding(14).background(Palette.paper)
                }
            }
            .task {
                selectedChapterID = initialChapterID
                if let passageID = initialPassageID {
                    try? await Task.sleep(for: .milliseconds(200))
                    proxy.scrollTo(passageID, anchor: .top)
                } else { store.remember(book: book, chapter: chapter) }
            }
            .onChange(of: selectedChapterID) { _, _ in proxy.scrollTo("chapterTop", anchor: .top) }
            .onChange(of: find) { _, _ in matchIndex = 0 }
        }
        .navigationTitle(book.title).navigationBarTitleDisplayMode(.inline)
        .environment(\.openURL, OpenURLAction { url in
            guard url.scheme == "ananta", url.host == "atlas", let entry = store.entity(url.lastPathComponent) else { return .systemAction }
            selectedEntry = entry
            return .handled
        })
        .toolbarBackground(Palette.paper, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button { showContents = true } label: { Image(systemName: "list.bullet") }.accessibilityLabel("Table of contents")
                Menu {
                    Button("Find in section", systemImage: "magnifyingglass") { showFind.toggle() }
                    Button("Reading appearance", systemImage: "textformat.size") { showAppearance = true }
                    Button("People & ideas", systemImage: "point.3.connected.trianglepath.dotted") { showGlossary = true }
                    if let url = URL(string: book.sourceURL) { Link("Source edition", destination: url) }
                } label: { Image(systemName: "ellipsis.circle") }.accessibilityLabel("Reading options")
            }
        }
        .sheet(isPresented: $showContents) {
            NavigationStack {
                List(book.chapters) { item in
                    Button { selectChapter(item.id); showContents = false } label: {
                        HStack {
                            Text(item.title).foregroundStyle(Palette.ink)
                            Spacer()
                            if item.id == chapter.id { Image(systemName: "checkmark").foregroundStyle(Palette.gold) }
                        }
                    }.accessibilityIdentifier("readerChapter-\(item.id)")
                }.navigationTitle("Contents").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showContents = false } } }
            }
        }
        .sheet(isPresented: $showAppearance) {
            NavigationStack {
                Form {
                    Section("Text size") {
                        Slider(value: $store.fontScale, in: 0.85...1.5, step: 0.05).accessibilityLabel("Text size")
                        Text("Let understanding grow slowly.").font(.system(size: 19 * store.fontScale, design: .serif))
                    }
                    Toggle("Warm paper", isOn: $store.readerSepia)
                }.navigationTitle("Reading appearance").toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showAppearance = false } } }
            }.presentationDetents([.medium])
        }
        .sheet(item: $selectedEntry) { entry in
            NavigationStack {
                EntityDetailView(entry: entry).routeDestinations()
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { selectedEntry = nil } } }
            }
        }
        .sheet(isPresented: $showGlossary) {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        PageHeading(eyebrow: book.title, title: "People & ideas", subtitle: "A few companions for your reading. Follow a name to understand its context.")
                        ForEach(glossaryEntries) { entry in
                            NavigationLink(value: Route.entity(entry.id)) { AtlasRow(entry: entry) }.buttonStyle(.plain)
                        }
                    }.padding(24)
                }.readingPage().routeDestinations().navigationTitle("Reading companions").navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showGlossary = false } } }
            }
        }
    }

    private func selectChapter(_ id: String) { selectedChapterID = id; find = ""; matchIndex = 0 }

    private var glossaryEntries: [WikiEntry] {
        var ids = Set<String>()
        return (book.relatedEntityIDs + ["dharma", "karma", "atman", "brahman", "moksha"]).filter { ids.insert($0).inserted }.compactMap { store.entity($0) }
    }

    private func passageView(_ passage: Passage) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text(passage.reference).font(.caption2.weight(.medium)).foregroundStyle(Palette.gold)
                Spacer(minLength: 8)
                SaveButton(id: "passage:\(book.id):\(passage.id)", title: "\(book.title) · \(passage.reference)", subtitle: String(passage.text.prefix(140)), route: .reader(book: book.id, chapter: chapter.id, passage: passage.id))
                    .font(.caption).foregroundStyle(Palette.gold).frame(minWidth: 32, minHeight: 28)
            }
            Text(highlight(passage.text)).font(.custom("Georgia", size: 18 * store.fontScale, relativeTo: .body))
                .lineSpacing(9).foregroundStyle(Palette.ink).textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
        }.padding(.vertical, 2)
            .padding(.horizontal, passage.id == initialPassageID ? 13 : 0)
            .padding(.vertical, passage.id == initialPassageID ? 12 : 0)
            .background(passage.id == initialPassageID ? Palette.paleGold.opacity(0.25) : .clear, in: RoundedRectangle(cornerRadius: 12))
    }

    private func highlight(_ text: String) -> AttributedString {
        var result = AttributedString(text)
        for entry in glossaryEntries {
            for name in [entry.name] + entry.aliases where name.count >= 3 {
                guard let range = text.range(of: name, options: [.caseInsensitive, .diacriticInsensitive]) else { continue }
                let beforeIsLetter = range.lowerBound > text.startIndex && text[text.index(before: range.lowerBound)].isLetter
                let afterIsLetter = range.upperBound < text.endIndex && text[range.upperBound].isLetter
                guard !beforeIsLetter, !afterIsLetter,
                      let lower = AttributedString.Index(range.lowerBound, within: result),
                      let upper = AttributedString.Index(range.upperBound, within: result) else { continue }
                result[lower..<upper].link = URL(string: "ananta://atlas/\(entry.id)")
                break
            }
        }
        guard !find.isEmpty else { return result }
        var start = text.startIndex
        while start < text.endIndex, let range = text.range(of: find, options: [.caseInsensitive, .diacriticInsensitive], range: start..<text.endIndex) {
            if let lower = AttributedString.Index(range.lowerBound, within: result), let upper = AttributedString.Index(range.upperBound, within: result) {
                result[lower..<upper].backgroundColor = UIColor(Palette.paleGold)
            }
            start = range.upperBound
        }
        return result
    }
}
