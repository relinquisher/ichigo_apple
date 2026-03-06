import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(StoreManager.self) private var storeManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Branding
            Image("IchigoIcon")
                .resizable()
                .frame(width: 80, height: 80)
            Text("Ichigo")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.strawberry)

            Text("無料トライアルが終了しました")
                .font(.title3)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)

            // Feature highlights
            VStack(alignment: .leading, spacing: 12) {
                featureRow(icon: "checkmark.circle.fill", text: "クイズ受け放題")
                featureRow(icon: "chart.line.uptrend.xyaxis", text: "IRTによる実力診断")
                featureRow(icon: "bag.fill", text: "買い切り — 追加料金なし")
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.appLightGray)
            .cornerRadius(16)

            // Purchase button
            Button {
                Task { await storeManager.purchase() }
            } label: {
                if storeManager.isPurchasing {
                    ProgressView()
                        .tint(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                } else {
                    Text(purchaseButtonTitle)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
            }
            .background(Color.strawberry)
            .cornerRadius(16)
            .disabled(storeManager.isPurchasing || storeManager.product == nil)

            // Restore button
            Button {
                Task { await storeManager.restore() }
            } label: {
                Text("購入を復元する")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Error message
            if let error = storeManager.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            // EULA link
            if let eulaURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                Link("利用規約 (Apple標準EULA)", destination: eulaURL)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(32)
        .onChange(of: storeManager.isUnlocked) {
            if storeManager.isUnlocked {
                dismiss()
            }
        }
    }

    private var purchaseButtonTitle: String {
        if let product = storeManager.product {
            return "\(product.displayPrice)で購入する"
        }
        return "読み込み中..."
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.strawberry)
                .font(.title3)
            Text(text)
                .font(.body)
        }
    }
}
