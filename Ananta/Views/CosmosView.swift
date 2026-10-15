import SwiftUI

/// A source-aware, symbolic atlas. Illustrations are interpretive, not astronomical models.
struct CosmosView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var experience = CosmosExperience.cycles
    @State private var cyclePosition = 0.12
    @State private var oceanStage = 0
    @State private var beginning = 0
    @State private var isPlaying = true
    @State private var frozenTime = Date().timeIntervalSinceReferenceDate
    @State private var showsNight = false

    private var yuga: CosmicYuga { CosmicYuga.at(cyclePosition) }
    private var stage: CosmicStory { CosmicStory.ocean[oceanStage] }
    private var origin: CosmicStory { CosmicStory.beginnings[beginning] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                heading
                experiencePicker
                illustration
                Group {
                    switch experience {
                    case .cycles: cycleControls
                    case .ocean: oceanControls
                    case .beginnings: beginningControls
                    }
                }
                perspectiveNote
            }
            .padding(.horizontal, 24)
            .padding(.top, 20)
            .padding(.bottom, 40)
            .frame(maxWidth: 680)
            .frame(maxWidth: .infinity)
        }
        .background(CosmosPalette.ink.ignoresSafeArea())
        .foregroundStyle(CosmosPalette.ivory)
        .tint(CosmosPalette.gold)
        .toolbar(.hidden, for: .navigationBar)
        .preferredColorScheme(.dark)
        .onChange(of: reduceMotion) { _, enabled in
            if enabled { frozenTime = Date().timeIntervalSinceReferenceDate }
        }
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 9) {
                Image(systemName: "sparkles")
                Text("THE COSMIC ATLAS").tracking(2.8)
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(CosmosPalette.gold)
            Text("A universe\nin motion")
                .font(.system(size: 43, weight: .regular, design: .serif))
                .tracking(-1.3)
                .fixedSize(horizontal: false, vertical: true)
            Text("Explore the stories through which Hindu traditions imagine time, creation, and renewal.")
                .font(.system(size: 15))
                .lineSpacing(5)
                .foregroundStyle(CosmosPalette.muted)
        }
    }

    private var experiencePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CosmosExperience.allCases) { item in
                    Button {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) {
                            experience = item
                        }
                    } label: {
                        HStack(spacing: 7) {
                            Image(systemName: item.symbol).font(.system(size: 11))
                            Text(item.rawValue).font(.system(size: 12, weight: .medium))
                        }
                        .padding(.horizontal, 13)
                        .frame(minHeight: 44)
                        .background(experience == item ? CosmosPalette.gold : .white.opacity(0.045), in: Capsule())
                        .foregroundStyle(experience == item ? CosmosPalette.ink : CosmosPalette.ivory)
                        .overlay(Capsule().strokeBorder(.white.opacity(experience == item ? 0 : 0.08)))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(experience == item ? .isSelected : [])
                    .accessibilityIdentifier("cosmos.experience.\(item.id)")
                }
            }
        }
        .contentMargins(.trailing, 2)
    }

    private var illustration: some View {
        VStack(spacing: 0) {
            HStack {
                Label(experience.eyebrow, systemImage: "circle.dotted")
                    .font(.system(size: 9, weight: .medium))
                    .tracking(1.6)
                    .foregroundStyle(CosmosPalette.muted)
                Spacer()
                Text("INTERACTIVE").font(.system(size: 8, weight: .semibold)).tracking(1.2)
                    .foregroundStyle(CosmosPalette.gold)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)

            TimelineView(.animation(minimumInterval: 1.0 / 24, paused: !isPlaying || reduceMotion)) { timeline in
                CosmosDrawing(
                    experience: experience,
                    position: cyclePosition,
                    stage: experience == .ocean ? oceanStage : beginning,
                    time: isPlaying && !reduceMotion ? timeline.date.timeIntervalSinceReferenceDate : frozenTime,
                    night: showsNight
                )
            }
            .frame(height: 292)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(artDescription)

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(artTitle)
                        .font(.system(size: 24, weight: .regular, design: .serif))
                    Text(artSubtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(CosmosPalette.muted)
                }
                Spacer(minLength: 0)
                Button {
                    frozenTime = Date().timeIntervalSinceReferenceDate
                    isPlaying.toggle()
                } label: {
                    Image(systemName: isPlaying && !reduceMotion ? "pause.fill" : "play.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(CosmosPalette.gold)
                        .frame(width: 44, height: 44)
                        .background(CosmosPalette.gold.opacity(0.1), in: Circle())
                        .overlay(Circle().strokeBorder(CosmosPalette.gold.opacity(0.2)))
                }
                .buttonStyle(.plain)
                .disabled(reduceMotion)
                .accessibilityLabel(reduceMotion ? "Animation disabled by Reduce Motion" : isPlaying ? "Pause illustration" : "Animate illustration")
                .accessibilityIdentifier("cosmos.play")
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 22)
        }
        .background {
            RoundedRectangle(cornerRadius: 22)
                .fill(LinearGradient(colors: [Color(red: 0.08, green: 0.16, blue: 0.21), CosmosPalette.panel], startPoint: .topLeading, endPoint: .bottomTrailing))
        }
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(CosmosPalette.gold.opacity(0.16)))
        .clipShape(RoundedRectangle(cornerRadius: 22))
    }

    private var cycleControls: some View {
        VStack(alignment: .leading, spacing: 22) {
            VStack(alignment: .leading, spacing: 12) {
                sectionEyebrow("MOVE THROUGH A GREAT AGE")
                Slider(value: $cyclePosition, in: 0...0.9999)
                    .accessibilityLabel("Position in the four yugas")
                    .accessibilityValue("\(yuga.name), \(Int(cyclePosition * 100)) percent through the great age")
                    .accessibilityIdentifier("cosmos.yugaSlider")
                GeometryReader { geometry in
                    HStack(spacing: 3) {
                        ForEach(CosmicYuga.all) { age in
                            Capsule()
                                .fill(age.color.opacity(yuga.id == age.id ? 1 : 0.32))
                                .frame(width: max(0, (geometry.size.width - 9) * age.fraction))
                        }
                    }
                }
                .frame(height: 3)
                HStack(spacing: 0) {
                    ForEach(CosmicYuga.all) { age in
                        Button {
                            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.35)) { cyclePosition = age.start + age.fraction / 2 }
                        } label: {
                            VStack(spacing: 7) {
                                Text(age.shortName).font(.system(size: 12, weight: .medium))
                                Text(age.durationShort).font(.system(size: 10))
                                    .foregroundStyle(CosmosPalette.muted)
                            }
                            .foregroundStyle(yuga.id == age.id ? CosmosPalette.gold : CosmosPalette.ivory)
                            .frame(maxWidth: .infinity, minHeight: 48)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("\(age.name), \(age.duration) years")
                        .accessibilityAddTraits(yuga.id == age.id ? .isSelected : [])
                    }
                }
            }
            Divider().overlay(.white.opacity(0.08))
            VStack(alignment: .leading, spacing: 11) {
                HStack(alignment: .firstTextBaseline) {
                    Text(yuga.duration).font(.system(size: 31, weight: .regular, design: .serif))
                    Text("human years").font(.system(size: 12)).foregroundStyle(CosmosPalette.muted)
                }
                Text(yuga.detail).font(.system(size: 14)).lineSpacing(5).foregroundStyle(CosmosPalette.muted)
            }
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(systemName: showsNight ? "moon.stars" : "sun.max")
                        .foregroundStyle(CosmosPalette.gold)
                    Text("A day of Brahmā").font(.system(size: 18, design: .serif))
                    Spacer()
                    Toggle("Show Brahmā’s night", isOn: $showsNight).labelsHidden()
                        .accessibilityIdentifier("cosmos.night")
                }
                Text(showsNight ? "An equally long night follows: dissolution, repose, and another beginning. The night is 4.32 billion human years in this model." : "1,000 great ages form one day of Brahmā: 4.32 billion human years. Each four-age cycle totals 4.32 million years.")
                    .font(.system(size: 13)).lineSpacing(4).foregroundStyle(CosmosPalette.muted)
            }
            .padding(18)
            .background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 15))
            sourceLink("Viṣṇu Purāṇa I.3", subtitle: "H. H. Wilson translation · traditional scale", url: "https://sacred-texts.com/hin/vp/vp037.htm")
        }
    }

    private var oceanControls: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionEyebrow("SAMUDRA MANTHANA · \(oceanStage + 1) OF 6")
            HStack(spacing: 7) {
                ForEach(0..<6, id: \.self) { index in
                    Button {
                        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { oceanStage = index }
                    } label: {
                        Text(String(format: "%02d", index + 1))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .frame(maxWidth: .infinity, minHeight: 44)
                            .background(index == oceanStage ? CosmosPalette.gold : .white.opacity(0.04), in: RoundedRectangle(cornerRadius: 10))
                            .foregroundStyle(index == oceanStage ? CosmosPalette.ink : CosmosPalette.muted)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Step \(index + 1), \(CosmicStory.ocean[index].title)")
                    .accessibilityAddTraits(index == oceanStage ? .isSelected : [])
                }
            }
            Text(stage.body).font(.system(size: 15)).lineSpacing(6).foregroundStyle(CosmosPalette.muted)
            HStack {
                Button { oceanStage = max(0, oceanStage - 1) } label: {
                    Label("Previous", systemImage: "arrow.left").font(.system(size: 13, weight: .medium))
                        .frame(minHeight: 44)
                }
                .disabled(oceanStage == 0)
                Spacer()
                Button { oceanStage = min(5, oceanStage + 1) } label: {
                    HStack { Text("Next chapter"); Image(systemName: "arrow.right") }
                        .font(.system(size: 13, weight: .medium)).frame(minHeight: 44)
                }
                .disabled(oceanStage == 5)
            }
            sourceLink("Viṣṇu Purāṇa I.9", subtitle: "H. H. Wilson translation · this telling", url: "https://sacred-texts.com/hin/vp/vp044.htm")
            Text("Retellings differ in the order of the treasures and the treatment of the poison. These six scenes follow this chapter’s telling.")
                .font(.system(size: 12)).lineSpacing(4).foregroundStyle(CosmosPalette.muted)
        }
    }

    private var beginningControls: some View {
        VStack(alignment: .leading, spacing: 17) {
            sectionEyebrow("THREE WINDOWS ON CREATION")
            ForEach(Array(CosmicStory.beginnings.enumerated()), id: \.offset) { index, item in
                Button {
                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.3)) { beginning = index }
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: ["questionmark", "sun.max", "leaf"][index])
                            .font(.system(size: 16, weight: .light))
                            .frame(width: 34, height: 34)
                            .foregroundStyle(CosmosPalette.gold)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(item.title).font(.system(size: 17, design: .serif))
                            Text(item.subtitle).font(.system(size: 11)).foregroundStyle(CosmosPalette.muted)
                        }
                        Spacer()
                        Image(systemName: beginning == index ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 18)).foregroundStyle(CosmosPalette.gold.opacity(beginning == index ? 1 : 0.3))
                    }
                    .padding(13)
                    .background(.white.opacity(beginning == index ? 0.055 : 0.015), in: RoundedRectangle(cornerRadius: 13))
                    .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(CosmosPalette.gold.opacity(beginning == index ? 0.3 : 0.08)))
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(beginning == index ? .isSelected : [])
            }
            Text(origin.body).font(.system(size: 15)).lineSpacing(6).foregroundStyle(CosmosPalette.muted)
                .padding(.top, 5)
            sourceLink(origin.subtitle, subtitle: beginning == 2 ? "Bhaktivedanta Vedabase · Vaiṣṇava interpretation" : "R. T. H. Griffith translation · Vedic hymn", url: origin.source)
        }
    }

    private var perspectiveNote: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: "sparkle").foregroundStyle(CosmosPalette.gold).padding(.top, 2)
            Text("One tradition, many ways of seeing. These are sacred narratives and philosophical models, presented in their textual settings. The illustrations are symbolic.")
                .font(.system(size: 12)).lineSpacing(4).foregroundStyle(CosmosPalette.muted)
        }
        .padding(.top, 8)
    }

    private func sectionEyebrow(_ title: String) -> some View {
        Text(title).font(.system(size: 9, weight: .semibold)).tracking(1.8).foregroundStyle(CosmosPalette.gold)
    }

    private func sourceLink(_ title: String, subtitle: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 12) {
                Image(systemName: "book.closed").font(.system(size: 17, weight: .light))
                VStack(alignment: .leading, spacing: 5) {
                    Text(title).font(.system(size: 14, weight: .medium))
                    Text(subtitle).font(.system(size: 10)).foregroundStyle(CosmosPalette.muted)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right").font(.system(size: 12))
            }
            .foregroundStyle(CosmosPalette.gold)
            .padding(.vertical, 12)
            .frame(minHeight: 44)
        }
        .accessibilityLabel("Read source: \(title). \(subtitle). Opens website.")
    }

    private var artTitle: String {
        switch experience {
        case .cycles: return showsNight ? "The long night" : yuga.name
        case .ocean: return stage.title
        case .beginnings: return origin.title
        }
    }

    private var artSubtitle: String {
        switch experience {
        case .cycles: return showsNight ? "Repose before renewal" : "One cycle. Four unfolding ages."
        case .ocean: return "The churning of the Ocean of Milk"
        case .beginnings: return origin.subtitle
        }
    }

    private var artDescription: String {
        switch experience {
        case .cycles: return "Symbolic concentric cosmic rings. \(yuga.name) is highlighted. The four colored arcs show the yugas in a 4 to 3 to 2 to 1 proportion. \(showsNight ? "Night view is active." : "A golden lotus marks the center.")"
        case .ocean: return "Symbolic ocean illustration, stage \(oceanStage + 1): \(stage.title). \(stage.body)"
        case .beginnings: return ["A field of stars surrounds an open circle, suggesting an unanswered question.", "A glowing golden oval represents Hiraṇyagarbha, the golden germ.", "A lotus rises above stylized cosmic waters, a symbol of Brahmā’s appearance."][beginning]
        }
    }
}

