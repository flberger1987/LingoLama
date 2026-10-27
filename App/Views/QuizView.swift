import SwiftUI
import VokabelKit

struct QuizView: View {
    @Environment(PlayerProgress.self) private var progress
    @Environment(\.dismiss) private var dismiss

    @State private var cards: [Card]
    @State private var index = 0
    @State private var answer = ""
    @State private var phase: Phase = .asking
    @State private var results: [AnswerResult] = []
    @State private var earnedStars = 0
    @State private var levelUp = false
    @State private var newAnimals: [Animal] = []
    @FocusState private var focused: Bool

    enum Phase: Equatable {
        case asking
        case checking
        case feedback(AnswerResult, String)
        case finished
    }

    init(words: [Word], mode: QuizMode) {
        _cards = State(initialValue: Card.session(from: words, mode: mode))
    }

    private var card: Card? { cards.indices.contains(index) ? cards[index] : nil }

    var body: some View {
        NavigationStack {
            Group {
                if phase == .finished || card == nil {
                    SummaryView(results: results, stars: earnedStars, levelUp: levelUp, newAnimals: newAnimals) { dismiss() }
                } else if let card {
                    question(card)
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
                    if phase != .finished, !cards.isEmpty {
                        ProgressView(value: Double(index), total: Double(cards.count)).frame(width: 160)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func question(_ card: Card) -> some View {
        VStack(spacing: 24) {
            Spacer()

            Text(card.direction == .deToEn ? "Wie heißt das auf Englisch?" : "Was bedeutet das auf Deutsch?")
                .font(.headline)
                .foregroundStyle(.secondary)

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

            TextField(card.direction == .deToEn ? "English" : "Deutsch", text: $answer)
                .font(.title2)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding()
                .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 16))
                .focused($focused)
                .disabled(phase != .asking)
                .onSubmit { submitOrContinue() }

            feedback(card)

            Spacer()

            Button(action: submitOrContinue) {
                Group {
                    switch phase {
                    case .checking: ProgressView()
                    case .feedback: Text(index + 1 < cards.count ? "Weiter" : "Fertig")
                    default: Text("Prüfen")
                    }
                }
                .font(.title3.bold())
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 16))
            .disabled(phase == .checking)
        }
        .onAppear { focused = true }
        .animation(.spring(duration: 0.3), value: phase)
    }

    @ViewBuilder
    private func feedback(_ card: Card) -> some View {
        if case .feedback(let result, let message) = phase {
            VStack(spacing: 10) {
                Text(result.title(variant: index)).font(.title.bold()).foregroundStyle(result.color)
                if !message.isEmpty { Text(message).multilineTextAlignment(.center) }
                if result != .correct {
                    Text(card.expected).font(.title2.bold())
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

    private func submitOrContinue() {
        switch phase {
        case .asking: Task { await check() }
        case .feedback: next()
        default: break
        }
    }

    private func check() async {
        guard let card, !answer.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        var result: AnswerResult
        var message = ""

        switch AnswerChecker.check(answer: answer, expected: card.expected) {
        case .correct: result = .correct
        case .almost: result = .almost; message = "Fast! Achte auf die Schreibweise."
        case .wrong: result = .wrong
        case .unsure:
            phase = .checking
            do {
                let verdict = try await ProxyClient.shared.check(prompt: card.prompt, expected: card.expected, answer: answer, direction: card.direction)
                result = verdict.verdict
                message = verdict.feedback
            } catch {
                // Ohne KI lieber gnädig sein, statt ein mögliches Synonym als falsch zu werten.
                result = .almost
                message = "Vergleiche selbst mit der Lösung."
            }
        }

        card.word.record(result, direction: card.direction)
        results.append(result)
        earnedStars += Rewards.stars(for: result)
        let levelBefore = progress.level
        if progress.award(result) {
            levelUp = true
            newAnimals += Herd.newlyUnlocked(from: levelBefore, to: progress.level)
        }
        phase = .feedback(result, message)
        Speaker.shared.speak(card.word.english)
    }

    private func next() {
        answer = ""
        if index + 1 < cards.count {
            index += 1
            phase = .asking
            focused = true
        } else {
            finish()
        }
    }

    private func finish() {
        if !results.isEmpty { progress.finishSession() }
        if results.isEmpty { dismiss() } else { phase = .finished }
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
