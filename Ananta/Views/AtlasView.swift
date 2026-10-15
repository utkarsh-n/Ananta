import SwiftUI

struct AtlasView: View {
    @Environment(LearningStore.self) private var store
    @State private var kind = "All"
    @State private var query = ""
    private let kinds = ["All", "Deity", "Epic figure", "Sage", "Concept"]
    private var entries: [WikiEntry] {
        store.entries.filter { entry in
            (kind == "All" || kind == entry.kind) &&
            (query.isEmpty || ([entry.name, entry.sanskrit, entry.subtitle] + entry.aliases).joined(separator: " ").localizedStandardContains(query))
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                PageHeading(eyebrow: "The living atlas", title: "Everything is connected.", subtitle: "Meet the deities, people, and ideas. Follow a connection and discover another story.")
                if let krishna = store.entity("krishna"), kind == "All", query.isEmpty {
                    NavigationLink(value: Route.entity(krishna.id)) {
                        HStack(spacing: 18) {
                            ZStack {
                                Circle().stroke(Palette.paleGold.opacity(0.5), lineWidth: 0.7).frame(width: 88, height: 88)
                                Circle().stroke(Palette.paleGold.opacity(0.2), lineWidth: 0.7).frame(width: 105, height: 105)
                                Image(systemName: krishna.symbol).font(.system(size: 36, weight: .ultraLight)).foregroundStyle(Palette.paleGold)
                                Circle().fill(Palette.paleGold).frame(width: 5, height: 5).offset(x: 43, y: -8)
                            }.frame(width: 112, height: 120)
                            VStack(alignment: .leading, spacing: 10) {
                                Eyebrow(text: "A thread to follow", color: Palette.paleGold)
                                Text("Krishna").font(.editorial(31)).foregroundStyle(.white)
                                Text("From the Bhagavad Gita to the worlds of devotion.").font(.caption).foregroundStyle(.white.opacity(0.75)).lineSpacing(4)
                                Label("Explore connections", systemImage: "arrow.up.right").font(.caption2.weight(.semibold)).foregroundStyle(Palette.paleGold)
                            }
                            Spacer(minLength: 0)
                        }.padding(20).background(Palette.ink, in: RoundedRectangle(cornerRadius: 23))
                    }.buttonStyle(.plain)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 9) { ForEach(kinds, id: \.self) { item in Button { kind = item } label: { Pill(title: item == "Deity" ? "Deities" : item == "Epic figure" ? "Narrative figures" : item == "Sage" ? "Sages" : item == "Concept" ? "Ideas" : item, selected: kind == item) }.buttonStyle(.plain) } }
                }
                SectionHeading(title: kind == "All" ? "People, deities & ideas" : kind == "Concept" ? "Ideas to understand" : "Explore the atlas", trailing: "\(entries.count) entries")
                if entries.isEmpty { EmptyState(symbol: "point.3.connected.trianglepath.dotted", title: "A new thread to follow", detail: "Try another name, an alternate spelling, or a different category.") }
                LazyVStack(spacing: 0) {
                    ForEach(entries) { entry in
                        NavigationLink(value: Route.entity(entry.id)) { AtlasRow(entry: entry) }.buttonStyle(.plain).accessibilityIdentifier("entity-\(entry.id)")
                        Divider().overlay(Palette.line).padding(.leading, 71)
                    }
                }
            }.padding(24).frame(maxWidth: 780).frame(maxWidth: .infinity)
        }.readingPage().navigationTitle("Atlas").navigationBarTitleDisplayMode(.inline).searchable(text: $query, prompt: "Names, ideas, alternate spellings")
    }
}

struct AtlasRow: View {
    let entry: WikiEntry
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: entry.symbol).font(.system(size: 25, weight: .ultraLight))
                .foregroundStyle(Palette.color(for: entry.kind)).frame(width: 55, height: 62)
                .background(Palette.color(for: entry.kind).opacity(0.09), in: RoundedRectangle(cornerRadius: 16))
            VStack(alignment: .leading, spacing: 5) {
                Text(entry.name).font(.system(.title3, design: .serif)).foregroundStyle(Palette.ink)
                Text(entry.subtitle).font(.caption).foregroundStyle(Palette.muted).lineLimit(2)
            }
            Spacer(minLength: 5)
            Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(Palette.gold)
        }.padding(.vertical, 15).contentShape(Rectangle())
    }
}