private enum CosmosPalette {
    static let ink = Color(red: 17.0 / 255, green: 30.0 / 255, blue: 41.0 / 255)
    static let panel = Color(red: 12.0 / 255, green: 26.0 / 255, blue: 35.0 / 255)
    static let gold = Color(red: 214.0 / 255, green: 172.0 / 255, blue: 106.0 / 255)
    static let ivory = Color(red: 0.96, green: 0.93, blue: 0.86)
    static let muted = Color(red: 0.61, green: 0.67, blue: 0.69)
    static let teal = Color(red: 0.32, green: 0.62, blue: 0.63)
}

private enum CosmosExperience: String, CaseIterable, Identifiable {
    case cycles = "Cosmic cycles"
    case ocean = "Ocean churning"
    case beginnings = "Many beginnings"
    var id: String { rawValue }
    var symbol: String {
        switch self { case .cycles: "circle.hexagongrid"; case .ocean: "water.waves"; case .beginnings: "sparkles" }
    }
    var eyebrow: String {
        switch self { case .cycles: "THE WHEEL OF TIME"; case .ocean: "AN OCEAN OF POSSIBILITY"; case .beginnings: "BEFORE THE BEGINNING" }
    }
}

private struct CosmicYuga: Identifiable {
    let id: Int
    let name: String
    let shortName: String
    let duration: String
    let durationShort: String
    let fraction: Double
    let start: Double
    let color: Color
    let detail: String
    static let all: [CosmicYuga] = [
        .init(id: 0, name: "Satya Yuga", shortName: "Satya", duration: "1.728 million", durationShort: "1.728m", fraction: 0.4, start: 0, color: CosmosPalette.gold, detail: "Also called Kṛta, the first age occupies four parts of the ten-part cycle. The durations here include each age’s dawn and twilight."),
        .init(id: 1, name: "Tretā Yuga", shortName: "Tretā", duration: "1.296 million", durationShort: "1.296m", fraction: 0.3, start: 0.4, color: Color(red: 0.79, green: 0.55, blue: 0.34), detail: "The second age occupies three parts of the cycle. The great ages decrease in length in this Purāṇic reckoning of time."),
        .init(id: 2, name: "Dvāpara Yuga", shortName: "Dvāpara", duration: "864,000", durationShort: "864k", fraction: 0.2, start: 0.7, color: CosmosPalette.teal, detail: "The third age occupies two parts of the cycle. The wheel shows relative duration, rather than four equal slices."),
        .init(id: 3, name: "Kali Yuga", shortName: "Kali", duration: "432,000", durationShort: "432k", fraction: 0.1, start: 0.9, color: Color(red: 0.57, green: 0.55, blue: 0.72), detail: "The fourth and shortest age occupies one part. It completes a great age, after which the pattern begins again. Kali here is distinct from the goddess Kālī.")
    ]
    static func at(_ position: Double) -> CosmicYuga {
        all.last(where: { position >= $0.start }) ?? all[0]
    }
}

