import SwiftData
import SwiftUI

/// Aufwärmen: englische und deutsche Wörter einander zuordnen.
/// Meldet am Ende, wie viele Paare ohne Fehlversuch gefunden wurden.
struct PairsView: View {
    let done: (_ cleanPairs: Int) -> Void

    @State private var left: [Word]
    @State private var right: [Word]
    @State private var selectedLeft: Word?
    @State private var selectedRight: Word?
    @State private var matched: Set<PersistentIdentifier> = []
    @State private var missed: Set<PersistentIdentifier> = []
    @State private var wrongLeft: PersistentIdentifier?
    @State private var wrongRight: PersistentIdentifier?

    init(words: [Word], done: @escaping (_ cleanPairs: Int) -> Void) {
        self.done = done
        _left = State(initialValue: words.shuffled())
        _right = State(initialValue: words.shuffled())
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text("Warm-up").font(.headline).foregroundStyle(.secondary)
            Text("Find the pairs!").font(.title.bold())
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 10) {
                    ForEach(left) { word in
                        tile(word.english, word: word, selected: selectedLeft === word, wrong: wrongLeft == word.persistentModelID) {
                            Speaker.shared.speak(word.english)
                            selectedLeft = word
                            tryMatch()
                        }
                    }
                }
                VStack(spacing: 10) {
                    ForEach(right) { word in
                        tile(word.german, word: word, selected: selectedRight === word, wrong: wrongRight == word.persistentModelID) {
                            selectedRight = word
                            tryMatch()
                        }
                    }
                }
            }
            Spacer()
        }
    }

    private func tile(_ text: String, word: Word, selected: Bool, wrong: Bool, action: @escaping () -> Void) -> some View {
        let isMatched = matched.contains(word.persistentModelID)
        let background = wrong ? Color.red.opacity(0.25) : isMatched ? Color.green.opacity(0.35) : Color("WoolCard")
        return Button(action: action) {
            Text(text)
                .font(.headline)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .frame(maxWidth: .infinity, minHeight: 56)
                .padding(.horizontal, 8)
                .background(background, in: RoundedRectangle(cornerRadius: 14))
                .overlay {
                    RoundedRectangle(cornerRadius: 14).strokeBorder(Color.accentColor, lineWidth: selected ? 3 : 0)
                }
        }
        .buttonStyle(.plain)
        .disabled(isMatched)
        .opacity(isMatched ? 0.6 : 1)
    }

    private func tryMatch() {
        guard let l = selectedLeft, let r = selectedRight else { return }
        selectedLeft = nil
        selectedRight = nil
        if l.persistentModelID == r.persistentModelID {
            withAnimation { _ = matched.insert(l.persistentModelID) }
            if matched.count == left.count {
                let clean = left.filter { !missed.contains($0.persistentModelID) }.count
                Task {
                    try? await Task.sleep(for: .milliseconds(600))
                    done(clean)
                }
            }
        } else {
            missed.insert(l.persistentModelID)
            missed.insert(r.persistentModelID)
            wrongLeft = l.persistentModelID
            wrongRight = r.persistentModelID
            Task {
                try? await Task.sleep(for: .milliseconds(500))
                withAnimation {
                    wrongLeft = nil
                    wrongRight = nil
                }
            }
        }
    }
}
