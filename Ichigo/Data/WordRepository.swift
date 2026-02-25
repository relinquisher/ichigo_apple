import Foundation
import SwiftData

@MainActor
class WordRepository {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Words

    func getWordsByGrade(_ grade: Int) -> [Word] {
        let descriptor = FetchDescriptor<Word>(
            predicate: #Predicate { $0.grade == grade },
            sortBy: [SortDescriptor(\.id)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func getWordCount(grade: Int) -> Int {
        let descriptor = FetchDescriptor<Word>(
            predicate: #Predicate { $0.grade == grade }
        )
        return (try? modelContext.fetchCount(descriptor)) ?? 0
    }

    func insertWords(_ words: [Word]) {
        for word in words { modelContext.insert(word) }
        try? modelContext.save()
    }

    func deleteWordsByGrade(_ grade: Int) {
        let existing = getWordsByGrade(grade)
        for word in existing { modelContext.delete(word) }
        try? modelContext.save()
    }

    // MARK: - UserStats

    func getUserStatsByGrade(_ gradeId: Int) -> UserStats {
        let descriptor = FetchDescriptor<UserStats>(
            predicate: #Predicate { $0.id == gradeId }
        )
        if let existing = try? modelContext.fetch(descriptor).first {
            return existing
        }
        let newStats = UserStats(id: gradeId, grade: gradeId)
        modelContext.insert(newStats)
        try? modelContext.save()
        return newStats
    }

    func updateUserStats(_ stats: UserStats) {
        try? modelContext.save()
    }

    // MARK: - StudyProgress

    func getProgress(wordId: Int) -> StudyProgress? {
        let descriptor = FetchDescriptor<StudyProgress>(
            predicate: #Predicate { $0.wordId == wordId }
        )
        return try? modelContext.fetch(descriptor).first
    }

    func getAllProgressByGrade(_ grade: Int) -> [StudyProgress] {
        let wordIds = Set(getWordsByGrade(grade).map { $0.id })
        let descriptor = FetchDescriptor<StudyProgress>()
        let allProgress = (try? modelContext.fetch(descriptor)) ?? []
        return allProgress.filter { wordIds.contains($0.wordId) }
    }

    func getStudiedWordIdsByGrade(_ grade: Int) -> Set<Int> {
        Set(getAllProgressByGrade(grade).map { $0.wordId })
    }

    func getStudiedCountByGrade(_ grade: Int) -> Int {
        getAllProgressByGrade(grade).count
    }

    func getLearnedCountByGrade(_ grade: Int) -> Int {
        getAllProgressByGrade(grade).filter { $0.isLearned }.count
    }

    func recordIrtAnswer(wordId: Int, isCorrect: Bool) {
        let progress: StudyProgress
        if let existing = getProgress(wordId: wordId) {
            progress = existing
        } else {
            progress = StudyProgress(wordId: wordId)
            modelContext.insert(progress)
        }

        if isCorrect {
            progress.correctCount += 1
            progress.consecutiveCorrect += 1
        } else {
            progress.incorrectCount += 1
            progress.consecutiveCorrect = 0
        }
        progress.isLearned = progress.consecutiveCorrect >= 3
        progress.lastStudiedAt = Int64(Date().timeIntervalSince1970 * 1000)
        try? modelContext.save()
    }

    // MARK: - SessionHistory

    func insertSession(_ session: SessionHistory) {
        modelContext.insert(session)
        try? modelContext.save()
    }

    func getLatestSessionByGrade(_ grade: Int) -> SessionHistory? {
        let descriptor = FetchDescriptor<SessionHistory>(
            predicate: #Predicate { $0.grade == grade },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        return try? modelContext.fetch(descriptor).first
    }

    // MARK: - Reset

    func resetAllUserData() {
        let allProgress = (try? modelContext.fetch(FetchDescriptor<StudyProgress>())) ?? []
        for p in allProgress { modelContext.delete(p) }
        let allStats = (try? modelContext.fetch(FetchDescriptor<UserStats>())) ?? []
        for s in allStats { modelContext.delete(s) }
        let allSessions = (try? modelContext.fetch(FetchDescriptor<SessionHistory>())) ?? []
        for s in allSessions { modelContext.delete(s) }

        modelContext.insert(UserStats(id: 1, grade: 1))
        modelContext.insert(UserStats(id: 2, grade: 2))
        try? modelContext.save()
    }
}
