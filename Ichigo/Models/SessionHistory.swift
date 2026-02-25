import Foundation
import SwiftData

@Model
final class SessionHistory {
    var timestamp: Int64
    var grade: Int
    var thetaBefore: Float
    var thetaAfter: Float
    var passProbBefore: Float
    var passProbAfter: Float
    var score: Int
    var total: Int

    init(
        grade: Int = 1,
        thetaBefore: Float = 0,
        thetaAfter: Float = 0,
        passProbBefore: Float = 0,
        passProbAfter: Float = 0,
        score: Int = 0,
        total: Int = 0
    ) {
        self.timestamp = Int64(Date().timeIntervalSince1970 * 1000)
        self.grade = grade
        self.thetaBefore = thetaBefore
        self.thetaAfter = thetaAfter
        self.passProbBefore = passProbBefore
        self.passProbAfter = passProbAfter
        self.score = score
        self.total = total
    }
}
