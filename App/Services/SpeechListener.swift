import AVFoundation
import Observation
import Speech

/// Hört auf ein englisches Wort. Die Erkennung läuft nur auf dem Gerät, Aufnahmen werden weder gespeichert noch verschickt.
@Observable
final class SpeechListener {
    private(set) var isListening = false
    private(set) var transcripts: [String] = []
    private(set) var unavailable = false

    @ObservationIgnored private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-GB"))
    @ObservationIgnored private let engine = AVAudioEngine()
    @ObservationIgnored private var request: SFSpeechAudioBufferRecognitionRequest?
    @ObservationIgnored private var task: SFSpeechRecognitionTask?
    @ObservationIgnored private var waiter: CheckedContinuation<[String], Never>?

    /// Sprechübungen gibt es nur mit Erkennung auf dem Gerät und solange sie nicht abgelehnt wurde.
    static var isAvailable: Bool {
        guard let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-GB")),
              recognizer.supportsOnDeviceRecognition else { return false }
        let status = SFSpeechRecognizer.authorizationStatus()
        return status != .denied && status != .restricted
    }

    func start() async {
        reset()
        guard let recognizer, recognizer.isAvailable, await Self.requestPermissions() else {
            unavailable = true
            return
        }
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = true
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
            Self.installTap(on: engine.inputNode, request: request)
            engine.prepare()
            try engine.start()
        } catch {
            engine.inputNode.removeTap(onBus: 0)
            unavailable = true
            return
        }
        self.request = request
        isListening = true
        task = Self.recognize(with: recognizer, request: request) { [weak self] texts, isFinal in
            Task { @MainActor in self?.received(texts, isFinal: isFinal) }
        }
    }

    /// Beendet die Aufnahme und wartet kurz auf das endgültige Ergebnis.
    func finish() async -> [String] {
        guard isListening else { return transcripts }
        stopAudio()
        return await withCheckedContinuation { continuation in
            waiter = continuation
            Task {
                try? await Task.sleep(for: .seconds(2))
                self.resolve()
            }
        }
    }

    func reset() {
        cancel()
        transcripts = []
        unavailable = false
    }

    func cancel() {
        stopAudio()
        task?.cancel()
        resolve()
    }

    private func received(_ texts: [String], isFinal: Bool) {
        if !texts.isEmpty { transcripts = texts }
        if isFinal {
            stopAudio()
            resolve()
        }
    }

    private func stopAudio() {
        if engine.isRunning {
            engine.stop()
            engine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        request = nil
    }

    private func resolve() {
        isListening = false
        task = nil
        waiter?.resume(returning: transcripts)
        waiter = nil
    }

    // Die Rückrufe kommen auf Audio- und Hintergrund-Threads, deshalb außerhalb des MainActor angelegt.

    nonisolated private static func requestPermissions() async -> Bool {
        let status = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { continuation.resume(returning: $0) }
        }
        guard status == .authorized else { return false }
        return await AVAudioApplication.requestRecordPermission()
    }

    nonisolated private static func installTap(on node: AVAudioInputNode, request: SFSpeechAudioBufferRecognitionRequest) {
        nonisolated(unsafe) let request = request
        node.installTap(onBus: 0, bufferSize: 1024, format: node.outputFormat(forBus: 0)) { buffer, _ in
            request.append(buffer)
        }
    }

    nonisolated private static func recognize(
        with recognizer: SFSpeechRecognizer,
        request: SFSpeechAudioBufferRecognitionRequest,
        update: @escaping @Sendable ([String], Bool) -> Void
    ) -> SFSpeechRecognitionTask {
        recognizer.recognitionTask(with: request) { result, error in
            update(result?.transcriptions.map(\.formattedString) ?? [], (result?.isFinal ?? false) || error != nil)
        }
    }
}
