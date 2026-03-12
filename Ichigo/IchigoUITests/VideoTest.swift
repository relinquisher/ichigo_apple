import XCTest

final class VideoTest: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = true
        // Don't launch - app is already running for recording
        app.activate()
        sleep(1)
    }

    /// Answer several quiz questions for app preview video recording
    func testQuizFlowForVideo() {
        // Start quiz
        let quizButton = app.buttons["クイズを始める"]
        guard quizButton.waitForExistence(timeout: 5) else { return }
        quizButton.tap()
        sleep(3) // Wait for TTS to read question

        // Answer 3-4 questions with pauses for natural feel
        for i in 0..<4 {
            // Wait a moment to let the question be visible
            sleep(2)

            // Tap a choice
            tapChoice()
            sleep(2) // Show answer result + delta effect

            // Check if we have next button
            let nextButton = app.buttons["次の問題"]
            let reviewButton = app.buttons["復習に行く"]
            let resultsButton = app.buttons["結果を見る"]

            if nextButton.waitForExistence(timeout: 2) {
                nextButton.tap()
                sleep(1) // Wait for next question + TTS
            } else if reviewButton.exists {
                break
            } else if resultsButton.exists {
                break
            }

            if i >= 3 { break }
        }
    }

    private func tapChoice() {
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
}
