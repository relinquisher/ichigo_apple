import Foundation

/// Word selection engine for assessment and study modes.
///
/// Ported from the Android Kotlin implementation. Uses IRT-based scoring
/// with slot-based role assignment for balanced assessment sessions.
///
/// The selector uses a multi-slot strategy:
/// - Slots 1-6 (Precision): Fisher info * exam weight * SRS penalty * mistake bonus
/// - Slots 7-8 (Exam-focused): High exam frequency, unmastered words
/// - Slots 9-10 (Challenge/Discovery): Beginner=unseen, Advanced=above theta
class WordSelector {

    private let irtEngine: IrtEngine

    init(irtEngine: IrtEngine) {
        self.irtEngine = irtEngine
    }

    // MARK: - Assessment Word Selection

    /// Select words for an assessment session using slot-based roles.
    ///
    /// All slots respect SRS penalty (24h block). Beginner mode applies
    /// a difficulty cap to prevent overwhelming new learners.
    ///
    /// - Parameters:
    ///   - words: All available words for the grade
    ///   - stats: Current user statistics
    ///   - progressMap: Map of wordId -> StudyProgress
    ///   - count: Number of words to select (default: 10)
    ///   - isBeginnerMode: Whether beginner difficulty cap applies
    /// - Returns: Shuffled array of selected words
    func selectAssessmentWords(
        words: [Word],
        stats: UserStats,
        progressMap: [Int: StudyProgress] = [:],
        count: Int = IrtConstants.assessmentQuestionCount,
        isBeginnerMode: Bool = false
    ) -> [Word] {
        var selectedIds = Set<Int>()
        var selected: [Word] = []

        // Eligible words: exclude 24h SRS block
        var eligible = words.filter { srsPenalty(progress: progressMap[$0.id]) > 0 }

        // Beginner mode: apply difficulty cap
        if isBeginnerMode {
            let cap = stats.theta + IrtConstants.beginnerDifficultyCap
            eligible = eligible.filter { $0.difficulty <= cap }
        }

        // --- Slots 1-6: Precision (Fisher x ExamFreq x SRS x MistakeBonus, weighted random) ---
        let precisionCount = max(Int(Float(count) * 0.6), 1) // 6 for count=10
        var precisionCandidates: [(Word, Float)] = eligible.map { word in
            let catTheta = irtEngine.getCategoryTheta(stats: stats, category: word.category)
            let fisherInfo = irtEngine.fisherInformation(theta: catTheta, difficulty: word.difficulty)
            let examWeight = examScoreWeight(word: word)
            let penalty = srsPenalty(progress: progressMap[word.id])
            let missBonus = mistakeBonus(progress: progressMap[word.id])
            return (word, fisherInfo * examWeight * penalty * missBonus)
        }

        for _ in 0..<precisionCount {
            guard let word = weightedPick(candidates: &precisionCandidates) else { break }
            if !selectedIds.contains(word.id) {
                selected.append(word)
                selectedIds.insert(word.id)
            }
        }

        // --- Slots 7-8: Exam-focused (high examFrequency, unmastered) ---
        let examCount = max(Int(Float(count) * 0.2), 1) // 2 for count=10
        var examCandidates: [(Word, Float)] = eligible
            .filter { !selectedIds.contains($0.id) }
            .filter { word in
                let progress = progressMap[word.id]
                return progress == nil || !progress!.isLearned // unmastered
            }
            .map { word in
                let penalty = srsPenalty(progress: progressMap[word.id])
                return (word, Float(word.examFrequency) * penalty)
            }
            .filter { $0.1 > 0 }

        for _ in 0..<examCount {
            guard let word = weightedPick(candidates: &examCandidates) else { break }
            if !selectedIds.contains(word.id) {
                selected.append(word)
                selectedIds.insert(word.id)
            }
        }

        // --- Slots 9-10: Challenge/Discovery ---
        let remainingCount = count - selected.count
        let globalTheta = stats.theta

        let slotCandidates: [Word]
        if isBeginnerMode {
            // Beginner: Discovery -- pick unseen words (never studied) within difficulty cap
            slotCandidates = eligible
                .filter { !selectedIds.contains($0.id) }
                .filter { progressMap[$0.id] == nil }
                .shuffled()
        } else {
            // Advanced: Challenge -- slightly harder than current ability
            slotCandidates = eligible
                .filter { !selectedIds.contains($0.id) }
                .filter { $0.difficulty >= globalTheta + 0.3 }
                .shuffled()
        }

        let randomFallback = eligible
            .filter { !selectedIds.contains($0.id) }
            .shuffled()

        let slotCandidateIds = Set(slotCandidates.map { $0.id })
        let finalPool: [Word]
        if slotCandidates.count >= remainingCount {
            finalPool = slotCandidates
        } else {
            finalPool = slotCandidates + randomFallback.filter { !slotCandidateIds.contains($0.id) }
        }

        for word in finalPool {
            if selected.count >= count { break }
            if !selectedIds.contains(word.id) {
                selected.append(word)
                selectedIds.insert(word.id)
            }
        }

        return selected.shuffled()
    }

