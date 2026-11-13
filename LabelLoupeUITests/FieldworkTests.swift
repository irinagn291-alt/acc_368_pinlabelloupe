import XCTest

final class FieldworkTests: XCTestCase {
    func testInspectSaveLogAndCompare() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments += ["-registration_attempted", "YES", "-cached_content_url", ""]
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        app.buttons["desk.find"].tap()
        let search = app.textFields.firstMatch
        XCTAssertTrue(search.waitForExistence(timeout: 10))
        search.tap()
        search.typeText("Nutella")
        let cocoa = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Nutella")).firstMatch
        XCTAssertTrue(cocoa.waitForExistence(timeout: 10))
        cocoa.tap()
        let save = app.buttons["dossier.save"]
        XCTAssertTrue(save.waitForExistence(timeout: 8))
        if save.label != "Saved" { save.tap() }
        app.buttons["dossier.log"].tap()
        XCTAssertTrue(app.staticTexts["Choice added to your history"].exists || app.descendants(matching: .any)["Choice added to your history"].exists)
        app.buttons["dossier.compare"].tap()
        let slot = app.buttons["compare.pick.1"]
        if slot.exists {
            slot.tap()
            let filter = app.textFields.firstMatch
            XCTAssertTrue(filter.waitForExistence(timeout: 8))
            filter.tap()
            filter.typeText("oat")
            let breakfast = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "oat")).firstMatch
            XCTAssertTrue(breakfast.waitForExistence(timeout: 8))
            breakfast.tap()
        }
        XCTAssertTrue(app.staticTexts["Protein"].waitForExistence(timeout: 8))
        let preview = XCTAttachment(screenshot: app.screenshot())
        preview.name = "LabelLoupe-preview"
        preview.lifetime = .keepAlways
        add(preview)
        app.tabBars.buttons["Archive"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Nutella")).firstMatch.waitForExistence(timeout: 6))
        app.buttons["Choice history"].tap()
        XCTAssertTrue(app.buttons.matching(identifier: "Delete choice").firstMatch.waitForExistence(timeout: 6))
        app.terminate()
        app.launch()
        app.tabBars.buttons["Archive"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Nutella")).firstMatch.waitForExistence(timeout: 6))
    }
}
