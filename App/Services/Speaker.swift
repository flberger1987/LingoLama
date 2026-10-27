import AVFoundation

/// Liest englische Wörter mit britischer Stimme vor (offline, eingebaut in iOS).
final class Speaker {
    static let shared = Speaker()

    private let synthesizer = AVSpeechSynthesizer()
    /// Die beste installierte britische Stimme; "Erweitert" oder "Premium" lädt man in den iOS-Einstellungen nach.
    private let voice = AVSpeechSynthesisVoice.speechVoices()
        .filter { $0.language == "en-GB" && !$0.voiceTraits.contains(.isNoveltyVoice) }
        .max { $0.quality.rawValue < $1.quality.rawValue }
        ?? AVSpeechSynthesisVoice(language: "en-GB")

    func speak(_ text: String, slow: Bool = false) {
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        utterance.rate = slow ? 0.35 : AVSpeechUtteranceDefaultSpeechRate * 0.9
        synthesizer.speak(utterance)
    }
}
