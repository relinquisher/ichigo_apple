import SwiftUI
import SwiftData

// MARK: - Navigation Routes

struct QuizRoute: Hashable {
    let grade: Int
}

struct ResultsRoute: Hashable {
    let grade: Int
    let passProbBefore: Float
    let passProbAfter: Float
    let score: Int
    let total: Int
    let forgottenDecay: Float
    let thetaBefore: Float
    let maxDiffBeaten: Float
    let masteredCountBefore: Int
    let isBeginnerMode: Bool
    let masteredCountAfter: Int
}

struct SettingsRoute: Hashable {}
struct HomeRoute: Hashable {}

// MARK: - App Entry Point

@main
struct IchigoApp: App {
    let container: ModelContainer

    init() {
        let schema = Schema([Word.self, UserStats.self, StudyProgress.self, SessionHistory.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        container = try! ModelContainer(for: schema, configurations: [config])
        seedDataIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }

    @MainActor
    private func seedDataIfNeeded() {
        let seedVersion = 5
        let defaults = UserDefaults.standard
        let currentVersion = defaults.integer(forKey: "seeded_version")

        guard currentVersion < seedVersion else { return }

        let context = container.mainContext

        for grade in Grade.allCases {
            // Delete existing words for this grade
            let gradeId = grade.rawValue
            let descriptor = FetchDescriptor<Word>(predicate: #Predicate { $0.grade == gradeId })
            if let existing = try? context.fetch(descriptor) {
                for word in existing { context.delete(word) }
            }

            // Load and insert from JSON
            let jsonWords = JsonDataLoader.loadWords(from: grade.assetFile)
            for jw in jsonWords {
                context.insert(jw.toWord())
            }

            // Ensure UserStats exists
            let statsDescriptor = FetchDescriptor<UserStats>(predicate: #Predicate { $0.id == gradeId })
            if (try? context.fetch(statsDescriptor))?.isEmpty ?? true {
                context.insert(UserStats(id: gradeId, grade: gradeId))
            }
        }

        try? context.save()
        defaults.set(seedVersion, forKey: "seeded_version")
    }
}

// MARK: - Root View with Navigation

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            HomeScreen(repository: WordRepository(modelContext: modelContext))
                .navigationDestination(for: QuizRoute.self) { route in
                    AssessmentQuizScreen(grade: route.grade, repository: WordRepository(modelContext: modelContext), path: $path)
                }
                .navigationDestination(for: ResultsRoute.self) { route in
                    AssessmentResultsScreen(
                        grade: route.grade,
                        passProbBefore: route.passProbBefore,
                        passProbAfter: route.passProbAfter,
                        score: route.score,
                        total: route.total,
                        forgottenDecay: route.forgottenDecay,
                        thetaBefore: route.thetaBefore,
                        maxDiffBeaten: route.maxDiffBeaten,
                        masteredCountBefore: route.masteredCountBefore,
                        isBeginnerMode: route.isBeginnerMode,
                        masteredCountAfter: route.masteredCountAfter,
                        repository: WordRepository(modelContext: modelContext),
                        path: $path
                    )
                }
                .navigationDestination(for: SettingsRoute.self) { _ in
                    SettingsScreen(repository: WordRepository(modelContext: modelContext))
                }
                .navigationDestination(for: HomeRoute.self) { _ in
                    HomeScreen(repository: WordRepository(modelContext: modelContext))
                }
        }
    }
}
