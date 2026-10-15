import SwiftUI

struct JourneyView: View {
    @Environment(LearningStore.self) private var store
    @Binding var selectedTab: AppTab
    @State private var showSaved = false
    @State private var showAbout = false
    @State private var showAllLessons = false
    private var visibleLessons: [Lesson] { showAllLessons ? store.lessons : Array(store.lessons.prefix(3)) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                masthead
                VStack(alignment: .leading, spacing: 9) {
                    Eyebrow(text: "A living atlas of Hinduism")
                    Text("Begin with wonder.").font(.editorial(37)).foregroundStyle(Palette.ink)
                    Text("Ancient questions. Many traditions.\nA path that starts right where you are.")
                        .font(.subheadline).foregroundStyle(Palette.muted).lineSpacing(4)
                }
                hero
                if let last = store.lastRead, let book = store.book(last.bookID) {
                    NavigationLink(value: Route.reader(book: last.bookID, chapter: last.chapterID, passage: last.passageID)) {
                        HStack(spacing: 14) {
                            Image(systemName: "book.pages").font(.title2).foregroundStyle(Palette.gold)
                            VStack(alignment: .leading, spacing: 4) {
                                Eyebrow(text: "Continue reading")
                                Text(book.title).font(.system(.headline, design: .serif)).foregroundStyle(Palette.ink)
                            }
                            Spacer()
                            Image(systemName: "arrow.right").foregroundStyle(Palette.ink)
                        }.padding(18).background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
                    }.buttonStyle(.plain)
                }
                learningPath
                cosmosCard
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        SectionHeading(title: "Meet the ideas")
                        Button("Explore all") { selectedTab = .atlas }.font(.caption.weight(.semibold)).foregroundStyle(Palette.gold)
                    }
                    HStack(spacing: 12) {
                        ForEach(["dharma", "karma", "moksha"], id: \.self) { id in
                            if let entry = store.entity(id) {
                                NavigationLink(value: Route.entity(id)) {
                                    VStack(alignment: .leading, spacing: 14) {
                                        Image(systemName: entry.symbol).font(.system(size: 24, weight: .light)).foregroundStyle(Palette.gold)
                                        Text(entry.name).font(.system(.subheadline, design: .serif, weight: .medium)).foregroundStyle(Palette.ink)
                                        Text("Discover").font(.caption2).foregroundStyle(Palette.muted)
                                    }.frame(maxWidth: .infinity, alignment: .leading).padding(16)
                                        .background(Palette.card, in: RoundedRectangle(cornerRadius: 18))
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                }
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: "leaf").foregroundStyle(Palette.gold)
                    Text("There is no single Hindu voice. Explore the texts, discover different perspectives, and make room for questions.")
                        .font(.footnote).lineSpacing(4).foregroundStyle(Palette.muted)
                }.padding(.vertical, 8)
            }.padding(.horizontal, 24).padding(.top, 10).padding(.bottom, 28).frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
        }
        .readingPage().toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showSaved) { NavigationStack { SavedView().routeDestinations() }.environment(store) }
        .sheet(isPresented: $showAbout) { NavigationStack { AboutView() }.environment(store) }
    }

    private var masthead: some View {
        HStack(spacing: 9) {
            LotusMark().frame(width: 33, height: 33)
            Text("Hindu App").font(.editorial(27)).foregroundStyle(Palette.ink)
            Spacer()
            Button { showSaved = true } label: {
                Image(systemName: "bookmark").font(.system(size: 17, weight: .regular)).frame(width: 44, height: 44)
                    .background(Palette.card, in: Circle())
            }.accessibilityLabel("Your saved pages")
            Button { showAbout = true } label: {
                Image(systemName: "info").font(.system(size: 17, weight: .regular)).frame(width: 44, height: 44)
                    .background(Palette.card, in: Circle())
            }.accessibilityLabel("About Hindu App and its sources")
        }.foregroundStyle(Palette.ink)
    }

    private var hero: some View {
        Group {
            if let lesson = store.nextLesson ?? store.lessons.first {
                NavigationLink(value: Route.lesson(lesson.id)) {
                    ZStack(alignment: .bottomLeading) {
                        GeometryReader { proxy in
                            Image("CosmicLotus").resizable().scaledToFill().frame(width: proxy.size.width, height: proxy.size.height).clipped()
                        }
                        LinearGradient(colors: [Palette.night.opacity(0.03), Palette.night.opacity(0.3), Palette.night.opacity(0.95)], startPoint: .top, endPoint: .bottom)
                        VStack(alignment: .leading, spacing: 13) {
                            HStack {
                                Label("YOUR FIRST STEPS", systemImage: "sparkle").font(.system(size: 10, weight: .semibold)).tracking(2)
                                Spacer()
                                Text("\(lesson.minutes) MIN").font(.system(size: 10, weight: .medium)).tracking(1.5)
                            }.foregroundStyle(Palette.paleGold)
                            Text(store.progress > 0 ? "Keep your\ncuriosity alive." : "A world of wisdom.\nA place to begin.")
                                .font(.editorial(29)).foregroundStyle(.white).lineSpacing(2)
                            HStack {
                                Text(store.progress > 0 ? "Continue your journey" : "Start your journey").font(.subheadline.weight(.semibold))
                                Image(systemName: "arrow.right").font(.subheadline)
                            }.foregroundStyle(Palette.night).padding(.horizontal, 17).padding(.vertical, 13)
                                .background(Palette.paleGold, in: Capsule())
                        }.padding(24)
                    }.frame(height: 330).background(Palette.night).clipShape(RoundedRectangle(cornerRadius: 25))
                }.buttonStyle(.plain).accessibilityIdentifier("startJourney")
            }
        }
    }

    private var learningPath: some View {
        VStack(alignment: .leading, spacing: 18) {
            SectionHeading(title: "A path into understanding", trailing: "\(store.completedLessons.count) / \(store.lessons.count)")
            ProgressView(value: store.progress).tint(Palette.gold).accessibilityLabel("Learning path progress")
            ForEach(visibleLessons) { lesson in
                NavigationLink(value: Route.lesson(lesson.id)) {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle().fill(store.completedLessons.contains(lesson.id) ? Palette.ink : Palette.paleGold.opacity(0.4))
                            if store.completedLessons.contains(lesson.id) {
                                Image(systemName: "checkmark").font(.subheadline.weight(.semibold)).foregroundStyle(Palette.card)
                            } else { Text(String(format: "%02d", lesson.number)).font(.system(.subheadline, design: .serif)).foregroundStyle(Palette.gold) }
                        }.frame(width: 42, height: 42)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(lesson.title).font(.system(.headline, design: .serif)).foregroundStyle(Palette.ink)
                            Text("\(lesson.minutes) min · \(lesson.subtitle)").font(.caption).foregroundStyle(Palette.muted).lineLimit(2)
                        }
                        Spacer(minLength: 3)
                        Image(systemName: "chevron.right").font(.caption2.weight(.semibold)).foregroundStyle(Palette.muted)
                    }.padding(.vertical, 8).contentShape(Rectangle())
                }.buttonStyle(.plain)
                if lesson.id != visibleLessons.last?.id { Divider().overlay(Palette.line).padding(.leading, 58) }
            }
            Button { showAllLessons.toggle() } label: {
                HStack { Text(showAllLessons ? "Show the first steps" : "Explore all \(store.lessons.count) lessons"); Spacer(); Image(systemName: showAllLessons ? "chevron.up" : "arrow.down") }
                    .font(.subheadline.weight(.medium)).foregroundStyle(Palette.gold).padding(.vertical, 12)
            }
        }
    }

    private var cosmosCard: some View {
        Button { selectedTab = .cosmos } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 12) {
                    Eyebrow(text: "An interactive universe", color: Palette.paleGold)
                    Text("What if time\nis a circle?").font(.editorial(27)).foregroundStyle(.white)
                    Label("Explore the cosmos", systemImage: "arrow.up.right").font(.caption.weight(.semibold)).foregroundStyle(Palette.paleGold)
                }
                Spacer(minLength: 0)
                ZStack {
                    ForEach(0..<4) { index in
                        Circle().stroke(Palette.paleGold.opacity(0.18 + Double(index) * 0.1), lineWidth: 0.7).frame(width: CGFloat(45 + index * 24))
                    }
                    Circle().fill(Palette.paleGold).frame(width: 12, height: 12)
                    Circle().fill(Palette.paleGold).frame(width: 6, height: 6).offset(x: 35, y: -29)
                }.frame(width: 112, height: 130).accessibilityHidden(true)
            }.padding(24).frame(maxWidth: .infinity, alignment: .leading).background(Palette.night, in: RoundedRectangle(cornerRadius: 23))
        }.buttonStyle(.plain)
    }
}

