import XCTest

final class AnantaUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Journey"].waitForExistence(timeout: 30), "The bundled library should load and reveal the app tabs.")
    }

    func testJourneyReaderAndSavedBookSurviveRelaunch() {
        XCTAssertTrue(app.staticTexts["Begin with wonder."].waitForExistence(timeout: 10))
        tapAfterRevealing(app.buttons["startJourney"])
        XCTAssertTrue(app.navigationBars["Your journey"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Start with human questions"].waitForExistence(timeout: 5))
        goBack()
        XCTAssertTrue(app.buttons["startJourney"].waitForExistence(timeout: 5))

        selectTab("Library")
        tapAfterRevealing(app.buttons["book-bhagavad-gita"])
        XCTAssertTrue(app.buttons["beginReading"].waitForExistence(timeout: 10))
        let wasAlreadySaved = app.navigationBars.buttons["Remove bookmark"].exists
        if !wasAlreadySaved { tap(app.navigationBars.buttons["Save bookmark"]) }
        XCTAssertTrue(app.navigationBars.buttons["Remove bookmark"].waitForExistence(timeout: 5))
        tapAfterRevealing(app.buttons["beginReading"])
        XCTAssertTrue(app.buttons["Reading options"].waitForExistence(timeout: 10))
        let openingPassage = textBeginning("Dhritarashtra said")
        reveal(openingPassage)
        XCTAssertTrue(openingPassage.exists, "The reader must show the actual translated passage.")

        tap(app.buttons["Reading options"])
        tap(app.buttons["Reading appearance"])
        XCTAssertTrue(app.sliders["Text size"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.switches["Warm paper"].exists)
        tap(app.navigationBars.buttons["Done"])
        tap(app.buttons["Table of contents"])
        XCTAssertTrue(app.navigationBars["Contents"].waitForExistence(timeout: 5))
        tap(app.buttons["readerChapter-bhagavad-gita-02"])
        XCTAssertTrue(app.staticTexts["2. Self and discernment"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Reading options"].exists, "Selecting contents should return to the reader.")

        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["Your saved pages"].waitForExistence(timeout: 30))
        tap(app.buttons["Your saved pages"])
        let savedBook = app.buttons["Remove Bhagavad Gita from saved pages"]
        reveal(savedBook)
        XCTAssertTrue(savedBook.exists, "A saved book must survive terminating and relaunching the app.")
        // Preserve a bookmark that existed before this test.
        if !wasAlreadySaved { tap(savedBook) }
    }

    func testDharmaSearchOpensPrimaryTextAndAtlasConnectionsNavigate() {
        selectTab("Search")
        let dharmaSuggestion = app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", "Dharma")).firstMatch
        tapAfterRevealing(dharmaSuggestion)
        tap(app.buttons["Texts"])
        let primaryResult = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Primary text")).firstMatch
        XCTAssertTrue(primaryResult.waitForExistence(timeout: 15), "Dharma should return an offline primary-text match.")
        tapAfterRevealing(primaryResult)
        XCTAssertTrue(app.buttons["Table of contents"].waitForExistence(timeout: 10), "A primary-text result should open its chapter in the reader.")
        XCTAssertTrue(app.buttons["Reading options"].exists)

        selectTab("Atlas")
        let featuredKrishna = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Explore connections")).firstMatch
        tapAfterRevealing(featuredKrishna)
        XCTAssertTrue(app.navigationBars["Krishna"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Friend, teacher, beloved"].exists)
        let connections = app.staticTexts["A web of connections"]
        reveal(connections, maxSwipes: 8)
        XCTAssertTrue(connections.exists)
        let vishnu = app.buttons["Explore Vishnu"]
        tapAfterRevealing(vishnu, maxSwipes: 4)
        XCTAssertTrue(app.navigationBars["Vishnu"].waitForExistence(timeout: 10), "A connection should lead to another wiki entry.")
    }

    func testCosmosSelectionsChangeTimeAndNarrative() {
        selectTab("Cosmos")
        XCTAssertTrue(app.staticTexts["THE COSMIC ATLAS"].waitForExistence(timeout: 10))
        let slider = app.sliders["cosmos.yugaSlider"]
        reveal(slider)
        XCTAssertTrue(slider.isHittable)
        slider.adjust(toNormalizedSliderPosition: 0.98)
        XCTAssertTrue(app.staticTexts["Kali Yuga"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["432,000"].exists)
        let night = app.switches["cosmos.night"]
        tapAfterRevealing(night)
        XCTAssertTrue(app.staticTexts["The long night"].waitForExistence(timeout: 5))

        selectCosmosExperience("Ocean churning")
        let lakshmiStage = app.buttons["Step 5, The rising of Śrī"]
        tapAfterRevealing(lakshmiStage)
        XCTAssertTrue(textBeginning("Śrī, also called Lakṣmī").waitForExistence(timeout: 5))

        selectCosmosExperience("Many beginnings")
        let goldenGerm = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "The golden germ")).firstMatch
        tapAfterRevealing(goldenGerm)
        XCTAssertTrue(textBeginning("Hiraṇyagarbha, the golden germ or embryo").waitForExistence(timeout: 5))
    }

    private func selectTab(_ name: String, file: StaticString = #filePath, line: UInt = #line) {
        tap(app.tabBars.buttons[name], file: file, line: line)
    }

    private func selectCosmosExperience(_ title: String, file: StaticString = #filePath, line: UInt = #line) {
        let identifier = "cosmos.experience.\(title)"
        let button = app.buttons[identifier]
        // Restore the top of this vertical screen, then reveal a clipped horizontal chip.
        reveal(app.staticTexts["THE COSMIC ATLAS"], upwards: false, maxSwipes: 7, file: file, line: line)
        if !button.isHittable {
            let containingScrollViews = app.scrollViews.containing(.button, identifier: identifier).allElementsBoundByIndex
            if let horizontal = containingScrollViews.last {
                for _ in 0..<3 where !button.isHittable { horizontal.swipeLeft() }
            }
        }
        tap(button, file: file, line: line)
    }

    private func goBack(file: StaticString = #filePath, line: UInt = #line) {
        // The leading navigation-bar button is UIKit's native Back control.
        tap(app.navigationBars.buttons.element(boundBy: 0), file: file, line: line)
    }

    private func textBeginning(_ prefix: String) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", prefix)).firstMatch
    }

    private func tap(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: 10), "Expected control does not exist: \(element)", file: file, line: line)
        let hittable = NSPredicate(format: "hittable == true")
        let ready = XCTNSPredicateExpectation(predicate: hittable, object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [ready], timeout: 5), .completed, "Expected control is not tappable: \(element)", file: file, line: line)
        element.tap()
    }

    private func tapAfterRevealing(_ element: XCUIElement, maxSwipes: Int = 6, file: StaticString = #filePath, line: UInt = #line) {
        reveal(element, maxSwipes: maxSwipes, file: file, line: line)
        tap(element, file: file, line: line)
    }

    private func reveal(_ element: XCUIElement, upwards: Bool = true, maxSwipes: Int = 6, file: StaticString = #filePath, line: UInt = #line) {
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 10), "Expected a scrollable screen.", file: file, line: line)
        for _ in 0..<maxSwipes {
            if element.exists && element.isHittable { return }
            if upwards { scrollView.swipeUp() } else { scrollView.swipeDown() }
        }
        XCTAssertTrue(element.exists && element.isHittable, "Could not reveal the expected content after \(maxSwipes) swipes: \(element)", file: file, line: line)
    }
}
