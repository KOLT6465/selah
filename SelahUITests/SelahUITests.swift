import XCTest

final class SelahUITests: XCTestCase {
    func testApplicationLaunchesAsMenuBarUtility() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 5) || app.state == .runningBackground)
        app.terminate()
    }
}
