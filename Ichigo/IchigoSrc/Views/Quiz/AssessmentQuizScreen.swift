import SwiftUI
import AVFoundation

struct AssessmentQuizScreen: View {
    @State var viewModel: AssessmentQuizViewModel
    @State private var timerProgress: Double = 1.0
    @State private var timerTask: Task<Void, Never>?
    @State private var exampleRevealed: Bool
    @State private var showExample = false
    @Binding var path: NavigationPath

    @AppStorage("timer_seconds") private var timerSeconds: Int = 4
    @AppStorage("show_example_default") private var showExampleByDefault: Bool = true

    private let ttsManager = TtsManager()

    init(grade: Int, repository: WordRepository, path: Binding<NavigationPath>) {
        let vm = AssessmentQuizViewModel(grade: grade, repository: repository)
        _viewModel = State(initialValue: vm)
        _exampleRevealed = State(initialValue: false)
        _path = path
    }

    var body: some View {
        ZStack {
            if viewModel.showDebuffOverlay {
                debuffOverlay
            } else if viewModel.isLoading {
                ProgressView()
            } else if let question = viewModel.question {
                quizContent(question: question)
            }

            // Full-screen example overlay (button mode)
            if showExample && !showExampleByDefault, let question = viewModel.question {
                exampleOverlay(question: question)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showExample)
        .navigationTitle(viewModel.isReviewPhase ? "復習" : "クイズ")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(value: SettingsRoute()) {
                    Image(systemName: "gearshape.fill")
                }
            }
        }
        .onChange(of: viewModel.currentIndex) {
            showExample = showExampleByDefault
            startTimer()
            if let q = viewModel.question {
                let text = q.word.phrase.isEmpty ? q.word.word : q.word.phrase
                ttsManager.speak(text)
            }
        }
        .onChange(of: viewModel.isAnswered) {
            if viewModel.isAnswered {
                timerTask?.cancel()
                playAnswerSound()
            }
        }
        .onChange(of: viewModel.isFinished) {
            if viewModel.isFinished {
                path.append(ResultsRoute(
                    grade: viewModel.grade,
                    passProbBefore: viewModel.passProbBefore,
                    passProbAfter: viewModel.passProbability,
                    score: viewModel.score,
                    total: viewModel.originalQuestionCount,
                    forgottenDecay: viewModel.forgottenDecay,
                    thetaBefore: viewModel.thetaBefore,
                    maxDiffBeaten: viewModel.maxDifficultyBeaten,
                    masteredCountBefore: viewModel.masteredCountBefore,
                    isBeginnerMode: viewModel.isBeginnerMode,
                    masteredCountAfter: viewModel.masteredCountAfter
                ))
            }
        }
        .onAppear {
            showExample = showExampleByDefault
            startTimer()
            if let q = viewModel.question {
                let text = q.word.phrase.isEmpty ? q.word.word : q.word.phrase
                ttsManager.speak(text)
            }
        }
    }

    // MARK: - Quiz Content

    private func quizContent(question: QuizQuestion) -> some View {
        VStack(spacing: 0) {
            // Remaining count
            HStack {
                Spacer()
                let remaining = viewModel.totalQuestions - viewModel.currentIndex
                Text(viewModel.isReviewPhase ? "復習のこり " : "のこり ")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                + Text("\(remaining)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.secondary)
                + Text("問")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            // Timer bar
            let timerColor: Color = viewModel.isAnswered
                ? (viewModel.isCorrect ? .correctBlue : .incorrectOrange)
                : (timerProgress < 0.25 ? .incorrectOrange : timerProgress < 0.5 ? .orange : .strawberry)

            ProgressView(value: viewModel.isAnswered ? (viewModel.isCorrect ? 1.0 : 0.0) : timerProgress)
                .tint(timerColor)
                .scaleEffect(y: 1.5)
                .padding(.horizontal)
                .padding(.top, 8)

            Spacer().frame(height: 20)

            // Word/Phrase display
            wordDisplay(question: question)

            Spacer().frame(height: 16)

            // Choices
            ForEach(0..<question.choices.count, id: \.self) { index in
                choiceButton(index: index, choice: question.choices[index], question: question)
            }

            // Example button (button mode)
            if viewModel.isAnswered && !showExampleByDefault && !showExample {
                Button(action: {
                    showExample = true
                    ttsManager.speak(question.word.exampleEn)
                }) {
                    Text("例文を見る")
                        .font(.title2)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.bordered)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.top, 8)
            }

            // Default mode example card
            if showExampleByDefault && viewModel.isAnswered {
                exampleCard(question: question)
                    .padding(.horizontal)
                    .padding(.top, 12)
            }

            Spacer()

            // Next button
            if viewModel.isAnswered {
                Button(action: { viewModel.nextQuestion() }) {
                    Text(viewModel.currentIndex + 1 >= viewModel.totalQuestions
                         ? (viewModel.hasIncorrectWords ? "復習に行く" : "結果を見る")
                         : "次の問題")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.strawberry)
                .cornerRadius(12)
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
    }

    // MARK: - Word Display

    private func wordDisplay(question: QuizQuestion) -> some View {
        VStack(spacing: 8) {
            if !question.word.phrase.isEmpty {
                // 準1級: phrase + word
                Text(question.word.phrase)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.strawberry)
                    .multilineTextAlignment(.center)
                    .onTapGesture { ttsManager.speak(question.word.phrase) }

                if !question.word.ipa.isEmpty {
                    Text(question.word.ipa)
                        .font(.title2)
                        .foregroundColor(.secondary)
                }

                Text(question.word.word)
                    .font(.title3)
                    .foregroundColor(.secondary)
            } else {
                // 2級: word only
                Text(question.word.word)
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.strawberry)
                    .multilineTextAlignment(.center)
                    .onTapGesture { ttsManager.speak(question.word.word) }

                if !question.word.ipa.isEmpty {
                    Text(question.word.ipa)
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Choice Button

    private func choiceButton(index: Int, choice: String, question: QuizQuestion) -> some View {
        let isSelected = viewModel.selectedIndex == index
        let isCorrectChoice = index == question.correctIndex
        let borderColor: Color = !viewModel.isAnswered ? .gray.opacity(0.3)
            : isCorrectChoice ? .correctBlue
            : isSelected ? .incorrectOrange
            : .gray.opacity(0.15)
        let bgColor: Color = !viewModel.isAnswered ? .clear
            : isCorrectChoice ? .correctBlue.opacity(0.1)
            : isSelected ? .incorrectOrange.opacity(0.1)
            : .clear

        return Button(action: { if !viewModel.isAnswered { viewModel.selectAnswer(index) } }) {
            Text(choice)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(bgColor)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: 2)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
        .padding(.vertical, 3)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isAnswered)
    }

    // MARK: - Example Card

    private func exampleCard(question: QuizQuestion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("例文")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.strawberry)
                Spacer()
                Button(action: { ttsManager.speak(question.word.exampleEn) }) {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(.strawberry)
                }
            }
            Text(highlightedEnglish(question: question, font: .title3))
                .font(.title3)
            Text(highlightedJapanese(question: question, font: .subheadline))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color.appLightGray)
        .cornerRadius(12)
    }

    // MARK: - Example Overlay

    private func exampleOverlay(question: QuizQuestion) -> some View {
        ZStack {
            // Scrim
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture { showExample = false }

            // Card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("例文")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.strawberry)
                    Spacer()
                    Button(action: { ttsManager.speak(question.word.exampleEn) }) {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.title3)
                            .foregroundColor(.strawberry)
                    }
                }
                Text(highlightedEnglish(question: question, font: .title2))
                    .font(.title2)
                Text(highlightedJapanese(question: question, font: .body))
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 8)
            .padding(.horizontal, 20)
            .onTapGesture { showExample = false }
        }
    }

    // MARK: - Debuff Overlay

    private var debuffOverlay: some View {
        VStack(spacing: 16) {
            Text("エビングハウスの忘却曲線により")
                .font(.headline)
            Text(String(format: "%.2f↓", viewModel.forgettingDebuff))
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(.incorrectOrange)
        }
        .onAppear {
            AudioManager.shared.play("debuff")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                viewModel.dismissDebuffOverlay()
            }
        }
    }

    // MARK: - Helpers

    private func highlightedEnglish(question: QuizQuestion, font: Font) -> AttributedString {
        let sentence = question.word.exampleEn
        var attr = AttributedString(sentence)
        if let range = PhraseExtractor.extractPhraseRange(word: question.word.word, category: question.word.category, sentence: sentence) {
            let startIdx = attr.index(attr.startIndex, offsetByCharacters: range.start)
            let endIdx = attr.index(attr.startIndex, offsetByCharacters: min(range.end + 1, sentence.count))
            attr[startIdx..<endIdx].font = font.bold()
            attr[startIdx..<endIdx].foregroundColor = .primary
        }
        return attr
    }

    private func highlightedJapanese(question: QuizQuestion, font: Font) -> AttributedString {
        let sentence = question.word.exampleJa
        var attr = AttributedString(sentence)
        if let range = PhraseExtractor.findMeaningRange(meaning: question.word.meaning, sentence: sentence) {
            let endChar = min(range.end + 1, sentence.count)
            if range.start < endChar {
                let startIdx = attr.index(attr.startIndex, offsetByCharacters: range.start)
                let endIdx = attr.index(attr.startIndex, offsetByCharacters: endChar)
                attr[startIdx..<endIdx].font = font.bold()
                attr[startIdx..<endIdx].foregroundColor = .primary
            }
        }
        return attr
    }

    private func startTimer() {
        timerTask?.cancel()
        timerProgress = 1.0
        guard !viewModel.isAnswered, !viewModel.showDebuffOverlay else { return }
        let duration = Double(timerSeconds)
        let startTime = Date()
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 50_000_000) // 50ms
                let elapsed = Date().timeIntervalSince(startTime)
                let progress = max(0, 1.0 - elapsed / duration)
                await MainActor.run { timerProgress = progress }
                if elapsed >= duration {
                    await MainActor.run { viewModel.timeUp() }
                    break
                }
            }
        }
    }

    private func playAnswerSound() {
        guard !viewModel.answerEffectsPlayed else { return }
        viewModel.markAnswerEffectsPlayed()
        let missSounds = (1...12).map { "miss\($0)" }
        let sound = viewModel.isCorrect ? "correct" : missSounds.randomElement()!
        AudioManager.shared.play(sound)

        if showExampleByDefault {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                if let q = viewModel.question {
                    ttsManager.speak(q.word.exampleEn)
                }
            }
        }
    }
}
