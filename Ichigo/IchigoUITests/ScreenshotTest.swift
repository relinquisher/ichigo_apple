import XCTest

final class ScreenshotTest: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = true
        app.launch()
        sleep(3)
    }

    func testTakeAllScreenshots() {
        // 1. Home screen
        sleep(1)
        takeScreenshot(name: "01_home")

        // 2. Start quiz
        let quizButton = app.buttons["クイズを始める"]
        guard quizButton.waitForExistence(timeout: 5) else {
            XCTFail("クイズボタンが見つからない")
            return
        }
        quizButton.tap()
        sleep(2)

        // 3. Quiz screen (before answering)
        takeScreenshot(name: "02_quiz")

        // 4. Answer a question (tap first choice)
        tapFirstChoice()
        sleep(1)

        // 5. Answered state
        takeScreenshot(name: "03_answered")

        // 6. Complete all remaining questions
        completeQuiz()

        // 7. Results screen
        let results = app.staticTexts["アセスメント結果"]
        if results.waitForExistence(timeout: 10) {
            sleep(1)
            takeScreenshot(name: "04_results")
        }

        // 8. Go home
        let homeButton = app.buttons["ホームに戻る"]
        if homeButton.waitForExistence(timeout: 5) {
            homeButton.tap()
            sleep(1)
        }

        // 9. Settings screen
        let gear = app.buttons["gearshape.fill"]
        if gear.waitForExistence(timeout: 5) {
            gear.tap()
            sleep(1)
            takeScreenshot(name: "05_settings")
        }
    }

    // MARK: - Helpers

    private func takeScreenshot(name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        // Also save to screenshots directory via simctl
        let path = "/Users/teramotojinta/Documents/ichigo_apple/screenshots/\(name).png"
        let data = screenshot.pngRepresentation
        try? data.write(to: URL(fileURLWithPath: path))
    }

    private func tapFirstChoice() {
        let allButtons = app.buttons.allElementsBoundByIndex
        for button in allButtons {
            let label = button.label
            if ["次の問題", "結果を見る", "復習に行く", "例文を見る", "続ける", "ホームに戻る",
                "クイズを始める", "gearshape.fill", "speaker.wave.2.fill", "クイズ", "復習"].contains(label) {
                continue
            }
            if label.isEmpty { continue }
            if button.isHittable {
                button.tap()
                return
            }
        }
    }

    private func completeQuiz() {
        for _ in 0..<30 {
            // Tap next/review/results
            let nextButton = app.buttons["次の問題"]
            let resultsButton = app.buttons["結果を見る"]
            let reviewButton = app.buttons["復習に行く"]

            if nextButton.waitForExistence(timeout: 2) {
                nextButton.tap()
                sleep(1)
                tapFirstChoice()
                sleep(1)
            } else if reviewButton.waitForExistence(timeout: 1) {
                reviewButton.tap()
                sleep(1)
                tapFirstChoice()
                sleep(1)
            } else if resultsButton.waitForExistence(timeout: 1) {
                resultsButton.tap()
                sleep(1)
                break
            } else {
                // Maybe waiting for timer
                sleep(2)
                tapFirstChoice()
                sleep(1)
            }

            // Check if we're on results screen
            if app.staticTexts["アセスメント結果"].exists {
                break
            }
        }
    }
}
