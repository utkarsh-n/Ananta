import SwiftUI

enum Palette {
    static let paper = Color(hex: 0xF5F1E9)
    static let card = Color(hex: 0xFFFCF6)
    static let ink = Color(hex: 0x213A37)
    static let muted = Color(hex: 0x65716B)
    static let gold = Color(hex: 0xA47136)
    static let paleGold = Color(hex: 0xE9D8B9)
    static let line = Color(hex: 0xDFDED2)
    static let night = Color(hex: 0x111E29)
    static let saffron = Color(hex: 0xB97143)

    static func color(for category: String) -> Color {
        switch category {
        case "Vedas", "Deity": return Color(hex: 0x426B61)
        case "Upanishads", "Concept": return Color(hex: 0x6F6B86)
        case "Epics", "Epic figure": return Color(hex: 0xAE7252)
        case "Puranas": return Color(hex: 0x677B8F)
        default: return Color(hex: 0x9A8251)
        }
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(.sRGB, red: Double((hex >> 16) & 255) / 255, green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255, opacity: 1)
    }
}

extension Font {
    static func editorial(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
}

struct Eyebrow: View {
    let text: String
    var color: Color = Palette.gold
    var body: some View {
        Text(text.uppercased()).font(.system(.caption2, design: .rounded, weight: .semibold)).tracking(2).foregroundStyle(color)
    }
}

struct LotusMark: View {
    var color: Color = Palette.gold
    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height * 0.77)
            for angle in [-60.0, -30, 0, 30, 60] {
                var petal = Path()
                petal.move(to: center)
                petal.addQuadCurve(to: CGPoint(x: center.x, y: size.height * 0.09), control: CGPoint(x: center.x - size.width * 0.4, y: size.height * 0.36))
                petal.addQuadCurve(to: center, control: CGPoint(x: center.x + size.width * 0.4, y: size.height * 0.36))
                let transform = CGAffineTransform(translationX: -center.x, y: -center.y)
                    .concatenating(CGAffineTransform(rotationAngle: angle * .pi / 180))
                    .concatenating(CGAffineTransform(translationX: center.x, y: center.y))
                context.stroke(petal.applying(transform), with: .color(color), lineWidth: 1.1)
            }
        }
        .accessibilityHidden(true)
    }
}

struct PageHeading: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: eyebrow)
            Text(title).font(.system(.largeTitle, design: .serif)).foregroundStyle(Palette.ink)
            Text(subtitle).font(.subheadline).foregroundStyle(Palette.muted).lineSpacing(4).fixedSize(horizontal: false, vertical: true)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SectionHeading: View {
    let title: String
    var trailing: String? = nil
    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).font(.system(.title2, design: .serif)).foregroundStyle(Palette.ink)
            Spacer()
            if let trailing { Text(trailing).font(.caption).foregroundStyle(Palette.muted) }
        }
    }
}

struct Pill: View {
    let title: String
    var selected = false
    var body: some View {
        Text(title).font(.subheadline.weight(.medium)).padding(.horizontal, 18).padding(.vertical, 11)
            .foregroundStyle(selected ? Palette.card : Palette.ink)
            .background(selected ? Palette.ink : Palette.card, in: Capsule())
            .overlay(Capsule().strokeBorder(selected ? .clear : Palette.line, lineWidth: 1))
    }
}

struct PrimaryLabel: View {
    let title: String
    var symbol = "arrow.right"
    var body: some View {
        HStack { Text(title).fontWeight(.semibold); Spacer(); Image(systemName: symbol) }
            .font(.subheadline).padding(18).foregroundStyle(Palette.card)
            .background(Palette.ink, in: RoundedRectangle(cornerRadius: 16))
    }
}

struct EntityChip: View {
    let entry: WikiEntry
    var body: some View {
        NavigationLink(value: Route.entity(entry.id)) {
            HStack(spacing: 8) {
                Image(systemName: entry.symbol).font(.caption)
                Text(entry.name).font(.subheadline)
                Image(systemName: "arrow.up.right").font(.system(size: 9, weight: .semibold))
            }.foregroundStyle(Palette.ink).padding(.horizontal, 13).padding(.vertical, 11)
                .background(Palette.card, in: Capsule()).overlay(Capsule().strokeBorder(Palette.line))
        }.buttonStyle(.plain)
    }
}

struct SourceNotes: View {
    let sources: [SourceLink]
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Eyebrow(text: "Sources & further reading")
            ForEach(sources, id: \.url) { source in
                if let url = URL(string: source.url) {
                    Link(destination: url) {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "arrow.up.right.square").font(.caption)
                            Text(source.title).font(.footnote).multilineTextAlignment(.leading)
                        }.foregroundStyle(Palette.ink)
                    }
                }
            }
        }.frame(maxWidth: .infinity, alignment: .leading).padding(20)
            .background(Palette.line.opacity(0.35), in: RoundedRectangle(cornerRadius: 18))
    }
}

struct ArticleBlock: View {
    let section: ArticleSection
    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(section.title).font(.system(.title3, design: .serif)).foregroundStyle(Palette.ink)
            Text(section.text).font(.body).lineSpacing(7).foregroundStyle(Palette.ink.opacity(0.9)).textSelection(.enabled)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EmptyState: View {
    let symbol: String
    let title: String
    let detail: String
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: symbol).font(.system(size: 32, weight: .ultraLight)).foregroundStyle(Palette.gold)
            Text(title).font(.system(.title2, design: .serif)).foregroundStyle(Palette.ink)
            Text(detail).font(.subheadline).foregroundStyle(Palette.muted).multilineTextAlignment(.center).lineSpacing(4)
        }.padding(32).frame(maxWidth: .infinity)
    }
}

struct SaveButton: View {
    @Environment(LearningStore.self) private var store
    let id: String
    let title: String
    let subtitle: String
    let route: Route
    var body: some View {
        Button {
            store.toggleSave(id: id, title: title, subtitle: subtitle, route: route)
        } label: { Image(systemName: store.isSaved(id) ? "bookmark.fill" : "bookmark") }
            .accessibilityLabel(store.isSaved(id) ? "Remove bookmark" : "Save bookmark")
    }
}
