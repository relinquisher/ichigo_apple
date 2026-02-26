import Foundation

/// IRT (Item Response Theory) engine implementing the 1PL logistic model.
///
/// Ported from the Android Kotlin implementation. This is a pure computation class
/// with no UI or persistence dependencies. It operates on Word and UserStats model
/// objects directly.
///
/// The engine handles:
/// - Probability calculation (1PL logistic function)
/// - Fisher information for item selection
/// - Theta (ability) updates for global and category-specific parameters
/// - Variance tracking via Fisher information
/// - Pass probability estimation with category weighting
/// - Mastery counting and forgetting curve risk
class IrtEngine {

    // MARK: - Core IRT Functions

    /// Calculate probability of correct response using the 1PL logistic model.
    ///
    /// P = 1 / (1 + exp(-a * (theta - difficulty)))
    ///
    /// - Parameters:
    ///   - theta: Current ability estimate
    ///   - difficulty: Item difficulty parameter
    /// - Returns: Probability clamped to [0.001, 0.999]
    func probability(theta: Float, difficulty: Float) -> Float {
        let a = IrtConstants.discrimination
        let exponent = -a * (theta - difficulty)
        let p = 1.0 / (1.0 + exp(exponent))
        return min(max(p, 0.001), 0.999)
    }

    /// Calculate Fisher Information for an item at a given theta.
    ///
    /// I = a^2 * P * (1 - P)
    ///
    /// Higher information means the item is more discriminating at this ability level.
    ///
    /// - Parameters:
    ///   - theta: Current ability estimate
    ///   - difficulty: Item difficulty parameter
    /// - Returns: Fisher information value
    func fisherInformation(theta: Float, difficulty: Float) -> Float {
        let a = IrtConstants.discrimination
        let p = probability(theta: theta, difficulty: difficulty)
        return a * a * p * (1.0 - p)
    }

    /// Update theta after an answer.
    ///
    /// - Correct: theta += learningRate * (1 - P)
    /// - Incorrect: theta -= lr * P (lr is reduced in beginner mode)
    ///
    /// - Parameters:
    ///   - currentTheta: Current ability estimate
    ///   - difficulty: Item difficulty parameter
    ///   - isCorrect: Whether the answer was correct
    ///   - isBeginnerMode: Whether beginner dampening applies
    /// - Returns: Updated theta value
    func updateTheta(currentTheta: Float, difficulty: Float, isCorrect: Bool, isBeginnerMode: Bool = false) -> Float {
        let p = probability(theta: currentTheta, difficulty: difficulty)
        if isCorrect {
            return currentTheta + IrtConstants.learningRate * (1.0 - p)
        } else {
            let lr = isBeginnerMode ? IrtConstants.beginnerLearningRate : IrtConstants.learningRate
            return currentTheta - lr * p
        }
    }

    /// Calculate delta theta (preview of change without applying).
    ///
    /// - Parameters:
    ///   - currentTheta: Current ability estimate
    ///   - difficulty: Item difficulty parameter
    ///   - isCorrect: Whether the answer was correct
    /// - Returns: The theta change that would result
    func deltaTheta(currentTheta: Float, difficulty: Float, isCorrect: Bool) -> Float {
        let p = probability(theta: currentTheta, difficulty: difficulty)
        let lr = IrtConstants.learningRate
        if isCorrect {
            return lr * (1.0 - p)
        } else {
            return -(lr * p)
        }
    }

    /// Update variance using Fisher Information.
    ///
    /// newVariance = 1 / (1/oldVariance + FisherInfo)
    ///
    /// - Parameters:
    ///   - currentVariance: Current variance estimate
    ///   - theta: Current ability estimate
    ///   - difficulty: Item difficulty parameter
    /// - Returns: Updated variance clamped to [0.01, 10.0]
    func updateVariance(currentVariance: Float, theta: Float, difficulty: Float) -> Float {
        let info = fisherInformation(theta: theta, difficulty: difficulty)
        let newVariance = 1.0 / (1.0 / currentVariance + info)
        return min(max(newVariance, 0.01), 10.0)
    }

    // MARK: - Category Theta

    /// Get category-specific theta from UserStats.
    ///
    /// Maps Japanese category names to the corresponding theta field.
    /// Falls back to global theta for unknown categories.
    ///
    /// - Parameters:
    ///   - stats: User statistics containing per-category thetas
    ///   - category: Japanese category name (動詞, 名詞, 形容詞, 副詞)
    /// - Returns: The category-specific theta value
    func getCategoryTheta(stats: UserStats, category: String) -> Float {
        switch category {
        case "形容詞":
            return stats.thetaAdjective
        case "動詞":
            return stats.thetaVerb
        case "名詞":
            return stats.thetaNoun
        case "副詞":
            return stats.thetaAdverb
        default:
            return stats.theta
        }
    }