private struct CosmicStory {
    let title: String
    let subtitle: String
    let body: String
    var source: String = "https://sacred-texts.com/hin/vp/vp044.htm"
    static let ocean: [CosmicStory] = [
        .init(title: "An uneasy alliance", subtitle: "01 · Cooperation", body: "Their strength diminished, the devas seek Viṣṇu’s help. He proposes that they work with their rivals, the asuras, to churn the Ocean of Milk for amṛta, the nectar of immortality."),
        .init(title: "A mountain, a serpent", subtitle: "02 · Churning", body: "Mount Mandara becomes the churning rod; the serpent Vāsuki becomes the rope. Devas and asuras pull from opposite sides."),
        .init(title: "The hidden support", subtitle: "03 · Kūrma", body: "Viṣṇu takes a tortoise form to support the mountain. The steady foundation beneath the ocean makes the immense effort possible."),
        .init(title: "Treasures from the deep", subtitle: "04 · Emergence", body: "Surabhi, Vāruṇī, the Pārijāta tree, celestial nymphs, the moon, and poison emerge. Dhanvantari then appears carrying amṛta."),
        .init(title: "The rising of Śrī", subtitle: "05 · Lakṣmī", body: "Śrī, also called Lakṣmī, rises on a lotus. She is honored and joins Viṣṇu, restoring the presence of prosperity."),
        .init(title: "The nectar is contested", subtitle: "06 · Resolution", body: "Viṣṇu assumes an enchanting form. The devas receive the nectar; conflict follows. The story leaves cooperation and rivalry closely intertwined.")
    ]
    static let beginnings: [CosmicStory] = [
        .init(title: "An open question", subtitle: "Ṛgveda 10.129", body: "The Nāsadīya hymn asks what preceded existence and who could know its origin. Its final movement leaves even the highest observer’s knowledge in question. Wonder remains part of the answer.", source: "https://sacred-texts.com/hin/rigveda/rv10129.htm"),
        .init(title: "The golden germ", subtitle: "Ṛgveda 10.121", body: "Hiraṇyagarbha, the golden germ or embryo, appears as the source and sustainer of beings. The hymn returns to a question of worship and addresses Prajāpati in its closing verse.", source: "https://sacred-texts.com/hin/rigveda/rv10121.htm"),
        .init(title: "A lotus on the waters", subtitle: "Bhāgavata Purāṇa 3.8", body: "In this Vaiṣṇava account, a lotus grows from Viṣṇu, and Brahmā appears within it. The creator first searches for his own origin. This is one Purāṇic telling among many.", source: "https://vedabase.io/en/library/sb/3/8/")
    ]
}

