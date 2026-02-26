import Foundation
import SwiftData

@Model
final class UserStats {
    @Attribute(.unique) var id: Int
    var grade: Int
    var theta: Float
    var thetaVariance: Float
    var totalAnswered: Int
    var sessionCount: Int
    var thetaAdjective: Float
    var thetaVerb: Float
    var thetaNoun: Float
    var thetaAdverb: Float

    init(
        id: Int = 1,
        grade: Int = 1,
        theta: Float = 0.0,
        thetaVariance: Float = 1.0,
        totalAnswered: Int = 0,
        sessionCount: Int = 0,
        thetaAdjective: Float = 0.0,
        thetaVerb: Float = 0.0,
        thetaNoun: Float = 0.0,
        thetaAdverb: Float = 0.0
    ) {
        self.id = id
        self.grade = grade
        self.theta = theta
        self.thetaVariance = thetaVariance
        self.totalAnswered = totalAnswered
        self.sessionCount = sessionCount
        self.thetaAdjective = thetaAdjective
        self.thetaVerb = thetaVerb
        self.thetaNoun = thetaNoun
        self.thetaAdverb = thetaAdverb
    }
}
