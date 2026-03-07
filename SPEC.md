# Ichigo アプリ仕様書

## 1. 概要

英検単語学習アプリ。IRT（項目応答理論）1PLモデルによる適応型アセスメントと個別スキルトラッキング。準1級・2級対応。

---

## 2. 画面構成

### 2.1 ホーム画面 (HomeScreen)
- タイトル: 「英検 単語学習」
- トライアルバッジ: 「トライアル中（のこり{n}日）」（緑、トライアル中&未購入時のみ）
- 級選択: 準1級 / 2級 トグル
- 統計カード:
  - 合格確率（80%↑=青, 50-79%=ストロベリー, 50%↓=オレンジ）
  - 実力偏差 = 50 + 10 × theta
  - 習得語数（正答確率>0.8の学習済み語）
  - 学習済み語数
- カテゴリ別実力: 動詞・名詞・形容詞・副詞
- 「クイズを始める」ボタン（未アンロック時は半透明+タップでペイウォール）
- ナビバー: Ichigoアイコン + 設定ギア

### 2.2 クイズ画面 (AssessmentQuizScreen)
- 問題表示:
  - 熟語（フレーズ）+ IPA + 単語（全級共通）
- 4択（正解=phraseMeaning + 不正解3=wrongChoice1-3）
- タイマー: 1-10秒（設定可能、デフォルト10秒）
  - 色変化: ストロベリー→オレンジ→赤
  - タイムアウトで不正解扱い
- 例文表示:
  - デフォルト表示モード: 回答後に自動表示
  - ボタン表示モード: 「例文を見る」ボタンで表示
  - 英語例文 + 日本語訳、キーワードハイライト
- 音声: TTS自動再生 + スピーカーボタン
- 回答後: 正解(青) / 不正解(オレンジ) + 「次の問題」ボタン
- のこり問数表示
- 出題数: 10問固定
- 復習フェーズ: 不正解の語を1回再出題
- 例文カード: ScrollView対応（長文対応）

### 2.3 結果画面 (AssessmentResultsScreen)
- タイトル: 「アセスメント結果」
- **ビギナーモードカード**（習得語<100語時）:
  - 語彙習得プログレス
  - 「+{n}語 習得！」（緑）
  - 「上級モードまであと{n}語」
- **上級モードカード**（習得語≥100語時）:
  - 合格確率（スプリングアニメーション付き）
  - 変動: 「({符号}{delta}%)」
  - 忘却減少: 「-{decay}%」（>0.001%時、オレンジ）
  - 「合格圏内です！」（80%以上時）
- スコア: {正解}/{全問}（満点時は👑付き）
  - 70%↑=青, それ以外=ストロベリー
- 世間からの評価: 合格確率に基づく称号（級別100+種類）
- ボタン:
  - 「続ける」→ クイズ再開（同じ級、結果画面の上にクイズを積む）
  - 「ホームに戻る」→ ホームへ
- 効果音: quiz_finish + 満点時level_up + 確率変動音

### 2.4 設定画面 (SettingsScreen)
- アカウントセクション:
  - 購入済み: 「フルバージョン購入済み」（緑チェック）
  - トライアル中: 「トライアル中（のこり{n}日）」（時計、ストロベリー）
  - 期限切れ: 「トライアル期間終了」（ロック、グレー）
  - 「購入を復元する」ボタン
- タイマー設定: スライダー 1-10秒
- 例文表示: トグル（最初から表示 / ボタンで表示）
- データ管理: 「学習データをリセット」（二段階確認）

### 2.5 ペイウォール (PaywallView)
- フルスクリーンカバーで表示
- Ichigoアイコン + ブランディング
- 「無料トライアルが終了しました」
- 機能ハイライト3項目:
  - クイズ受け放題
  - IRTによる実力診断
  - 買い切り — 追加料金なし
- 購入ボタン: product.displayPrice表示（価格ハードコードなし）
- 「購入を復元する」ボタン
- Apple標準EULAリンク
- 購入完了時に自動dismiss

---

## 3. データモデル