private struct CosmosDrawing: View {
    let experience: CosmosExperience
    let position: Double
    let stage: Int
    let time: Double
    let night: Bool

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let scale = min(size.width / 340, 1.16)
            drawStars(context: &context, size: size)
            context.translateBy(x: center.x, y: center.y)
            context.scaleBy(x: scale, y: scale)
            switch experience {
            case .cycles: drawCycles(context: &context)
            case .ocean: drawOcean(context: &context)
            case .beginnings: drawBeginning(context: &context)
            }
        }
        .drawingGroup()
    }

    private func drawStars(context: inout GraphicsContext, size: CGSize) {
        for index in 0..<72 {
            let x = CGFloat((index * 97 + 19) % 353) / 353 * size.width
            let y = CGFloat((index * 53 + 31) % 293) / 293 * size.height
            let radius: CGFloat = index % 7 == 0 ? 1.15 : 0.55
            let opacity = 0.16 + Double(index % 5) * 0.09
            context.fill(Path(ellipseIn: CGRect(x: x, y: y, width: radius * 2, height: radius * 2)), with: .color(CosmosPalette.ivory.opacity(opacity)))
            if index % 13 == 0 {
                var sparkle = Path()
                sparkle.move(to: CGPoint(x: x - 3, y: y + radius))
                sparkle.addLine(to: CGPoint(x: x + 4, y: y + radius))
                sparkle.move(to: CGPoint(x: x + radius, y: y - 3))
                sparkle.addLine(to: CGPoint(x: x + radius, y: y + 4))
                context.stroke(sparkle, with: .color(CosmosPalette.gold.opacity(0.3)), lineWidth: 0.6)
            }
        }
    }

    private func drawCycles(context: inout GraphicsContext) {
        let selected = CosmicYuga.at(position)
        let glow = night ? CosmosPalette.teal : CosmosPalette.gold
        let halo = Path(ellipseIn: CGRect(x: -119, y: -119, width: 238, height: 238))
        context.fill(halo, with: .radialGradient(Gradient(colors: [glow.opacity(night ? 0.1 : 0.16), glow.opacity(0)]), center: .zero, startRadius: 5, endRadius: 119))

        for radius in [68.0, 93.0, 121.0, 135.0] {
            let ring = Path(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2))
            context.stroke(ring, with: .color(CosmosPalette.gold.opacity(radius == 135 ? 0.13 : 0.23)), style: StrokeStyle(lineWidth: 0.6, dash: radius == 135 ? [1, 7] : []))
        }

        for tick in 0..<80 {
            let angle = Double(tick) / 80 * .pi * 2
            let long = tick % 10 == 0
            var path = Path()
            path.move(to: point(angle, radius: 115))
            path.addLine(to: point(angle, radius: long ? 123 : 118))
            context.stroke(path, with: .color(CosmosPalette.gold.opacity(long ? 0.65 : 0.27)), lineWidth: 0.6)
        }

        for age in CosmicYuga.all {
            var arc = Path()
            arc.addArc(center: .zero, radius: 104, startAngle: .degrees(age.start * 360 - 88), endAngle: .degrees((age.start + age.fraction) * 360 - 92), clockwise: false)
            context.stroke(arc, with: .color(age.color.opacity(night ? 0.25 : selected.id == age.id ? 1 : 0.28)), style: StrokeStyle(lineWidth: selected.id == age.id ? 3.5 : 2, lineCap: .round))
        }

        var lotus = context
        lotus.rotate(by: .radians(time * 0.035))
        drawRosette(context: &lotus, radius: night ? 25 : 39, petals: 12, opacity: night ? 0.28 : 0.75)
        var inner = context
        inner.rotate(by: .radians(-time * 0.025))
        drawRosette(context: &inner, radius: night ? 14 : 24, petals: 8, opacity: night ? 0.24 : 0.65)

        for (index, radius) in [68.0, 93.0, 121.0].enumerated() {
            let angle = time * (index % 2 == 0 ? 0.022 : -0.016) + Double(index) * 2.4
            let p = point(angle, radius: radius)
            context.fill(Path(ellipseIn: CGRect(x: p.x - 2.5, y: p.y - 2.5, width: 5, height: 5)), with: .color(CosmosPalette.gold.opacity(night ? 0.3 : 0.75)))
        }
        let marker = point(position * .pi * 2 - .pi / 2, radius: 104)
        let markerRect = CGRect(x: marker.x - 13, y: marker.y - 13, width: 26, height: 26)
        context.fill(Path(ellipseIn: markerRect), with: .radialGradient(Gradient(colors: [selected.color.opacity(0.6), selected.color.opacity(0)]), center: marker, startRadius: 1, endRadius: 13))
        context.fill(Path(ellipseIn: CGRect(x: marker.x - 4, y: marker.y - 4, width: 8, height: 8)), with: .color(CosmosPalette.ivory))
        let centerDot = Path(ellipseIn: CGRect(x: -3, y: -3, width: 6, height: 6))
        context.fill(centerDot, with: .color(glow))
    }

    private func drawOcean(context: inout GraphicsContext) {
        let glowCenter = CGPoint(x: 0, y: -5)
        context.fill(Path(ellipseIn: CGRect(x: -125, y: -130, width: 250, height: 260)), with: .radialGradient(Gradient(colors: [CosmosPalette.teal.opacity(0.15), .clear]), center: glowCenter, startRadius: 0, endRadius: 130))
        drawWaves(context: &context, baseline: 62)
        if stage >= 1 {
            var mountain = Path()
            mountain.move(to: CGPoint(x: -63, y: 60))
            mountain.addLine(to: CGPoint(x: -12, y: -82))
            mountain.addLine(to: CGPoint(x: 3, y: -101))
            mountain.addLine(to: CGPoint(x: 19, y: -58))
            mountain.addLine(to: CGPoint(x: 58, y: 60))
            mountain.closeSubpath()
            context.fill(mountain, with: .linearGradient(Gradient(colors: [CosmosPalette.gold.opacity(0.18), CosmosPalette.teal.opacity(0.05)]), startPoint: CGPoint(x: -30, y: -80), endPoint: CGPoint(x: 25, y: 60)))
            context.stroke(mountain, with: .color(CosmosPalette.gold.opacity(0.75)), lineWidth: 1)
            var ridge = Path()
            ridge.move(to: CGPoint(x: 3, y: -101))
            ridge.addLines([CGPoint(x: -10, y: -14), CGPoint(x: 12, y: 60)])
            context.stroke(ridge, with: .color(CosmosPalette.gold.opacity(0.35)), lineWidth: 0.8)
            for coil in 0..<3 {
                var snake = Path()
                for step in 0...90 {
                    let x = Double(step) / 90 * 252 - 126
                    let y = 9 + Double(coil) * 13 + sin(x / 25 + time * 0.7 + Double(coil) * 0.9) * 8
                    let p = CGPoint(x: x, y: y)
                    if step == 0 { snake.move(to: p) } else { snake.addLine(to: p) }
                }
                context.stroke(snake, with: .color(CosmosPalette.gold.opacity(0.75 - Double(coil) * 0.19)), lineWidth: coil == 0 ? 2 : 1)
            }
        }
        if stage >= 2 {
            let shell = Path(ellipseIn: CGRect(x: -38, y: 79, width: 76, height: 29))
            context.fill(shell, with: .color(CosmosPalette.teal.opacity(0.19)))
            context.stroke(shell, with: .color(CosmosPalette.teal.opacity(0.8)), lineWidth: 1)
            context.stroke(Path(ellipseIn: CGRect(x: -24, y: 82, width: 48, height: 22)), with: .color(CosmosPalette.teal.opacity(0.4)), lineWidth: 0.7)
            context.stroke(Path(ellipseIn: CGRect(x: 36, y: 85, width: 16, height: 11)), with: .color(CosmosPalette.teal.opacity(0.8)), lineWidth: 1)
        }
        if stage >= 3 {
            let moon = Path(ellipseIn: CGRect(x: 81, y: -88, width: 23, height: 23))
            context.fill(moon, with: .color(CosmosPalette.ivory.opacity(0.78)))
            context.fill(Path(ellipseIn: CGRect(x: 86, y: -94, width: 22, height: 22)), with: .color(CosmosPalette.panel))
            var tree = Path()
            tree.move(to: CGPoint(x: -90, y: -21))
            tree.addLine(to: CGPoint(x: -90, y: -66))
            tree.move(to: CGPoint(x: -90, y: -43))
            tree.addLine(to: CGPoint(x: -108, y: -58))
            tree.move(to: CGPoint(x: -90, y: -51))
            tree.addLine(to: CGPoint(x: -71, y: -68))
            context.stroke(tree, with: .color(CosmosPalette.gold.opacity(0.7)), lineWidth: 1)
            for p in [CGPoint(x: -109, y: -66), CGPoint(x: -91, y: -81), CGPoint(x: -68, y: -76)] {
                context.stroke(Path(ellipseIn: CGRect(x: p.x - 10, y: p.y - 8, width: 20, height: 16)), with: .color(CosmosPalette.gold.opacity(0.5)), lineWidth: 0.8)
            }
        }
        if stage >= 4 {
            var flower = context
            flower.translateBy(x: 0, y: -51)
            drawLotus(context: &flower, radius: 38)
        }
        if stage == 5 {
            var pot = Path()
            pot.move(to: CGPoint(x: 76, y: -22))
            pot.addCurve(to: CGPoint(x: 104, y: -22), control1: CGPoint(x: 61, y: 17), control2: CGPoint(x: 119, y: 17))
            pot.addLine(to: CGPoint(x: 100, y: -28))
            pot.addLine(to: CGPoint(x: 80, y: -28))
            pot.closeSubpath()
            context.fill(pot, with: .color(CosmosPalette.gold.opacity(0.2)))
            context.stroke(pot, with: .color(CosmosPalette.gold), lineWidth: 1)
        }
        if stage == 0 {
            for (offset, color) in [(-72.0, CosmosPalette.gold), (72.0, CosmosPalette.teal)] {
                var group = context
                group.translateBy(x: offset, y: -17)
                group.stroke(Path(ellipseIn: CGRect(x: -29, y: -29, width: 58, height: 58)), with: .color(color.opacity(0.6)), lineWidth: 0.8)
                for index in 0..<6 {
                    let p = point(Double(index) / 6 * .pi * 2, radius: 16)
                    group.fill(Path(ellipseIn: CGRect(x: p.x - 3, y: p.y - 3, width: 6, height: 6)), with: .color(color))
                }
            }
            var connection = Path()
            connection.move(to: CGPoint(x: -40, y: -17))
            connection.addLine(to: CGPoint(x: 40, y: -17))
            context.stroke(connection, with: .color(CosmosPalette.gold.opacity(0.4)), style: StrokeStyle(lineWidth: 1, dash: [3, 5]))
        }
    }

    private func drawBeginning(context: inout GraphicsContext) {
        switch stage {
        case 0:
            for index in 0..<4 {
                var ring = Path()
                let radius = 43.0 + Double(index) * 23
                ring.addArc(center: .zero, radius: radius, startAngle: .radians(time * 0.017 + Double(index)), endAngle: .radians(time * 0.017 + Double(index) + .pi * 1.55), clockwise: false)
                context.stroke(ring, with: .color(CosmosPalette.gold.opacity(0.6 - Double(index) * 0.12)), style: StrokeStyle(lineWidth: 0.7, lineCap: .round))
            }
            context.draw(Text("?").font(.system(size: 57, weight: .ultraLight, design: .serif)).foregroundColor(CosmosPalette.gold), at: .zero)
        case 1:
            let egg = Path(ellipseIn: CGRect(x: -53, y: -78, width: 106, height: 148))
            context.fill(Path(ellipseIn: CGRect(x: -115, y: -125, width: 230, height: 250)), with: .radialGradient(Gradient(colors: [CosmosPalette.gold.opacity(0.3), .clear]), center: CGPoint(x: 0, y: -8), startRadius: 0, endRadius: 125))
            context.fill(egg, with: .radialGradient(Gradient(colors: [CosmosPalette.ivory.opacity(0.95), CosmosPalette.gold.opacity(0.65), CosmosPalette.gold.opacity(0.05)]), center: CGPoint(x: -12, y: -23), startRadius: 0, endRadius: 93))
            context.stroke(egg, with: .color(CosmosPalette.gold.opacity(0.8)), lineWidth: 1)
            for index in 0..<36 {
                let angle = Double(index) / 36 * .pi * 2 + time * 0.009
                var ray = Path()
                ray.move(to: CGPoint(x: cos(angle) * 75, y: sin(angle) * 101))
                ray.addLine(to: CGPoint(x: cos(angle) * 84, y: sin(angle) * 113))
                context.stroke(ray, with: .color(CosmosPalette.gold.opacity(0.4)), lineWidth: 0.8)
            }
        default:
            drawWaves(context: &context, baseline: 61)
            var stem = Path()
            stem.move(to: CGPoint(x: 0, y: 70))
            stem.addCurve(to: CGPoint(x: 0, y: -13), control1: CGPoint(x: 17, y: 40), control2: CGPoint(x: -12, y: 9))
            context.stroke(stem, with: .color(CosmosPalette.gold.opacity(0.7)), lineWidth: 1.4)
            var lotus = context
            lotus.translateBy(x: 0, y: -20)
            drawLotus(context: &lotus, radius: 75)
            var halo = Path()
            halo.addArc(center: CGPoint(x: 0, y: -25), radius: 104, startAngle: .degrees(196), endAngle: .degrees(-16), clockwise: false)
            context.stroke(halo, with: .color(CosmosPalette.gold.opacity(0.25)), style: StrokeStyle(lineWidth: 0.7, dash: [1, 5]))
        }
    }

    private func drawWaves(context: inout GraphicsContext, baseline: Double) {
        for index in 0..<6 {
            var wave = Path()
            for step in 0...100 {
                let x = Double(step) * 2.9 - 145
                let y = baseline + Double(index) * 8 + sin(x / 28 + time * 0.32 + Double(index) * 0.7) * 3
                if step == 0 { wave.move(to: CGPoint(x: x, y: y)) } else { wave.addLine(to: CGPoint(x: x, y: y)) }
            }
            context.stroke(wave, with: .color(CosmosPalette.teal.opacity(0.47 - Double(index) * 0.065)), lineWidth: 0.8)
        }
    }

    private func drawRosette(context: inout GraphicsContext, radius: Double, petals: Int, opacity: Double) {
        for index in 0..<petals {
            var petal = Path()
            petal.move(to: .zero)
            petal.addQuadCurve(to: CGPoint(x: 0, y: -radius), control: CGPoint(x: -radius * 0.58, y: -radius * 0.63))
            petal.addQuadCurve(to: .zero, control: CGPoint(x: radius * 0.58, y: -radius * 0.63))
            let transform = CGAffineTransform(rotationAngle: Double(index) / Double(petals) * .pi * 2)
            context.stroke(petal.applying(transform), with: .color(CosmosPalette.gold.opacity(opacity)), lineWidth: 0.75)
        }
    }

    private func drawLotus(context: inout GraphicsContext, radius: Double) {
        for angle in [-65.0, -38.0, 0, 38.0, 65.0] {
            var petal = Path()
            petal.move(to: CGPoint(x: 0, y: 26))
            petal.addQuadCurve(to: CGPoint(x: 0, y: -radius), control: CGPoint(x: -radius * 0.68, y: -radius * 0.3))
            petal.addQuadCurve(to: CGPoint(x: 0, y: 26), control: CGPoint(x: radius * 0.68, y: -radius * 0.3))
            let rotated = petal.applying(CGAffineTransform(rotationAngle: angle * .pi / 180))
            context.fill(rotated, with: .color(CosmosPalette.gold.opacity(0.05)))
            context.stroke(rotated, with: .color(CosmosPalette.gold.opacity(angle == 0 ? 0.95 : 0.6)), lineWidth: 1)
        }
        context.fill(Path(ellipseIn: CGRect(x: -7, y: 11, width: 14, height: 6)), with: .color(CosmosPalette.gold.opacity(0.8)))
    }

    private func point(_ angle: Double, radius: Double) -> CGPoint {
        CGPoint(x: cos(angle) * radius, y: sin(angle) * radius)
    }
}

#Preview("Cosmic atlas") {
    CosmosView()
}
