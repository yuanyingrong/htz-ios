//
//  HTZNextUITests.swift
//  HTZNextUITests
//
//  Created by Mu Xueqiang on 2026/5/17.
//

import XCTest

final class HTZNextUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testSampleToneAudiblyAdvances() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-HTZTestAccount", "-HTZPlaySample"]
        app.launch()

        let bar = app.otherElements["now-playing-bar"]
        XCTAssertTrue(bar.waitForExistence(timeout: 15), "迷你条没有出现：\(app.debugDescription)")

        let playing = NSPredicate(format: "value == 'playing'")
        let expectation = XCTNSPredicateExpectation(predicate: playing, object: bar)
        let result = XCTWaiter.wait(for: [expectation], timeout: 12)
        XCTAssertEqual(result, .completed, "音频没有往前走，当前状态：\(bar.value ?? "nil")")
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
