import SwiftUI

struct HomeScreen: View {
    @State private var viewModel: HomeViewModel

    init(repository: WordRepository) {
        _viewModel = State(initialValue: HomeViewModel(repository: repository))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("英検 単語学習")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.strawberry)

                // Grade toggle
                HStack(spacing: 12) {
                    gradeChip("準1級", grade: 1)
                    if viewModel.grade2Available {
                        gradeChip("2級", grade: 2)
                    }
                }

                if viewModel.isLoading {
                    ProgressView()
                } else {
                    // Pass probability card
                    statsCard

                    // Category breakdown
                    categoryCard

                    // Start quiz button
                    NavigationLink(value: QuizRoute(grade: viewModel.selectedGrade)) {
                        Text("クイズを始める")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.strawberry)
                            .cornerRadius(16)
                    }
                }
            }
            .padding(20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.strawberry)
                    Text("Ichigo")
                        .font(.headline)
                        .foregroundColor(.strawberry)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(value: SettingsRoute()) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.strawberry)
                }
            }
        }
    }

    private func gradeChip(_ title: String, grade: Int) -> some View {
        Button(action: { viewModel.selectGrade(grade) }) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.bold)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(viewModel.selectedGrade == grade ? Color.strawberry : Color.appLightGray)
                .foregroundColor(viewModel.selectedGrade == grade ? .white : .primary)
                .cornerRadius(20)
        }
    }

    private var statsCard: some View {
        VStack(spacing: 12) {
            let passPercent = viewModel.passProbability * 100
            let passColor: Color = passPercent >= 80 ? .correctBlue : passPercent >= 50 ? .strawberry : .incorrectOrange

            Text("合格確率")
                .font(.headline)
            Text(String(format: "%.1f%%", passPercent))
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(passColor)

            ProgressView(value: Double(viewModel.passProbability))
                .tint(passColor)
                .scaleEffect(y: 2)
                .padding(.horizontal)

            Divider()

            HStack {
                statItem("実力偏差", value: String(format: "%.1f", 50 + 10 * viewModel.theta))
                Divider().frame(height: 40)
                statItem("習得語", value: "\(viewModel.masteredCount)")
                Divider().frame(height: 40)
                statItem("学習済", value: "\(viewModel.studiedCount)")
            }
        }
        .padding(20)
        .background(Color.appLightGray)
        .cornerRadius(16)
    }

    private func statItem(_ label: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var categoryCard: some View {
        VStack(spacing: 8) {
            Text("カテゴリ別実力")
                .font(.headline)
            HStack {
                categoryItem("動詞", theta: viewModel.thetaVerb)
                categoryItem("名詞", theta: viewModel.thetaNoun)
                categoryItem("形容詞", theta: viewModel.thetaAdjective)
                categoryItem("副詞", theta: viewModel.thetaAdverb)
            }
        }
        .padding(20)
        .background(Color.appLightGray)
        .cornerRadius(16)
    }

    private func categoryItem(_ label: String, theta: Float) -> some View {
        VStack(spacing: 4) {
            Text(String(format: "%.1f", 50 + 10 * theta))
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
