import SwiftData
import SwiftUI
import VokabelKit

struct QuizView: View {
    @Environment(PlayerProgress.self) private var progress
    @Environment(\.dismiss) private var dismiss

    @State private var steps: [QuizStep]
    @State private var index = 0
    @State private var answer = ""
    @State private var phase: Phase = .asking
    @State private var results: [AnswerResult] = []
    @State private var earnedStars = 0
    @State private var levelUp = false
    @State private var newAnimals: [Animal] = []
    @State private var listener = SpeechListener()
    @FocusState private var focused: Bool

    enum Phase: Equatable {
        case asking
        case checking
        case feedback(AnswerResult, String)
        case finished
    }

    init(words: [Word], mode: QuizMode) {
        _steps = State(initialValue: QuizStep.session(from: words, mode: mode))
    }

    private var step: QuizStep? { steps.indices.contains(index) ? steps[index] : nil }

    var body: some View {
        NavigationStack {
            Group {
                if phase == .finished || step == nil {
                    SummaryView(results: results, stars: earnedStars, levelUp: levelUp, newAnimals: newAnimals) { dismiss() }
                } else if case .pairs(let words)? = step {
                    PairsView(words: words) { finishPairs(clean: $0) }
                        .id(index)
                } else if case .card(let card, let kind, let choices)? = step {
                    question(card, kind: kind, choices: choices)
                        .id(index)
                }
            }
            .padding()
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("Wool"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Beenden", systemImage: "xmark") { finish() }
                }
                ToolbarItem(placement: .principal) {
                    if phase != .finished, !steps.isEmpty {
                        ProgressView(value: Double(index), total: Double(steps.count)).frame(width: 160)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func question(_ card: Card, kind: ExerciseKind, choices: [String]) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Text(kind.instruction(card.direction))
                .font(.headline)
                .foregroundStyle(.secondary)

            if kind == .listening {
                HStack(spacing: 20) {
                    Button { Speaker.shared.speak(card.word.english) } label: {
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 40))
                            .padding(28)
                            .background(Color.accentColor.opacity(0.15), in: Circle())
                    }
                    .accessibilityLabel("Anhören")
                    Button { Speaker.shared.speak(card.word.english, slow: true) } label: {
                        Image(systemName: "tortoise.fill").font(.title)
                    }
                    .accessibilityLabel("Langsam anhören")
                }
            } else {
                HStack(spacing: 12) {
                    Text(card.prompt)
                        .font(.system(size: 38, weight: .bold))
                        .multilineTextAlignment(.center)
                        .minimumScaleFactor(0.5)
                    if card.direction == .enToDe {
                        Button { Speaker.shared.speak(card.prompt) } label: {
                            Image(systemName: "speaker.wave.2.circle.fill").font(.largeTitle)
                        }
                    }
                }
            }

            switch kind {
            case .multipleChoice:
                choiceButtons(choices, card: card)
            case .speaking:
                speakingInput(card)
            case .typing, .listening:
                TextField(kind == .listening || card.direction == .deToEn ? "English" : "Deutsch", text: $answer)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
                    .focused($focused)
                    .disabled(phase != .asking)
                    .onSubmit { submitOrContinue(card, kind) }
            }

            feedback(card, expected: expected(card, kind))

            Spacer()

            // Bei der Auswahl prüft schon der Tipp auf eine Antwort.
            if !(kind == .multipleChoice && phase == .asking) {
                Button { submitOrContinue(card, kind) } label: {
                    Group {
                        switch phase {
                        case .checking: ProgressView()
                        case .feedback: Text(index + 1 < steps.count ? "Weiter" : "Fertig")
                        default: Text("Prüfen")
                        }
                    }
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.roundedRectangle(radius: 16))
                .disabled(phase == .checking || (kind == .speaking && phase == .asking && (listener.isListening || listener.transcripts.isEmpty)))
            }
        }
        .onAppear {
            focused = kind == .typing || kind == .listening
            if kind == .listening { Speaker.shared.speak(card.word.english) }
        }
        .animation(.spring(duration: 0.3), value: phase)
    }

