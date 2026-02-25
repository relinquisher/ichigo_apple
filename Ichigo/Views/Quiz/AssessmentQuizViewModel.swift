import Foundation
import SwiftData

struct QuizQuestion {
    let word: Word
    let choices: [String]
    let correctIndex: Int
}

@Observable
class AssessmentQuizViewModel {
    var isLoading = true
    var currentIndex = 0
    var totalQuestions = IrtConstants.assessmentQuestionCount
    var question: QuizQuestion?
    var selectedIndex: Int?
    var isAnswered = false
    var isCorrect = false
    var isTimedOut = false
    var score = 0
    var thetaBefore: Float = 0.0
    var thetaAfter: Float = 0.0
    var passProbBefore: Float = 0.0
    var passProbability: Float = 0.0
    var deltaPassProbability: Float = 0.0
    var forgottenDecay: Float = 0.0
    var masteredCountBefore: Int = 0
    var maxDifficultyBeaten: Float = -.infinity
    var isReviewPhase = false
    var isFinished = false
    var forgettingDebuff: Float = 0
    var showDebuffOverlay = false
    var isBeginnerMode = true
    var masteredCountAfter: Int = 0
    var answerEffectsPlayed = false

    private let repository: WordRepository
    private let irtEngine = IrtEngine()
    private let wordSelector: WordSelector
    let grade: Int
    private let categoryWeights: [String: Float]

    private var allWords: [Word] = []
    private var quizWords: [Word] = []
    private var userStats: UserStats!
    private var incorrectWords: [Word] = []
    private var originalQuestionCount = 0
    private var studiedWordIds: Set<Int> = []

    init(grade: Int, repository: WordRepository) {
        self.grade = grade
        self.repository = repository
        self.wordSelector = WordSelector(irtEngine: irtEngine)
        self.categoryWeights = IrtConstants.categoryWeightsForGrade(grade)
        loadQuiz()
    }

    private func loadQuiz() {
        allWords = repository.getWordsByGrade(grade)
        userStats = repository.getUserStatsByGrade(grade)

        let progressList = repository.getAllProgressByGrade(grade)
        let progressMap = Dictionary(uniqueKeysWithValues: progressList.map { ($0.wordId, $0) })

        studiedWordIds = repository.getStudiedWordIdsByGrade(grade)
        let masteredBefore = irtEngine.countMasteredWords(stats: userStats, words: allWords, studiedWordIds: studiedWordIds)
        isBeginnerMode = masteredBefore < IrtConstants.beginnerMasteryThreshold

        quizWords = wordSelector.selectAssessmentWords(
            allWords: allWords, stats: userStats, progressMap: progressMap, isBeginnerMode: isBeginnerMode
        )
        originalQuestionCount = quizWords.count

        // Ebbinghaus forgetting debuff (advanced mode only)
        let lastSession = repository.getLatestSessionByGrade(grade)
        let debuff: Float
        if !isBeginnerMode, let session = lastSession {
            let elapsedMs = Int64(Date().timeIntervalSince1970 * 1000) - session.timestamp
            let elapsedHours = Double(elapsedMs) / (1000.0 * 60 * 60)
            if elapsedHours >= 48 { debuff = -0.05 }
            else if elapsedHours >= 24 { debuff = -0.01 }
            else { debuff = 0 }
        } else { debuff = 0 }

        if debuff != 0 {
            userStats.theta += debuff
            userStats.thetaVerb += debuff
            userStats.thetaNoun += debuff
            userStats.thetaAdjective += debuff
            userStats.thetaAdverb += debuff
        }

        userStats.sessionCount += 1
        repository.updateUserStats(userStats)

        guard !quizWords.isEmpty else { return }

        let initialPassProb = irtEngine.calculatePassProbability(stats: userStats, words: allWords, categoryWeights: categoryWeights)
        let decay: Float = lastSession.map { max(0, $0.passProbAfter - initialPassProb) } ?? 0

        thetaBefore = userStats.theta
        thetaAfter = userStats.theta
        passProbBefore = initialPassProb
        passProbability = initialPassProb
        forgottenDecay = decay
        masteredCountBefore = masteredBefore
        masteredCountAfter = masteredBefore
        forgettingDebuff = debuff
        showDebuffOverlay = debuff != 0
        totalQuestions = quizWords.count
        question = buildQuestion(index: 0)
        isLoading = false
    }

