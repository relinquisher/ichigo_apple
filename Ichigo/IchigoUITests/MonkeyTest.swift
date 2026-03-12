import XCTest

final class MonkeyTest: XCTestCase {

    let app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = true
        app.launch()
        // Wait for home screen to load
        sleep(2)
    }

    // MARK: - 1. ホーム画面の基本表示

    func testHomeScreenLoads() {
        XCTAssertTrue(app.staticTexts["英検 単語学習"].waitForExistence(timeout: 5),
                      "ホーム画面のタイトルが表示されること")
    }

    // MARK: - 2. 級切り替え

    func testGradeToggle() {
        let gradeButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS '級'"))
        if gradeButtons.count >= 2 {
            gradeButtons.element(boundBy: 0).tap()
            sleep(1)
            gradeButtons.element(boundBy: 1).tap()
            sleep(1)
            // Should not crash
        }
    }

    // MARK: - 3. クイズ開始→回答→結果→ホームに戻る

    func testFullQuizFlowToHome() {
        startQuiz()
        answerAllQuestions()
        // Results screen
        let resultsTitle = app.staticTexts["アセスメント結果"]
        XCTAssertTrue(resultsTitle.waitForExistence(timeout: 10),
                      "結果画面が表示されること")
        // Go home
        let homeButton = app.buttons["ホームに戻る"]
        if homeButton.waitForExistence(timeout: 5) {
            homeButton.tap()
            sleep(1)
            XCTAssertTrue(app.staticTexts["英検 単語学習"].waitForExistence(timeout: 5),
                          "ホーム画面に戻ること")
        }
    }

    // MARK: - 4. クイズ→結果→続ける→結果→ホーム（スタック蓄積テスト）

    func testContinueButtonDoesNotAccumulateStack() {
        for round in 1...3 {
            startQuiz()
            answerAllQuestions()
            let resultsTitle = app.staticTexts["アセスメント結果"]
            XCTAssertTrue(resultsTitle.waitForExistence(timeout: 10),
                          "ラウンド\(round): 結果画面が表示されること")

            if round < 3 {
                let continueButton = app.buttons["続ける"]
                XCTAssertTrue(continueButton.waitForExistence(timeout: 5),
                              "ラウンド\(round): 続けるボタンが表示されること")
                continueButton.tap()
                sleep(2)
            }
        }
        // After 3 rounds, go home
        let homeButton = app.buttons["ホームに戻る"]
        if homeButton.waitForExistence(timeout: 5) {
            homeButton.tap()
            sleep(1)
            XCTAssertTrue(app.staticTexts["英検 単語学習"].waitForExistence(timeout: 5),
                          "3ラウンド後にホーム画面に戻れること")
        }
    }

    // MARK: - 5. クイズ中のスワイプバック無効確認

    func testSwipeBackDisabledDuringQuiz() {
        startQuiz()
        sleep(1)
        // Swipe from left edge
        let coord = app.coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.5))
        let dest = app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
        coord.press(forDuration: 0.1, thenDragTo: dest)
        sleep(1)
        // Should still be on quiz screen, not home
        XCTAssertFalse(app.staticTexts["英検 単語学習"].exists,
                       "クイズ中にスワイプバックでホームに戻らないこと")
    }

    // MARK: - 6. タイムアウトテスト（回答しない）

    func testTimerTimeout() {
        startQuiz()
        // Wait for timer to expire (max 10 seconds + buffer)
        sleep(12)
        // Should show incorrect state (orange) or next button
        let nextButton = app.buttons["次の問題"]
        let resultsButton = app.buttons["結果を見る"]
        let reviewButton = app.buttons["復習に行く"]
        XCTAssertTrue(nextButton.exists || resultsButton.exists || reviewButton.exists,
                      "タイムアウト後に次の問題/結果ボタンが表示されること")
    }

    // MARK: - 7. 設定画面の遷移と復帰

    func testSettingsNavigation() {
        // From home
        tapSettingsGear()
        sleep(1)
        // Should show settings screen elements
        let timerText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'タイマー'"))
        XCTAssertTrue(timerText.count > 0, "設定画面が表示されること")
        // Go back
        app.navigationBars.buttons.firstMatch.tap()
        sleep(1)
        XCTAssertTrue(app.staticTexts["英検 単語学習"].waitForExistence(timeout: 5),
                      "設定からホームに戻れること")
    }

    // MARK: - 8. クイズ中の設定遷移

    func testSettingsFromQuiz() {
        startQuiz()
        sleep(1)
        tapSettingsGear()
        sleep(1)
        // Go back to quiz
        app.navigationBars.buttons.firstMatch.tap()
        sleep(1)
        // Should still be on quiz (not crashed)
        XCTAssertFalse(app.staticTexts["英検 単語学習"].exists,
                       "設定からクイズ画面に戻れること")
    }

    // MARK: - 9. 高速連打テスト

    func testRapidTapping() {
        startQuiz()
        sleep(1)
        // Rapidly tap multiple choice buttons
        let buttons = app.buttons
        for _ in 0..<20 {
            let count = buttons.count
            if count > 0 {
                let idx = Int.random(in: 0..<count)
                buttons.element(boundBy: idx).tap()
            }
            usleep(100_000) // 100ms
        }
        // App should not crash
        sleep(1)
        XCTAssertTrue(app.exists, "高速連打後にアプリがクラッシュしないこと")
    }

    // MARK: - 10. ランダム操作テスト（モンキーテスト）

    func testRandomActions() {
        for _ in 0..<50 {
            let action = Int.random(in: 0..<5)
            switch action {
            case 0:
                // Tap random point
                let x = CGFloat.random(in: 0.1...0.9)
                let y = CGFloat.random(in: 0.1...0.9)
                app.coordinate(withNormalizedOffset: CGVector(dx: x, dy: y)).tap()
            case 1:
                // Swipe up
                app.swipeUp()
            case 2:
                // Swipe down
                app.swipeDown()
            case 3:
                // Tap a random button
                let buttons = app.buttons
                if buttons.count > 0 {
                    buttons.element(boundBy: Int.random(in: 0..<buttons.count)).tap()
                }
            case 4:
                // Swipe from left edge
                let coord = app.coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.5))
                let dest = app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
                coord.press(forDuration: 0.05, thenDragTo: dest)
            default:
                break
            }
            usleep(300_000) // 300ms between actions
        }
        // App should still be running
        XCTAssertTrue(app.exists, "ランダム操作後にアプリがクラッシュしないこと")
    }

    // MARK: - Helpers

    private func startQuiz() {
        let quizButton = app.buttons["クイズを始める"]
        if quizButton.waitForExistence(timeout: 5) {
            quizButton.tap()
            sleep(2)
        }
    }

    private func answerAllQuestions() {
        for _ in 0..<30 { // Max questions including review
            // Try to tap a choice
            let answered = tapFirstChoice()
            if !answered { break }
            sleep(1)

            // Tap next/results/review button
            let nextButton = app.buttons["次の問題"]
            let resultsButton = app.buttons["結果を見る"]
            let reviewButton = app.buttons["復習に行く"]

            if nextButton.waitForExistence(timeout: 2) {
                nextButton.tap()
                sleep(1)
            } else if reviewButton.waitForExistence(timeout: 1) {
                reviewButton.tap()
                sleep(1)
            } else if resultsButton.waitForExistence(timeout: 1) {
                resultsButton.tap()
                sleep(1)
                break
            } else {
                break
            }
        }
    }

    private func tapFirstChoice() -> Bool {
        // Choices are plain-style buttons with Japanese text
        // Look for buttons that are likely quiz choices (not navigation/system buttons)
        let allButtons = app.buttons.allElementsBoundByIndex
        for button in allButtons {
            let label = button.label
            // Skip known non-choice buttons
            if ["次の問題", "結果を見る", "復習に行く", "例文を見る", "続ける", "ホームに戻る",
                "クイズを始める", "gearshape.fill", "speaker.wave.2.fill"].contains(label) {
                continue
            }
            if label.isEmpty { continue }
            // Likely a choice button
            if button.isHittable {
                button.tap()
                return true
            }
        }
        return false
    }

    private func tapSettingsGear() {
        let gear = app.buttons["gearshape.fill"]
        if gear.waitForExistence(timeout: 3) {
            gear.tap()
        }
    }
}
