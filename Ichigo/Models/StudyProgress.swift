import Foundation
import SwiftData

@Model
final class StudyProgress {
    @Attribute(.unique) var wordId: Int
    var correctCount: Int
    var incorrectCount: Int
    var consecutiveCorrect: Int
    var isLearned: Bool
    var lastStudiedAt: Int64

    init(
        wordId: Int,
        correctCount: Int = 0,
        incorrectCount: Int = 0,
        consecutiveCorrect: Int = 0,
        isLearned: Bool = false,
        lastStudiedAt: Int64 = 0
    ) {
        self.wordId = wordId
        self.correctCount = correctCount
        self.incorrectCount = incorrectCount
        self.consecutiveCorrect = consecutiveCorrect
        self.isLearned = isLearned
        self.lastStudiedAt = lastStudiedAt
    }
}
