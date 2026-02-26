import Foundation

/// IRT model constants ported from the Android Kotlin implementation.
/// Uses a 1PL (Rasch) model with fixed discrimination = 1.0.
enum IrtConstants {

    // MARK: - IRT Model Parameters

    /// Discrimination parameter (fixed for 1PL model)
    static let discrimination: Float = 1.0

    /// Theta update step size for correct/incorrect answers
    static let learningRate: Float = 0.4

    // MARK: - Forgetting Curve

    /// Decay rate per millisecond. Significant forgetting after ~1 day.
    static let lambda: Float = 0.00001

    // MARK: - Exploration Rate (Epsilon-Greedy)

    /// 10% random exploration in word selection
    static let epsilon: Float = 0.1

    // MARK: - Exam Frequency Weights

    /// Base weight for words with examFrequency = 0
    static let examFreqBase: Float = 0.3

    /// Additional weight per exam appearance
    static let examFreqPer: Float = 0.7
    // Effective: freq=0 -> 0.3, freq=1 -> 1.0, freq=2 -> 1.7, freq=3 -> 2.4

    // MARK: - Category Weights (Eiken Exam Distribution)

    /// Default category weights for pass probability calculation (Pre-1 / Jun-1)
    static let categoryWeights: [String: Float] = [
        "動詞": 0.40,
        "名詞": 0.25,
        "形容詞": 0.25,
        "副詞": 0.10
    ]

    /// Returns grade-specific category weights.
    /// Grade 2 shifts weight from verbs to nouns.
    static func categoryWeightsForGrade(_ gradeId: Int) -> [String: Float] {
        switch gradeId {
        case 2:
            return [
                "動詞": 0.35,
                "名詞": 0.30,
                "形容詞": 0.25,
                "副詞": 0.10
            ]
        default:
            return categoryWeights
        }
    }

    // MARK: - Category Keys

    /// All supported category keys for theta storage
    static let categoryKeys: [String] = ["形容詞", "動詞", "名詞", "副詞"]

    // MARK: - Beginner Mode

    /// Number of mastered words before graduating from beginner mode
    static let beginnerMasteryThreshold: Int = 100

    /// Reduced learning rate for incorrect answers in beginner mode (1/4 of normal)
    static let beginnerLearningRate: Float = 0.1

    /// Difficulty cap relative to theta in beginner mode
    static let beginnerDifficultyCap: Float = 0.3

    // MARK: - Assessment Mode

    /// Fixed number of questions per assessment session
    static let assessmentQuestionCount: Int = 10

    // MARK: - Timer

    /// Timer duration in milliseconds
    static let timerDurationMs: Int64 = 4000
}
