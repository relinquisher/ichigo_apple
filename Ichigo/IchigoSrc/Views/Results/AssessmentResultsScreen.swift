import SwiftUI
import AVFoundation

struct AssessmentResultsScreen: View {
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

    let repository: WordRepository
    @Binding var path: NavigationPath

    @State private var animatedProgress: Float
    @State private var hasAnimated = false
    @State private var isFading = false
    @State private var preloadedPlayer: AVAudioPlayer?

    init(grade: Int, passProbBefore: Float, passProbAfter: Float, score: Int, total: Int,
         forgottenDecay: Float, thetaBefore: Float, maxDiffBeaten: Float,
         masteredCountBefore: Int, isBeginnerMode: Bool, masteredCountAfter: Int,
         repository: WordRepository, path: Binding<NavigationPath>) {
        self.grade = grade
        self.passProbBefore = passProbBefore
        self.passProbAfter = passProbAfter
        self.score = score
        self.total = total
        self.forgottenDecay = forgottenDecay
        self.thetaBefore = thetaBefore
        self.maxDiffBeaten = maxDiffBeaten
        self.masteredCountBefore = masteredCountBefore
        self.isBeginnerMode = isBeginnerMode
        self.masteredCountAfter = masteredCountAfter
        self.repository = repository
        _path = path
        _animatedProgress = State(initialValue: passProbBefore)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("アセスメント結果")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.strawberry)

                // Pass probability / mastery card
                if isBeginnerMode {
                    beginnerCard
                } else {
                    advancedCard
                }

                // Score
                let scoreText = (score == total && total > 0) ? "👑\(score) / \(total)" : "\(score) / \(total)"
                let percentage = total > 0 ? (score * 100) / total : 0
                Text(scoreText)
                    .font(.system(size: 48))
                    .foregroundColor(percentage >= 70 ? .correctBlue : .strawberry)

                // Evaluation title
                let passPercent = passProbAfter * 100
                let title = EvaluationTitle.getTitle(grade: grade, passPercent: passPercent)
                VStack(spacing: 8) {
                    Text("世間からの評価")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.strawberry)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.strawberry, lineWidth: 2)
                )

                // Buttons
                Button {
                    withAnimation(.easeIn(duration: 0.3)) {
                        isFading = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        path = NavigationPath()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            path.append(QuizRoute(grade: grade))
                        }
                    }
                } label: {
                    Text("続ける")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.strawberry)
                        .cornerRadius(16)
                }

                Button {
                    path = NavigationPath()
                } label: {
                    Text("ホームに戻る")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.strawberry, lineWidth: 2)
                        )
                }
            }
            .padding(32)
        }
        .overlay {
            if isFading {
                Color.cream
                    .ignoresSafeArea()
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            AudioManager.shared.play("quiz_finish")
            if score == total && total > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                    AudioManager.shared.play("level_up")
                }
            }
            // Pre-load probability sound and start animation
            if !isBeginnerMode && !hasAnimated {
                let soundName = (passProbAfter - passProbBefore) >= 0 ? "prob_up" : "prob_down"
                preloadedPlayer = AudioManager.shared.preload(soundName)

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.55)) {
                        animatedProgress = passProbAfter
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        preloadedPlayer?.play()
                    }
                    hasAnimated = true
                }
            }
        }
    }

    // MARK: - Beginner Card

    private var beginnerCard: some View {
        let gain = masteredCountAfter - masteredCountBefore
        let threshold = IrtConstants.beginnerMasteryThreshold
        let remaining = max(0, threshold - masteredCountAfter)
        let progress = Float(masteredCountAfter) / Float(threshold)

        return VStack(spacing: 12) {
            Text("語彙習得")
                .font(.headline)
            if gain > 0 {
                Text("+\(gain)語 習得！")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.leafGreen)
            }
            ProgressView(value: Double(min(progress, 1.0)))
                .tint(.correctBlue)
                .scaleEffect(y: 2)
            Text("\(masteredCountAfter) / \(threshold)語")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.correctBlue)
            if remaining > 0 {
                Text("上級モードまであと\(remaining)語")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
        .background(Color.appLightGray)
        .cornerRadius(16)
    }

    // MARK: - Advanced Card

    private var advancedCard: some View {
        let passPercent = animatedProgress * 100
        let deltaPercent = (passProbAfter - passProbBefore) * 100
        let decayPercent = forgottenDecay * 100
        let passColor: Color = passPercent >= 80 ? .correctBlue : passPercent >= 50 ? .strawberry : .incorrectOrange

        return VStack(spacing: 12) {
            Text("合格確率")
                .font(.title3)
                .fontWeight(.bold)

            Text(String(format: "%.1f%%", min(max(passPercent, 0), 100)))
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(passColor)

            ProgressView(value: Double(min(max(animatedProgress, 0), 1)))
                .tint(passColor)
                .scaleEffect(y: 3)

            let deltaSign = deltaPercent >= 0 ? "+" : ""
            let deltaColor: Color = deltaPercent >= 0 ? .correctBlue : .incorrectOrange
            Text("(\(deltaSign)\(String(format: "%.3f", deltaPercent))%)")
                .font(.body)
                .fontWeight(.bold)
                .foregroundColor(deltaColor)

            if decayPercent > 0.001 {
                Text("忘却による減少: -\(String(format: "%.3f", decayPercent))%")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.incorrectOrange)
            }

            if passProbAfter * 100 >= 80 {
                Divider()
                Text("合格圏内です！")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.correctBlue)
            }
        }
        .padding(20)
        .background(Color.appLightGray)
        .cornerRadius(16)
    }
}