### Word
| フィールド | 型 | 説明 |
|---|---|---|
| id | Int | 一意ID |
| word | String | 英単語 |
| meaning | String | 日本語意味 |
| exampleEn | String | 英語例文 |
| exampleJa | String | 日本語訳 |
| category | String | 動詞/名詞/形容詞/副詞 |
| difficulty | Float | IRT難易度パラメータ |
| ipa | String | 発音記号 |
| examFrequency | Int | 過去の英検出題回数 |
| grade | Int | 1(準1級) or 2(2級) |
| phrase | String | 熟語（準1級のみ） |
| phraseMeaning | String | 熟語の意味 |
| wrongChoice1/2/3 | String | ダミー選択肢 |

### UserStats
| フィールド | 型 | 説明 |
|---|---|---|
| id/grade | Int | 級ID |
| theta | Float | 全体能力推定値（初期0.0） |
| thetaVariance | Float | 推定値の信頼度（初期1.0） |
| totalAnswered | Int | 累計回答数 |
| sessionCount | Int | セッション数 |
| thetaVerb/Noun/Adjective/Adverb | Float | カテゴリ別theta |

### StudyProgress
| フィールド | 型 | 説明 |
|---|---|---|
| wordId | Int | 単語ID |
| correctCount | Int | 正答数 |
| incorrectCount | Int | 誤答数 |
| consecutiveCorrect | Int | 連続正答数（不正解でリセット） |
| isLearned | Bool | 連続正答≥3でtrue |
| lastStudiedAt | Int64 | 最終学習タイムスタンプ(ms) |

### SessionHistory
| フィールド | 型 | 説明 |
|---|---|---|
| timestamp | Int64 | セッション日時(ms) |
| grade | Int | 級 |
| thetaBefore/After | Float | セッション前後のtheta |
| passProbBefore/After | Float | セッション前後の合格確率 |
| score/total | Int | 正答数/出題数 |

---

## 4. IRTエンジン

### 定数
| 定数 | 値 | 説明 |
|---|---|---|
| discrimination | 1.0 | 識別力（1PL固定） |
| learningRate | 0.4 | theta更新ステップ |
| lambda | 0.00001 | 忘却曲線の減衰率(/ms) |
| epsilon | 0.1 | 探索率（10%ランダム） |
| assessmentQuestionCount | 10 | 1セッションの出題数 |
| beginnerMasteryThreshold | 100 | 上級モード移行に必要な習得語数 |
| beginnerLearningRate | 0.1 | ビギナー不正解時のlearningRate |
| beginnerDifficultyCap | 0.3 | ビギナー難易度上限（theta+0.3） |

### 出題頻度重み
- examFreq=0 → 0.3, =1 → 1.0, =2 → 1.7, =3 → 2.4

### カテゴリ重み
| カテゴリ | 準1級 | 2級 |
|---|---|---|
| 動詞 | 0.40 | 0.35 |
| 名詞 | 0.25 | 0.30 |
| 形容詞 | 0.25 | 0.25 |
| 副詞 | 0.10 | 0.10 |

### 主要計算式
- **正答確率**: P = 1 / (1 + exp(-a × (θ - d)))
- **θ更新**: 正解 → θ += lr × (1-P), 不正解 → θ -= lr × P
- **合格確率**: カテゴリ別平均正答確率の重み付き平均
- **忘却リスク**: risk = 1 - exp(-λ × 経過ms)

---

## 5. 出題選択アルゴリズム (WordSelector)

### 10問のスロット配分
| スロット | 割合 | 目的 |
|---|---|---|
| 1-6 | 60% | 精度重視（Fisher情報量×出題頻度×SRS×誤答ボーナス） |
| 7-8 | 20% | 出題頻度重視（未習得語のみ） |
| 9-10 | 20% | ビギナー:未見語 / 上級:チャレンジ語 |

### SRSペナルティ
| 経過時間 | ペナルティ |
|---|---|
| 24時間以内 | 0.0（出題しない） |
| 24-72時間 | 0.3 |
| 72時間-7日 | 0.6 |
| 7日以上/未学習 | 1.0 |

### 誤答ボーナス
- 1.0 + 0.3 × incorrectCount（上限3.0）

---

## 6. 課金システム

