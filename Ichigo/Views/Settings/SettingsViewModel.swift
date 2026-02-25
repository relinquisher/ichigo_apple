import Foundation

@Observable
class SettingsViewModel {
    var resetCompleted = false

    private let repository: WordRepository

    init(repository: WordRepository) {
        self.repository = repository
    }

    func resetAllUserData() {
        repository.resetAllUserData()
        resetCompleted = true
    }

    func clearResetFlag() {
        resetCompleted = false
    }
}