struct EntityDetailView: View {
    @Environment(LearningStore.self) private var store
    let entry: WikiEntry
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 27) {
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Eyebrow(text: entry.kind == "Epic figure" ? "Narrative figure" : entry.kind)
                        Spacer()
                        Image(systemName: entry.symbol).font(.system(size: 35, weight: .ultraLight)).foregroundStyle(Palette.gold)
                    }
                    Text(entry.name).font(.editorial(43)).foregroundStyle(Palette.ink)
                    if !entry.sanskrit.isEmpty { Text(entry.sanskrit).font(.title2).foregroundStyle(Palette.gold) }
                    Text(entry.subtitle).font(.system(.title3, design: .serif)).foregroundStyle(Palette.muted)
                    if !entry.aliases.isEmpty { Text("Also known as \(entry.aliases.joined(separator: ", "))").font(.caption).foregroundStyle(Palette.muted) }
                }
                Text(entry.summary).font(.body).lineSpacing(7).foregroundStyle(Palette.ink).textSelection(.enabled)
                if !entry.traditions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Eyebrow(text: "Traditions & contexts")
                        Text(entry.traditions.joined(separator: " · ")).font(.footnote).foregroundStyle(Palette.muted).lineSpacing(4)
                    }.padding(18).frame(maxWidth: .infinity, alignment: .leading).background(Palette.paleGold.opacity(0.24), in: RoundedRectangle(cornerRadius: 16))
                }
                ForEach(entry.body, id: \.title) { ArticleBlock(section: $0) }
                if !entry.relatedIDs.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeading(title: "A web of connections")
                        Text("Tap a name to follow the thread. These are thematic connections, not a family tree.").font(.caption).foregroundStyle(Palette.muted).lineSpacing(4)
                        ConnectionMap(entry: entry, related: entry.relatedIDs.compactMap { store.entity($0) })
                        ForEach(entry.relatedIDs, id: \.self) { id in
                            if let related = store.entity(id) {
                                NavigationLink(value: Route.entity(id)) { AtlasRow(entry: related) }.buttonStyle(.plain)
                            }
                        }
                    }
                }
                if !entry.bookIDs.isEmpty {
                    VStack(alignment: .leading, spacing: 13) {
                        SectionHeading(title: "Find them in the texts")
                        ForEach(entry.bookIDs, id: \.self) { id in if let book = store.book(id) { CompactBookRow(book: book) } }
                    }
                }
                Text("Hindu App atlas · Original introductory commentary").font(.caption).foregroundStyle(Palette.muted)
                SourceNotes(sources: entry.sources)
            }.padding(24).frame(maxWidth: 740).frame(maxWidth: .infinity)
        }.readingPage().navigationTitle(entry.name).navigationBarTitleDisplayMode(.inline)
            .toolbar { SaveButton(id: "entity:\(entry.id)", title: entry.name, subtitle: entry.subtitle, route: .entity(entry.id)) }
    }
}

struct ConnectionMap: View {
    let entry: WikiEntry
    let related: [WikiEntry]
    var nodes: [WikiEntry] { Array(related.prefix(6)) }
    var body: some View {
        GeometryReader { proxy in
            let center = CGPoint(x: proxy.size.width / 2, y: 150)
            let radius = min(proxy.size.width * 0.34, 116)
            ZStack {
                Canvas { context, _ in
                    context.stroke(Path(ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)), with: .color(Palette.paleGold.opacity(0.2)), style: StrokeStyle(lineWidth: 0.7, dash: [2, 6]))
                    for index in nodes.indices {
                        let point = position(index, center: center, radius: radius)
                        var path = Path(); path.move(to: center); path.addLine(to: point)
                        context.stroke(path, with: .color(Palette.paleGold.opacity(0.3)), lineWidth: 0.8)
                    }
                }.accessibilityHidden(true)
                VStack(spacing: 7) {
                    Image(systemName: entry.symbol).font(.system(size: 23, weight: .ultraLight))
                    Text(entry.name).font(.system(size: 12, weight: .medium, design: .serif)).lineLimit(1)
                }.foregroundStyle(Palette.paleGold).frame(width: 88, height: 88).background(Palette.ink, in: Circle())
                    .overlay(Circle().stroke(Palette.paleGold.opacity(0.6), lineWidth: 0.8)).position(center)
                ForEach(Array(nodes.enumerated()), id: \.element.id) { index, node in
                    NavigationLink(value: Route.entity(node.id)) {
                        VStack(spacing: 7) {
                            Image(systemName: node.symbol).font(.system(size: 17, weight: .light)).frame(width: 39, height: 39)
                                .background(Palette.night, in: Circle()).overlay(Circle().stroke(Palette.paleGold.opacity(0.6), lineWidth: 0.8))
                            Text(node.name).font(.system(size: 11, weight: .medium)).lineLimit(1).minimumScaleFactor(0.75)
                        }.foregroundStyle(Palette.paleGold).frame(width: 88)
                    }.buttonStyle(.plain).position(position(index, center: center, radius: radius)).accessibilityLabel("Explore \(node.name)")
                }
            }
        }.frame(height: 305).background(Palette.night, in: RoundedRectangle(cornerRadius: 22))
    }
    private func position(_ index: Int, center: CGPoint, radius: CGFloat) -> CGPoint {
        let angle = Double(index) * 2 * .pi / Double(max(nodes.count, 1)) - .pi / 2
        return CGPoint(x: center.x + CGFloat(cos(angle)) * radius, y: center.y + CGFloat(sin(angle)) * radius)
    }
}
