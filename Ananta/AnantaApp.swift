import SwiftUI

@main
struct AnantaApp: App {
    @State private var store = LearningStore()
    var body: some Scene {
        WindowGroup {
            AppRootView().environment(store).tint(Palette.ink)
        }
    }
}

enum AppTab: String { case journey, library, cosmos, atlas, search }

struct AppRootView: View {
    @Environment(LearningStore.self) private var store
    @State private var selectedTab: AppTab = .journey

    var body: some View {
        Group {
            if store.isLoaded {
                TabView(selection: $selectedTab) {
                    NavigationStack { JourneyView(selectedTab: $selectedTab).routeDestinations() }
                        .tabItem { Label("Journey", systemImage: "leaf") }.tag(AppTab.journey)
                    NavigationStack { LibraryView().routeDestinations() }
                        .tabItem { Label("Library", systemImage: "books.vertical") }.tag(AppTab.library)
                    NavigationStack { CosmosView().routeDestinations() }
                        .tabItem { Label("Cosmos", systemImage: "sparkles") }.tag(AppTab.cosmos)
                    NavigationStack { AtlasView().routeDestinations() }
                        .tabItem { Label("Atlas", systemImage: "point.3.connected.trianglepath.dotted") }.tag(AppTab.atlas)
                    NavigationStack { SearchView().routeDestinations() }
                        .tabItem { Label("Search", systemImage: "magnifyingglass") }.tag(AppTab.search)
                }
                .tint(selectedTab == .cosmos ? Palette.paleGold : Palette.ink)
            } else if let error = store.loadError {
                VStack(spacing: 20) {
                    EmptyState(symbol: "books.vertical", title: "The library couldn’t open", detail: error)
                    Button("Try again") { Task { await store.load() } }.buttonStyle(.borderedProminent)
                }
            } else {
                VStack(spacing: 20) {
                    LotusMark().frame(width: 74, height: 74)
                    Text("Hindu App").font(.editorial(40)).foregroundStyle(Palette.ink)
                    ProgressView("Opening your library").font(.caption).tint(Palette.gold)
                }.frame(maxWidth: .infinity, maxHeight: .infinity).background(Palette.paper)
            }
        }
        .preferredColorScheme(selectedTab == .cosmos ? .dark : .light)
        .task { await store.load() }
    }
}

struct RouteDestinations: ViewModifier {
    @Environment(LearningStore.self) private var store
    func body(content: Content) -> some View {
        content.navigationDestination(for: Route.self) { route in
            switch route {
            case .book(let id):
                if let book = store.book(id) { BookDetailView(book: book) }
                else { missing }
            case .entity(let id):
                if let entry = store.entity(id) { EntityDetailView(entry: entry) }
                else { missing }
            case .lesson(let id):
                if let lesson = store.lesson(id) { LessonDetailView(lesson: lesson) }
                else { missing }
            case .reader(let bookID, let chapterID, let passage):
                if let book = store.book(bookID), let chapter = book.chapters.first(where: { $0.id == chapterID }) {
                    ReaderView(book: book, initialChapterID: chapter.id, initialPassageID: passage)
                } else { missing }
            }
        }
    }
    private var missing: some View { EmptyState(symbol: "link", title: "Page unavailable", detail: "This saved page is not in the current edition of the library.") }
}

extension View {
    func routeDestinations() -> some View { modifier(RouteDestinations()) }
    func readingPage() -> some View {
        self.background(Palette.paper).toolbarBackground(Palette.paper, for: .navigationBar).toolbarBackground(.visible, for: .navigationBar)
    }
}
