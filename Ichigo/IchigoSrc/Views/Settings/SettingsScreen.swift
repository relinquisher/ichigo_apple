import SwiftUI

struct SettingsScreen: View {
    @Environment(StoreManager.self) private var storeManager
    @State private var viewModel: SettingsViewModel
    @AppStorage("timer_seconds") private var timerSeconds: Int = 10
    @AppStorage("show_example_default") private var showExampleByDefault: Bool = true
    @State private var showResetAlert = false
    @State private var showFinalConfirm = false
    @Environment(\.dismiss) private var dismiss

    init(repository: WordRepository) {
        _viewModel = State(initialValue: SettingsViewModel(repository: repository))
    }

    var body: some View {
        Form {
            Section("アカウント") {
                if storeManager.isPurchased {
                    Label("フルバージョン購入済み", systemImage: "checkmark.seal.fill")
                        .foregroundColor(.leafGreen)
                } else if storeManager.isTrialActive {
                    Label("トライアル中（のこり\(storeManager.trialDaysRemaining)日）", systemImage: "clock.fill")
                        .foregroundColor(.strawberry)
                } else {
                    Label("トライアル期間終了", systemImage: "lock.fill")
                        .foregroundColor(.secondary)
                }

                Button {
                    Task { await storeManager.restore() }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("購入を復元する")
                    }
                }
            }

            Section("タイマー設定") {
                VStack(alignment: .leading) {
                    Text("制限時間: \(timerSeconds)秒")
                        .font(.headline)
                    Slider(value: Binding(
                        get: { Double(timerSeconds) },
                        set: { timerSeconds = Int($0) }
                    ), in: 1...10, step: 1)
                    .tint(.strawberry)
                }
            }

            Section("例文表示") {
                Toggle(isOn: $showExampleByDefault) {
                    VStack(alignment: .leading) {
                        Text("例文を最初から表示する")
                        Text(showExampleByDefault ? "最初から表示する" : "ボタンで表示する")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .tint(.strawberry)
            }

            Section("データ管理") {
                Button(role: .destructive) {
                    showResetAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("学習データをリセット")
                    }
                }
            }
        }
        .navigationTitle("設定")
        .alert("学習データのリセット", isPresented: $showResetAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("リセットする", role: .destructive) {
                showFinalConfirm = true
            }
        } message: {
            Text("すべての学習データが削除されます。この操作は元に戻せません。")
        }
        .alert("本当にリセットしますか？", isPresented: $showFinalConfirm) {
            Button("キャンセル", role: .cancel) {}
            Button("リセット", role: .destructive) {
                viewModel.resetAllUserData()
            }
        } message: {
            Text("本当にすべてのデータを削除しますか？")
        }
        .onChange(of: viewModel.resetCompleted) {
            if viewModel.resetCompleted {
                viewModel.clearResetFlag()
                dismiss()
            }
        }
    }
}