    /// Update category-specific theta in UserStats (mutates in place).
    ///
    /// - Parameters:
    ///   - stats: User statistics to update (SwiftData @Model, reference type)
    ///   - category: Japanese category name
    ///   - newTheta: The new theta value for the category
    func updateCategoryTheta(stats: UserStats, category: String, newTheta: Float) {
        switch category {
        case "形容詞": stats.thetaAdjective = newTheta
        case "動詞": stats.thetaVerb = newTheta
        case "名詞": stats.thetaNoun = newTheta
        case "副詞": stats.thetaAdverb = newTheta
        default: break
        }
    }

    // MARK: - Pass Probability

    /// Calculate weighted pass probability across all categories.
    ///
    /// For each category, computes the average P(correct) using category-specific theta
    /// across all words in that category, then takes the weighted average.
    ///
    /// - Parameters:
    ///   - stats: User statistics with per-category thetas
    ///   - words: All words to consider
    ///   - categoryWeights: Category weight map (defaults to standard weights)
    /// - Returns: Weighted pass probability in [0, 1]
    func calculatePassProbability(
        stats: UserStats,
        words: [Word],
        categoryWeights: [String: Float] = IrtConstants.categoryWeights
    ) -> Float {
        // Group words by category
        var categoryWords: [String: [Word]] = [:]
        for word in words {
            categoryWords[word.category, default: []].append(word)
        }

        var weightedSum: Float = 0.0
        var totalWeight: Float = 0.0

        for (category, weight) in categoryWeights {
            guard let wordsInCategory = categoryWords[category], !wordsInCategory.isEmpty else {
                continue
            }
            let categoryTheta = getCategoryTheta(stats: stats, category: category)
            let probabilities = wordsInCategory.map { probability(theta: categoryTheta, difficulty: $0.difficulty) }
            let avgProb = probabilities.reduce(0, +) / Float(probabilities.count)
            weightedSum += weight * avgProb
            totalWeight += weight
        }

        return totalWeight > 0 ? weightedSum / totalWeight : 0.0
    }

    // MARK: - Mastery

    /// Count "mastered" words: studied words where P(correct) > 0.8.
    ///
    /// A word is mastered when:
    /// 1. It has been studied (its ID is in studiedWordIds)
    /// 2. The probability of answering correctly exceeds 0.8
    ///
    /// - Parameters:
    ///   - stats: User statistics with per-category thetas
    ///   - words: All words to check
    ///   - studiedWordIds: Set of word IDs that have been studied
    /// - Returns: Count of mastered words
    func countMasteredWords(stats: UserStats, words: [Word], studiedWordIds: Set<Int> = []) -> Int {
        return words.filter { word in
            studiedWordIds.contains(word.id) &&
            probability(theta: getCategoryTheta(stats: stats, category: word.category), difficulty: word.difficulty) > 0.8
        }.count
    }

    // MARK: - Forgetting Curve

    /// Calculate forgetting risk based on time since last study.
    ///
    /// Uses exponential decay: risk = 1 - exp(-lambda * elapsed_ms)
    /// Words never studied (lastStudiedAt == 0) return maximum risk of 1.0.
    ///
    /// - Parameter lastStudiedAt: Timestamp in milliseconds of last study, or 0 if never studied
    /// - Returns: Forgetting risk in [0, 1]
    func forgetRisk(lastStudiedAt: Int64) -> Float {
        if lastStudiedAt == 0 { return 1.0 }
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000.0)
        let elapsed = Float(nowMs - lastStudiedAt)
        let risk = 1.0 - exp(-IrtConstants.lambda * elapsed)
        return min(max(risk, 0.0), 1.0)
    }

    // MARK: - Full Answer Processing

    /// Process a full IRT answer update.
    ///
    /// Updates in order:
    /// 1. Global theta
    /// 2. Category-specific theta
    /// 3. Variance
    /// 4. Total answered counter
    ///
    /// - Parameters:
    ///   - stats: Current user statistics
    ///   - word: The word that was answered
    ///   - isCorrect: Whether the answer was correct
    ///   - isBeginnerMode: Whether beginner dampening applies
    /// - Returns: Tuple of (updatedStats, deltaTheta)
    func processAnswer(
        stats: UserStats,
        word: Word,
        isCorrect: Bool,
        isBeginnerMode: Bool = false
    ) -> (UserStats, Float) {
        let oldTheta = stats.theta
        let newTheta = updateTheta(currentTheta: oldTheta, difficulty: word.difficulty, isCorrect: isCorrect, isBeginnerMode: isBeginnerMode)
        let dt = newTheta - oldTheta

        let catTheta = getCategoryTheta(stats: stats, category: word.category)
        let newCatTheta = updateTheta(currentTheta: catTheta, difficulty: word.difficulty, isCorrect: isCorrect, isBeginnerMode: isBeginnerMode)

        let newVariance = updateVariance(currentVariance: stats.thetaVariance, theta: newTheta, difficulty: word.difficulty)

        stats.theta = newTheta
        stats.thetaVariance = newVariance
        stats.totalAnswered = stats.totalAnswered + 1
        updateCategoryTheta(stats: stats, category: word.category, newTheta: newCatTheta)

        return (stats, dt)
    }
}