    // MARK: - Priority-Based Selection (CAT Mode)

    /// Select the next word using priority-based scoring with epsilon-greedy exploration.
    ///
    /// Priority = examScoreWeight * (1 - userAccuracy) * forgettingCurveFactor
    /// "出やすくて、苦手で、忘れかけている語" (frequent, weak, forgetting) prioritized.
    ///
    /// - Parameters:
    ///   - words: Candidate words
    ///   - stats: Current user statistics
    ///   - progressMap: Map of wordId -> StudyProgress
    ///   - allWords: All words (unused, kept for API compatibility)
    ///   - recentWordIds: Recently shown word IDs to exclude
    /// - Returns: The selected word, or nil if no candidates
    func selectNextWord(
        words: [Word],
        stats: UserStats,
        progressMap: [Int: StudyProgress],
        allWords: [Word],
        recentWordIds: Set<Int> = []
    ) -> Word? {
        let candidates = words.filter { !recentWordIds.contains($0.id) }
        if candidates.isEmpty { return words.randomElement() }

        // Epsilon-greedy: random exploration
        if Float.random(in: 0..<1) < IrtConstants.epsilon {
            return candidates.randomElement()
        }

        let scored = candidates.map { word -> (Word, Float) in
            let progress = progressMap[word.id]

            // Factor 1: Exam frequency weight
            let examWeight = examScoreWeight(word: word)

            // Factor 2: Weakness = 1 - accuracy
            let weakness: Float = 1.0 - userAccuracy(progress: progress)

            // Factor 3: Forgetting curve
            let forgetFactor = irtEngine.forgetRisk(lastStudiedAt: progress?.lastStudiedAt ?? 0)

            let priority = examWeight * weakness * forgetFactor
            return (word, priority)
        }

        return scored.max(by: { $0.1 < $1.1 })?.0
    }

    // MARK: - Helper Methods

    /// Calculate exam frequency weight for a word.
    /// Higher frequency in past exams = higher score.
    private func examScoreWeight(word: Word) -> Float {
        return IrtConstants.examFreqBase + IrtConstants.examFreqPer * Float(word.examFrequency)
    }

    /// Calculate user accuracy for a word (0.0 = never correct, 1.0 = always correct).
    /// Returns 0.0 for unstudied words (treat as unknown).
    private func userAccuracy(progress: StudyProgress?) -> Float {
        guard let progress = progress else { return 0.0 }
        let total = progress.correctCount + progress.incorrectCount
        if total == 0 { return 0.0 }
        return Float(progress.correctCount) / Float(total)
    }

    /// SRS penalty based on time since last study.
    ///
    /// - Within 24h: 0.0 (block -- don't show)
    /// - Within 3 days: 0.3
    /// - Within 7 days: 0.6
    /// - Beyond 7 days or never studied: 1.0
    ///
    /// - Parameter progress: Study progress for the word, or nil if never studied
    /// - Returns: SRS penalty multiplier in [0, 1]
    func srsPenalty(progress: StudyProgress?) -> Float {
        guard let progress = progress, progress.lastStudiedAt != 0 else { return 1.0 }
        let nowMs = Int64(Date().timeIntervalSince1970 * 1000.0)
        let elapsedMs = nowMs - progress.lastStudiedAt
        let elapsedHours = Double(elapsedMs) / (1000.0 * 60.0 * 60.0)
        switch elapsedHours {
        case ..<24:
            return 0.0
        case ..<72:
            return 0.3
        case ..<168:
            return 0.6
        default:
            return 1.0
        }
    }

    /// Weighted random pick from a scored list. Removes the picked item.
    ///
    /// If total weight is zero or negative, picks the first item.
    ///
    /// - Parameter candidates: Mutable array of (Word, weight) pairs
    /// - Returns: The selected word, or nil if candidates is empty
    func weightedPick(candidates: inout [(Word, Float)]) -> Word? {
        if candidates.isEmpty { return nil }
        let totalWeight = candidates.reduce(0.0) { $0 + Double($1.1) }
        if totalWeight <= 0.0 {
            return candidates.removeFirst().0
        }

        var roll = Double.random(in: 0..<totalWeight)
        for i in candidates.indices {
            roll -= Double(candidates[i].1)
            if roll <= 0 {
                return candidates.remove(at: i).0
            }
        }
        return candidates.removeLast().0
    }

    /// Mistake bonus: 1.0 + 0.3 per incorrect answer, capped at 3.0.
    ///
    /// Words the user has gotten wrong more often get a higher score boost
    /// to prioritize re-testing.
    ///
    /// - Parameter progress: Study progress for the word, or nil if never studied
    /// - Returns: Mistake bonus multiplier in [1.0, 3.0]
    func mistakeBonus(progress: StudyProgress?) -> Float {
        guard let progress = progress else { return 1.0 }
        return min(1.0 + 0.3 * Float(progress.incorrectCount), 3.0)
    }
}
