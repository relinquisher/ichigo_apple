import Foundation
import SwiftData

@Model
final class Word {
    @Attribute(.unique) var id: Int
    var word: String
    var reading: String
    var meaning: String
    var exampleEn: String
    var exampleJa: String
    var category: String
    var difficulty: Float
    var ipa: String
    var examFrequency: Int
    var grade: Int
    var phrase: String
    var phraseMeaning: String
    var wrongChoice1: String
    var wrongChoice2: String
    var wrongChoice3: String

    init(
        id: Int,
        word: String,
        reading: String = "",
        meaning: String,
        exampleEn: String,
        exampleJa: String,
        category: String,
        difficulty: Float = 0.0,
        ipa: String = "",
        examFrequency: Int = 0,
        grade: Int = 1,
        phrase: String = "",
        phraseMeaning: String = "",
        wrongChoice1: String = "",
        wrongChoice2: String = "",
        wrongChoice3: String = ""
    ) {
        self.id = id
        self.word = word
        self.reading = reading
        self.meaning = meaning
        self.exampleEn = exampleEn
        self.exampleJa = exampleJa
        self.category = category
        self.difficulty = difficulty
        self.ipa = ipa
        self.examFrequency = examFrequency
        self.grade = grade
        self.phrase = phrase
        self.phraseMeaning = phraseMeaning
        self.wrongChoice1 = wrongChoice1
        self.wrongChoice2 = wrongChoice2
        self.wrongChoice3 = wrongChoice3
    }
}

// MARK: - JSON Decoding

struct WordJSON: Codable {
    let id: Int
    let word: String
    let reading: String?
    let meaning: String
    let exampleEn: String
    let exampleJa: String
    let category: String
    let difficulty: Float?
    let ipa: String?
    let examFrequency: Int?
    let grade: Int?
    let phrase: String?
    let phraseMeaning: String?
    let wrongChoice1: String?
    let wrongChoice2: String?
    let wrongChoice3: String?

    enum CodingKeys: String, CodingKey {
        case id, word, reading, meaning, exampleEn, exampleJa, category
        case difficulty, ipa, examFrequency, grade, phrase
        case phraseMeaning = "phrase_meaning"
        case wrongChoice1 = "dummy1"
        case wrongChoice2 = "dummy2"
        case wrongChoice3 = "dummy3"
    }

    func toWord() -> Word {
        Word(
            id: id,
            word: word,
            reading: reading ?? "",
            meaning: meaning,
            exampleEn: exampleEn,
            exampleJa: exampleJa,
            category: category,
            difficulty: difficulty ?? 0.0,
            ipa: ipa ?? "",
            examFrequency: examFrequency ?? 0,
            grade: grade ?? 1,
            phrase: phrase ?? "",
            phraseMeaning: phraseMeaning ?? "",
            wrongChoice1: wrongChoice1 ?? "",
            wrongChoice2: wrongChoice2 ?? "",
            wrongChoice3: wrongChoice3 ?? ""
        )
    }
}
