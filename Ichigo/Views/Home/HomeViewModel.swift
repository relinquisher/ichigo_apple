import Foundation
import SwiftData

@Observable
class HomeViewModel {
    var selectedGrade: Int = 1
    var theta: Float = 0.0
    var thetaVariance: Float = 1.0
    var passProbability: Float = 0.0
    var masteredCount: Int = 0
    var totalWords: Int = 0
    var studiedCount: Int = 0
    var thetaVerb: Float = 0.0
    var thetaNoun: Float = 0.0
    var thetaAdjective: Float = 0.0
    var thetaAdverb: Float = 0.0
    var totalAnswered: Int = 0
    var isLoading: Bool = true
    var grade2Available: Bool = false

    private let repository: WordRepository
    private let irtEngine = IrtEngine()

    init(repository: WordRepository) {
        self.repository = repository
        loadData()
    }

    func selectGrade(_ grade: Int) {
        selectedGrade = grade
        loadData()
    }

    func loadData() {
        isLoading = true
        let grade = selectedGrade
        let words = repository.getWordsByGrade(grade)
        let stats = repository.getUserStatsByGrade(grade)
        let studiedIds = repository.getStudiedWordIdsByGrade(grade)
        let categoryWeights = IrtConstants.categoryWeightsForGrade(grade)

        theta = stats.theta
        thetaVariance = stats.thetaVariance
        thetaVerb = stats.thetaVerb
        thetaNoun = stats.thetaNoun
        thetaAdjective = stats.thetaAdjective
        thetaAdverb = stats.thetaAdverb
        totalAnswered = stats.totalAnswered
        totalWords = words.count
        studiedCount = repository.getStudiedCountByGrade(grade)
        passProbability = irtEngine.calculatePassProbability(stats: stats, words: words, categoryWeights: categoryWeights)
        masteredCount = irtEngine.countMasteredWords(stats: stats, words: words, studiedWordIds: studiedIds)
        grade2Available = repository.getWordCount(grade: 2) > 0
        isLoading = false
    }
}