    private func buildQuestion(index: Int) -> QuizQuestion {
        let word = quizWords[index]
        let usePhrase = !word.phrase.isEmpty && !word.phraseMeaning.isEmpty
        let correctAnswer = usePhrase ? word.phraseMeaning : word.meaning

        let wrongChoices: [String]
        if usePhrase && !word.wrongChoice1.isEmpty {
            wrongChoices = [word.wrongChoice1, word.wrongChoice2, word.wrongChoice3]
        } else {
            let sameCat = allWords.filter { $0.id != word.id && $0.category == word.category }
            if sameCat.count >= 3 {
                wrongChoices = Array(sameCat.shuffled().prefix(3)).map { $0.meaning }
            } else {
                let others = allWords.filter { $0.id != word.id && $0.category != word.category }.shuffled()
                let combined = (sameCat + others)
                var seen = Set<String>()
                let unique = combined.filter { seen.insert($0.meaning).inserted }.prefix(3)
                wrongChoices = unique.map { $0.meaning }
            }
        }

        var allChoices = wrongChoices + [correctAnswer]
        allChoices.shuffle()
        let correctIdx = allChoices.firstIndex(of: correctAnswer) ?? 0
        return QuizQuestion(word: word, choices: allChoices, correctIndex: correctIdx)
    }

    func selectAnswer(_ index: Int) {
        guard !isAnswered, question != nil else { return }
        processAnswer(isCorrect: index == question!.correctIndex, selectedIndex: index)
    }

    func timeUp() {
        guard !isAnswered, question != nil else { return }
        processAnswer(isCorrect: false, selectedIndex: nil)
    }

    private func processAnswer(isCorrect: Bool, selectedIndex: Int?) {
        guard let q = question else { return }

        if !isReviewPhase {
            let (_, _) = irtEngine.processAnswer(stats: userStats, word: q.word, isCorrect: isCorrect, isBeginnerMode: isBeginnerMode)
            repository.recordIrtAnswer(wordId: q.word.id, isCorrect: isCorrect)
            repository.updateUserStats(userStats)
            if !isCorrect { incorrectWords.append(q.word) }
        }

        let newPassProb = irtEngine.calculatePassProbability(stats: userStats, words: allWords, categoryWeights: categoryWeights)

        self.selectedIndex = selectedIndex
        self.isAnswered = true
        self.isCorrect = isCorrect
        self.isTimedOut = selectedIndex == nil
        if !isReviewPhase { score += isCorrect ? 1 : 0 }
        thetaAfter = userStats.theta
        deltaPassProbability = !isReviewPhase ? newPassProb - passProbability : 0
        passProbability = newPassProb
        maxDifficultyBeaten = isCorrect ? max(maxDifficultyBeaten, q.word.difficulty) : maxDifficultyBeaten
        if !isReviewPhase {
            studiedWordIds.insert(q.word.id)
            masteredCountAfter = irtEngine.countMasteredWords(stats: userStats, words: allWords, studiedWordIds: studiedWordIds)
        }
        answerEffectsPlayed = false
    }

    func dismissDebuffOverlay() { showDebuffOverlay = false }
    func markAnswerEffectsPlayed() { answerEffectsPlayed = true }

    func nextQuestion() {
        let nextIdx = currentIndex + 1
        if nextIdx >= quizWords.count {
            if !isReviewPhase && !incorrectWords.isEmpty {
                quizWords.append(contentsOf: incorrectWords)
                incorrectWords.removeAll()
                currentIndex = nextIdx
                totalQuestions = quizWords.count
                question = buildQuestion(index: nextIdx)
                selectedIndex = nil; isAnswered = false; self.isCorrect = false; isTimedOut = false
                isReviewPhase = true
            } else {
                repository.insertSession(SessionHistory(
                    grade: grade, thetaBefore: thetaBefore, thetaAfter: userStats.theta,
                    passProbBefore: passProbBefore, passProbAfter: passProbability,
                    score: score, total: originalQuestionCount
                ))
                isFinished = true
            }
        } else {
            currentIndex = nextIdx
            question = buildQuestion(index: nextIdx)
            selectedIndex = nil; isAnswered = false; self.isCorrect = false; isTimedOut = false
        }
    }
}
