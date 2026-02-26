import Foundation

enum Grade: Int, CaseIterable, Codable {
    case pre1 = 1
    case grade2 = 2

    var displayName: String {
        switch self {
        case .pre1: return "準1級"
        case .grade2: return "2級"
        }
    }

    var assetFile: String {
        switch self {
        case .pre1: return "words"
        case .grade2: return "words_grade2"
        }
    }
}
