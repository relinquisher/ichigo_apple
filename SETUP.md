# Ichigo iOS - Xcodeプロジェクトセットアップ手順

## 前提条件
- macOS + Xcode 15以上
- iOS 17+ ターゲット（SwiftData使用のため）

## セットアップ手順

### 1. Xcodeプロジェクト作成
1. Xcode を開く → File → New → Project
2. **iOS → App** を選択
3. 設定:
   - Product Name: `Ichigo`
   - Organization Identifier: `com.ichigo`
   - Interface: **SwiftUI**
   - Storage: **SwiftData**
   - Language: **Swift**
4. 保存先: `ichigo_apple/` フォルダ内

### 2. 既存ファイルの追加
1. Xcode が自動生成した `IchigoApp.swift` と `ContentView.swift` を削除
2. File → Add Files to "Ichigo" で以下のフォルダを全て追加（Create groups を選択）:
   - `Ichigo/Models/`
   - `Ichigo/IRT/`
   - `Ichigo/Data/`
   - `Ichigo/Views/`
   - `Ichigo/Util/`
   - `Ichigo/Theme/`
   - `Ichigo/IchigoApp.swift`

### 3. リソースファイルの追加
1. `Ichigo/Resources/words.json` と `words_grade2.json` をプロジェクトに追加
   - **"Copy items if needed"** にチェック
   - Target に追加されていることを確認
2. `Ichigo/Resources/Sounds/` 内の全 `.mp3` ファイルをプロジェクトに追加
   - 同様に Target に追加

### 4. Build Settings確認
- iOS Deployment Target: **17.0**
- Swift Language Version: **5.9** 以上

### 5. ビルド＆実行
- Cmd+B でビルド
- シミュレータまたは実機で実行

## プロジェクト構成

```
Ichigo/
├── IchigoApp.swift          # アプリエントリポイント + ナビゲーション
├── Models/                  # SwiftData モデル
│   ├── Grade.swift
│   ├── Word.swift           # + WordJSON (JSON デコード用)
│   ├── UserStats.swift
│   ├── StudyProgress.swift
│   └── SessionHistory.swift
├── IRT/                     # IRT エンジン（純粋ロジック）
│   ├── IrtConstants.swift
│   ├── IrtEngine.swift
│   └── WordSelector.swift
├── Data/                    # データアクセス層
│   ├── WordRepository.swift
│   └── JsonDataLoader.swift
├── Views/                   # SwiftUI 画面
│   ├── Home/
│   ├── Quiz/
│   ├── Results/
│   └── Settings/
├── Util/                    # ユーティリティ
│   ├── TtsManager.swift
│   ├── AudioManager.swift
│   ├── PhraseExtractor.swift
│   └── EvaluationTitle.swift
├── Theme/
│   └── AppColors.swift
└── Resources/
    ├── words.json
    ├── words_grade2.json
    └── Sounds/*.mp3
```

## 技術スタック
- **SwiftUI** (UIフレームワーク)
- **SwiftData** (永続化、iOS 17+)
- **AVFoundation** (音声再生・TTS)
- **@Observable** (状態管理、iOS 17+)