struct LessonDetailView: View {
    @Environment(LearningStore.self) private var store
    let lesson: Lesson
    @State private var answer: Int?
    var correct: Bool { answer == lesson.correctAnswer }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                PageHeading(eyebrow: "Lesson \(lesson.number) · \(lesson.minutes) minute read", title: lesson.title, subtitle: lesson.subtitle)
                Rectangle().fill(Palette.gold).frame(width: 44, height: 2)
                ForEach(lesson.sections, id: \.title) { ArticleBlock(section: $0) }
                if !lesson.keyTerms.isEmpty {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeading(title: "Follow your curiosity")
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack { ForEach(lesson.keyTerms, id: \.self) { id in if let entry = store.entity(id) { EntityChip(entry: entry) } } }
                        }
                    }
                }
                review
                if correct || store.completedLessons.contains(lesson.id) {
                    Button { store.complete(lesson) } label: {
                        PrimaryLabel(title: store.completedLessons.contains(lesson.id) ? "Lesson completed" : "Complete lesson", symbol: "checkmark.circle")
                    }.disabled(store.completedLessons.contains(lesson.id)).accessibilityIdentifier("completeLesson")
                    if let next = store.lessons.first(where: { $0.number == lesson.number + 1 }) {
                        NavigationLink(value: Route.lesson(next.id)) { PrimaryLabel(title: "Next: \(next.title)") }.buttonStyle(.plain)
                    }
                }
                if !lesson.bookIDs.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeading(title: "Into the library")
                        ForEach(lesson.bookIDs, id: \.self) { id in if let book = store.book(id) { CompactBookRow(book: book) } }
                    }
                }
                Text("Hindu App learning guide · Original introductory commentary").font(.caption).foregroundStyle(Palette.muted)
                SourceNotes(sources: lesson.sources)
            }.padding(24).frame(maxWidth: 740).frame(maxWidth: .infinity)
        }.readingPage().navigationTitle("Your journey").navigationBarTitleDisplayMode(.inline)
            .toolbar { SaveButton(id: "lesson:\(lesson.id)", title: lesson.title, subtitle: "Lesson \(lesson.number)", route: .lesson(lesson.id)) }
    }

    private var review: some View {
        VStack(alignment: .leading, spacing: 16) {
            Eyebrow(text: "Pause & reflect")
            Text(lesson.question).font(.system(.title3, design: .serif)).foregroundStyle(Palette.ink)
            ForEach(Array(lesson.answers.enumerated()), id: \.offset) { index, value in
                Button { answer = index } label: {
                    HStack(alignment: .top, spacing: 11) {
                        Image(systemName: answer == index ? (correct ? "checkmark.circle.fill" : "circle.inset.filled") : "circle")
                        Text(value).multilineTextAlignment(.leading)
                    }.font(.subheadline).foregroundStyle(Palette.ink).frame(maxWidth: .infinity, alignment: .leading).padding(15)
                        .background(answer == index ? Palette.paleGold.opacity(0.5) : Palette.card, in: RoundedRectangle(cornerRadius: 13))
                        .overlay(RoundedRectangle(cornerRadius: 13).strokeBorder(answer == index ? Palette.gold : Palette.line))
                }.accessibilityIdentifier("answer-\(index)")
            }
            if let _ = answer {
                Text(correct ? lesson.explanation : "Take another look. \(lesson.explanation)")
                    .font(.subheadline).foregroundStyle(Palette.ink).lineSpacing(5).accessibilityIdentifier("answerExplanation")
            }
        }.padding(20).background(Palette.paleGold.opacity(0.2), in: RoundedRectangle(cornerRadius: 20))
    }
}

