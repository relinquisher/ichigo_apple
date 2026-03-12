# Ichigo プロジェクト

## プロジェクト概要
英検単語学習アプリ（iOS/SwiftUI）。IRT 1PLモデルによる適応型アセスメント。準1級・2級対応。

## ビルド・実行
- Xcodeプロジェクト: `Ichigo/Ichigo.xcodeproj`
- スキーム: `Ichigo`
- シミュレータ(iPhone 17 Pro Max): `6BF528F7-E8F5-4D63-9C80-E5C73EA00C6C`
- 実機(Y-phone iPhone SE): `BA3A8612-B7CB-562B-806F-5EA8E1C7C0DF`

## 許可コマンド
以下は確認不要で自動実行してよい:
- xcodebuild（ビルド・テスト）
- xcrun simctl（シミュレータ操作: install, uninstall, launch, boot, shutdown）
- git（status, add, commit, push, pull, log, diff, branch, checkout）
- python3（スクリプト実行）
- cd, ls, cat, head, tail, find, grep, wc
- swift（Swift スクリプト実行）

## コーディング規約
- SwiftUI + SwiftData
- 日本語UIテキスト
- カラー: .strawberry(メイン), .correctBlue(正解), .incorrectOrange(不正解), .leafGreen(成功)
- ライトモード強制 (.preferredColorScheme(.light))