### StoreManager
- Product ID: `com.ichigo.Ichigo.fullversion`（非消耗型）
- トライアル: 3日間（UserDefaults `trial_start_date`）
- `isUnlocked` = isPurchased OR isTrialActive（シミュレータでは常にtrue）
- StoreKit 2 使用（Transaction.updates監視）

### フロー
1. 初回起動 → trial_start_dateを保存
2. ホーム画面表示 → refreshStatus()
3. トライアル期限切れ → クイズボタンでペイウォール表示
4. 購入 → Transaction検証 → finish → isUnlocked=true
5. 復元 → AppStore.sync() → refreshStatus()

---

## 7. 音声

### 効果音 (AudioManager)
| ファイル | タイミング |
|---|---|
| correct.mp3 | 正解時 |
| miss1-12.mp3 | 不正解時（ランダム選択） |
| debuff.mp3 | 忘却曲線デバフ表示時 |
| level_up.mp3 | 満点時 |
| prob_up.mp3 | 合格確率上昇アニメ |
| prob_down.mp3 | 合格確率下降アニメ |
| quiz_finish.mp3 | セッション完了時 |

### TTS (TtsManager)
- AVSpeechSynthesizer (en-US)
- 問題表示時に自動再生
- 例文スピーカーボタンで再生

---

## 8. ビギナーモード vs 上級モード

| | ビギナー（<100語習得） | 上級（≥100語習得） |
|---|---|---|
| 難易度上限 | theta+0.3 | なし |
| 不正解時lr | 0.1 | 0.4 |
| 結果表示 | 語彙習得プログレス | 合格確率 |
| 忘却デバフ | なし | 24h+ → theta減少 |
| スロット9-10 | 未見語（発見） | 高難度語（チャレンジ） |

### 忘却デバフ（上級のみ）
- 24-48時間: theta -0.01
- 48時間以上: theta -0.05
- オーバーレイ表示:「エビングハウスの忘却曲線により」

---

## 9. ナビゲーション

```
ContentView (NavigationStack)
├── HomeScreen (root)
│   ├── → QuizRoute → AssessmentQuizScreen
│   ├── → SettingsRoute → SettingsScreen
│   └── [PaywallView fullScreenCover]
├── AssessmentQuizScreen
│   ├── → SettingsRoute → SettingsScreen
│   └── → ResultsRoute → AssessmentResultsScreen
├── AssessmentResultsScreen
│   ├── 「続ける」→ path.append(QuizRoute) ※ホームを経由しない
│   └── 「ホームに戻る」→ path = NavigationPath()
└── SettingsScreen → dismiss
```

---

## 10. テーマ・カラー

| 名前 | RGB | 用途 |
|---|---|---|
| strawberry | 233,30,99 | メインブランド |
| strawberryLight | 255,96,144 | ライト |
| strawberryDark | 176,0,58 | ダーク |
| leafGreen | 76,175,80 | 成功・トライアルバッジ |
| correctBlue | 25,118,210 | 正解・合格圏 |
| incorrectOrange | 230,81,0 | 不正解・低合格率 |
| appLightGray | 245,245,245 | カード背景 |

- ダークモード: `.preferredColorScheme(.light)` でライトモード強制

---

## 11. UserDefaults キー

| キー | 型 | デフォルト | 説明 |
|---|---|---|---|
| timer_seconds | Int | 10 | タイマー秒数 |
| show_example_default | Bool | true | 例文デフォルト表示 |
| trial_start_date | Date | nil | トライアル開始日 |
| seeded_version | Int | 0 | シードデータバージョン（現在5） |

---

## 12. 称号システム (EvaluationTitle)

合格確率(0-100%)に基づく称号を表示。級別に100種類以上。
- 準1級例: 「記念受験の民」「英語ゴリラ勢」「ネイティブ近似生命体」
- 2級例: 「英語どこ勢」「合格目前の人」「合格確定の覇者」

---

## 13. キーワードハイライト (PhraseExtractor)

- 例文中の該当単語/熟語をボールドで強調表示
- 品詞に応じた範囲拡張（動詞:前方4語, 形容詞:前方2語, 名詞:後方2語）
- 不規則動詞活用対応（50+語）
- 日本語訳中の意味もハイライト

---

*仕様書バージョン: 1.0*
*最終更新: 2026年3月7日*