struct SavedView: View {
    @Environment(LearningStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                PageHeading(eyebrow: "Your personal collection", title: "Keep what moves you.", subtitle: "Books, passages, people, and ideas to return to.")
                if store.saved.isEmpty { EmptyState(symbol: "bookmark", title: "Room for discovery", detail: "Tap the bookmark on any page to save it here. Your collection stays on this device.") }
                ForEach(store.saved) { item in
                    HStack {
                        NavigationLink(value: item.route) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(item.title).font(.system(.headline, design: .serif)).foregroundStyle(Palette.ink)
                                Text(item.subtitle).font(.caption).foregroundStyle(Palette.muted).lineLimit(2)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }.buttonStyle(.plain)
                        Button { store.toggleSave(id: item.id, title: item.title, subtitle: item.subtitle, route: item.route) } label: { Image(systemName: "bookmark.fill").frame(width: 44, height: 44) }.accessibilityLabel("Remove \(item.title) from saved pages")
                    }.padding(16).background(Palette.card, in: RoundedRectangle(cornerRadius: 16))
                }
            }.padding(24).frame(maxWidth: 740).frame(maxWidth: .infinity)
        }.readingPage().navigationTitle("Saved pages").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
    }
}

struct AboutView: View {
    @Environment(LearningStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 25) {
                LotusMark().frame(width: 70, height: 70)
                PageHeading(eyebrow: "Our approach", title: "An open door.\nAn endless inquiry.", subtitle: "Hindu App is a place to begin learning, and to keep asking.")
                ArticleBlock(section: .init(title: "Many traditions, in their own voices", text: "Hindu traditions differ in theology, philosophy, ritual, language, and region. We name perspectives and textual contexts rather than present one interpretation as universal. The atlas includes revered deities, epic figures, teachers, and concepts."))
                ArticleBlock(section: .init(title: "Know what you are reading", text: "The library separates historical translations from Hindu App’s original introductory guides. Each book names its edition, source, and coverage. Public-domain translations can contain dated language and interpretations; no single English rendering represents the whole tradition."))
                ArticleBlock(section: .init(title: "An expanding library", text: "This edition has \(store.books.count) catalog entries, \(store.books.filter(\.isReadable).count) with offline reading, and \(store.entries.count) atlas entries. Catalog guides point to further sources when a reviewed text is not bundled. It is a starting collection, not every Hindu scripture."))
                ArticleBlock(section: .init(title: "A quiet space, on your device", text: "Reading, search, saved passages, and lesson progress work offline. There is no account, tracking, or advertising. External source links open the cited website and require a connection. Your progress is stored locally."))
                ArticleBlock(section: .init(title: "Images that invite curiosity", text: "The lotus artwork is an original AI-generated illustration. Interactive cosmology diagrams are interpretive teaching aids. They describe particular textual traditions, not an astronomical reconstruction."))
                Text("HINDU APP · FIRST EDITION").font(.caption2).tracking(2).foregroundStyle(Palette.gold)
            }.padding(24).frame(maxWidth: 740).frame(maxWidth: .infinity)
        }.readingPage().navigationTitle("About Hindu App").navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
    }
}