    private func choiceButtons(_ choices: [String], card: Card) -> some View {
        VStack(spacing: 10) {
            ForEach(choices, id: \.self) { choice in
                Button {
                    guard phase == .asking else { return }
                    answer = choice
                    Task { await check(card, .multipleChoice) }
                } label: {
                    Text(choice)
                        .font(.title3.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(choiceColor(choice, expected: card.expected), in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func choiceColor(_ choice: String, expected: String) -> Color {
        guard case .feedback = phase else { return Color("WoolCard") }
        if choice == expected { return .green.opacity(0.3) }
        if choice == answer { return .red.opacity(0.25) }
        return Color("WoolCard")
    }

    private func speakingInput(_ card: Card) -> some View {
        VStack(spacing: 12) {
            Button {
                Task {
                    if listener.isListening { _ = await listener.finish() } else { await listener.start() }
                }
            } label: {
                Label(listener.isListening ? "Fertig gesprochen" : "Tippen und sprechen",
                      systemImage: listener.isListening ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background((listener.isListening ? Color.red : Color.accentColor).opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(phase != .asking)

            if let heard = listener.transcripts.first {
                Text("Lingo hat gehört: „\(heard)“").foregroundStyle(.secondary)
            }
            if listener.unavailable {
                Text("Sprechen geht gerade nicht. Tipp das Wort lieber ein.").foregroundStyle(.secondary)
            }
            if phase == .asking {
                Button("Lieber tippen") { switchToTyping(card) }.font(.subheadline)
            }
        }
    }

    @ViewBuilder
    private func feedback(_ card: Card, expected: String) -> some View {
        if case .feedback(let result, let message) = phase {
            VStack(spacing: 10) {
                Text(result.title(variant: index)).font(.title.bold()).foregroundStyle(result.color)
                if !message.isEmpty { Text(message).multilineTextAlignment(.center) }
                if result != .correct {
                    Text(expected).font(.title2.bold())
                }
                HStack {
                    Text(card.word.english).font(.headline)
                    Button { Speaker.shared.speak(card.word.english, slow: true) } label: {
                        Image(systemName: "tortoise.fill")
                    }
                    .accessibilityLabel("Langsam vorlesen")
                }
                if !card.word.example.isEmpty {
                    Text(card.word.example).font(.callout).italic().foregroundStyle(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(result.color.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
            .transition(.scale.combined(with: .opacity))
        }
    }

    /// Beim Hören wird immer das englische Wort geschrieben, sonst gilt die Richtung der Karte.
    private func expected(_ card: Card, _ kind: ExerciseKind) -> String {
        kind == .listening ? card.word.english : card.expected
    }

    private func submitOrContinue(_ card: Card, _ kind: ExerciseKind) {
        switch phase {
        case .asking: Task { await check(card, kind) }
        case .feedback: next()
        default: break
        }
    }

    private func check(_ card: Card, _ kind: ExerciseKind) async {
        guard phase == .asking else { return }
        let expected = expected(card, kind)
        var result: AnswerResult
        var message = ""

        switch kind {
        case .multipleChoice:
            result = answer == expected ? .correct : .wrong
        case .speaking:
            let heard = listener.isListening ? await listener.finish() : listener.transcripts
            guard let first = heard.first else { return }
            answer = first
            result = Self.bestSpoken(heard, expected: expected)
            if result == .almost { message = "Fast! Sag es noch einmal ganz deutlich." }
        case .typing, .listening:
            guard !answer.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            switch AnswerChecker.check(answer: answer, expected: expected) {
            case .correct: result = .correct
            case .almost: result = .almost; message = "Fast! Achte auf die Schreibweise."
            case .wrong: result = .wrong
            case .unsure:
                phase = .checking
                do {
                    let direction: Direction = kind == .listening ? .deToEn : card.direction
                    let verdict = try await ProxyClient.shared.check(prompt: card.prompt, expected: expected, answer: answer, direction: direction)
                    result = verdict.verdict
                    message = verdict.feedback
                } catch {
                    // Ohne KI lieber gnädig sein, statt ein mögliches Synonym als falsch zu werten.
                    result = .almost
                    message = "Vergleiche selbst mit der Lösung."
                }
            }
        }

        card.word.record(result, direction: card.direction)
        results.append(result)
        award(result)
        phase = .feedback(result, message)
        Speaker.shared.speak(card.word.english)
    }

    /// Die Spracherkennung liefert mehrere Kandidaten; einer davon reicht.
    /// Was der Prüfer unsicher findet, gilt beim Sprechen als "fast", ohne die KI zu fragen.
    private static func bestSpoken(_ heard: [String], expected: String) -> AnswerResult {
        var best: AnswerResult = .wrong
        for text in heard {
            switch AnswerChecker.check(answer: text, expected: expected) {
            case .correct: return .correct
            case .almost, .unsure: best = .almost
            case .wrong: break
            }
        }
        return best
    }

    private func award(_ result: AnswerResult) {
        let levelBefore = progress.level
        earnedStars += Rewards.stars(for: result)
        if progress.award(result) {
            levelUp = true
            newAnimals += Herd.newlyUnlocked(from: levelBefore, to: progress.level)
        }
    }

    /// Jedes Paar ohne Fehlversuch bringt einen Stern; die Lernfächer bleiben beim Aufwärmen unverändert.
    private func finishPairs(clean: Int) {
        for _ in 0..<clean { award(.almost) }
        next()
    }

    private func switchToTyping(_ card: Card) {
        listener.cancel()
        steps[index] = .card(card, .typing, choices: [])
        focused = true
    }

    private func next() {
        answer = ""
        listener.reset()
        if index + 1 < steps.count {
            index += 1
            phase = .asking
        } else {
            finish()
        }
    }

    private func finish() {
        listener.cancel()
        let practiced = !results.isEmpty || earnedStars > 0
        if practiced { progress.finishSession() }
        if practiced { phase = .finished } else { dismiss() }
    }
}

/// Ein Schritt einer Übungsrunde.
enum QuizStep {
    case pairs([Word])
    case card(Card, ExerciseKind, choices: [String])

    static func session(from words: [Word], mode: QuizMode) -> [QuizStep] {
        let cards = Card.session(from: words, mode: mode)
        let canSpeak = SpeechListener.isAvailable
        var generator = SystemRandomNumberGenerator()
        var steps: [QuizStep] = cards.enumerated().map { position, card in
            var kind = Exercises.kind(box: card.word.box(card.direction), promptIsEnglish: card.direction == .enToDe,
                                      canSpeak: canSpeak, variant: position)
            var choices: [String] = []
            if kind == .multipleChoice {
                let pool = words.map { card.direction == .deToEn ? $0.english : $0.german }
                if let options = Exercises.choices(correct: card.expected, pool: pool, using: &generator) {
                    choices = options
                } else {
                    kind = .typing
                }
            }
            return .card(card, kind, choices: choices)
        }
        // Längere Runden beginnen mit Paare-Finden zum Aufwärmen.
        var seen = Set<PersistentIdentifier>()
        let pairWords = cards.map(\.word).filter { seen.insert($0.persistentModelID).inserted }.prefix(5)
        if cards.count >= 6, pairWords.count >= 4 {
            steps.insert(.pairs(Array(pairWords)), at: 0)
        }
        return steps
    }
}

extension ExerciseKind {
    func instruction(_ direction: Direction) -> String {
        switch self {
        case .listening: "Hör zu und schreib das englische Wort"
        case .speaking: "Sag es auf Englisch!"
        case .multipleChoice, .typing: direction == .deToEn ? "Wie heißt das auf Englisch?" : "Was bedeutet das auf Deutsch?"
        }
    }
}

extension AnswerResult {
    func title(variant: Int) -> String {
        switch self {
        case .correct: ["Lamastisch! ⭐️⭐️", "Richtig! ⭐️⭐️", "Super, Lama! ⭐️⭐️", "Genau! ⭐️⭐️"][variant % 4]
        case .almost: "Fast richtig! ⭐️"
        case .wrong: "Kein Drama, Lama!"
        }
    }

    var color: Color {
        switch self {
        case .correct: .green
        case .almost: .orange
        case .wrong: .red
        }
    }
}

private struct SummaryView: View {
    @Environment(PlayerProgress.self) private var progress
    let results: [AnswerResult]
    let stars: Int
    let levelUp: Bool
    let newAnimals: [Animal]
    let done: () -> Void

    @State private var shownAnimal: Animal?

    private var correct: Int { results.filter { $0 != .wrong }.count }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Text(levelUp ? "🎉" : correct == results.count ? "🦙" : "💪").font(.system(size: 90))
            if levelUp {
                Text("Level \(progress.level) erreicht!").font(.largeTitle.bold()).foregroundStyle(.tint)
                Text("Du bist jetzt: \(progress.levelTitle) 🦙").font(.title3)
            }
            ForEach(newAnimals) { animal in
                Button { shownAnimal = animal } label: {
                    HStack(spacing: 12) {
                        Text(animal.emoji).font(.system(size: 44))
                        VStack(alignment: .leading) {
                            Text("Neu in deiner Herde!").font(.caption.bold()).foregroundStyle(.tint)
                            Text(animal.name).font(.title3.bold())
                        }
                        Spacer()
                        Image(systemName: "chevron.right").foregroundStyle(.tertiary)
                    }
                    .padding()
                    .background(Color("WoolCard"), in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
            Text("\(correct) von \(results.count) gewusst").font(.title.bold())
            Label("+\(stars) Sterne", systemImage: "star.fill").font(.title2).foregroundStyle(.yellow)
            Label("\(progress.streak) \(progress.streak == 1 ? "Tag" : "Tage") in Folge", systemImage: "flame.fill")
                .font(.title3).foregroundStyle(.orange)
            Spacer()
            Button(action: done) {
                Text("Zurück").font(.title3.bold()).frame(maxWidth: .infinity).padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 16))
        }
        .sheet(item: $shownAnimal) { AnimalCard(animal: $0) }
    }
}
