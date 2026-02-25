import AVFoundation

class AudioManager {
    static let shared = AudioManager()
    private var player: AVAudioPlayer?

    func play(_ soundName: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else { return }
        player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
    }

    func preload(_ soundName: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else { return nil }
        let p = try? AVAudioPlayer(contentsOf: url)
        p?.prepareToPlay()
        return p
    }
}
