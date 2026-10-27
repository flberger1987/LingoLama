import SwiftData
import SwiftUI

/// Valerie tippt nur die englischen Wörter, die KI korrigiert und ergänzt den Rest.
struct AddWordsView: View {
    let lesson: Lesson
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var input = ""
    @State private var suggestions: [ProxyClient.Suggestion] = []
    @State private var selected: Set<String> = []
    @State private var loading = false
    @State private var error: String?

    private var inputWords: [String] {
        var seen = Set<String>()
        return input.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
    }

    private var ready: [ProxyClient.Suggestion] {
        suggestions.filter { selected.contains($0.id) && !$0.german.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var body: some View {
        NavigationStack {
            Group {
                if suggestions.isEmpty { inputStep } else { reviewStep }
            }
            .navigationTitle("Neue Wörter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Abbrechen") { dismiss() } }
            }
        }
    }

    private var inputStep: some View {
        Form {
            Section {
                TextEditor(text: $input)
                    .frame(minHeight: 220)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            } header: {
                Text("Englische Wörter – eins pro Zeile")
            } footer: {
                Text("Keine Sorge wegen Tippfehlern, die KI hilft dir.")
            }

            if let error {
                Section { Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.orange) }
            }

            Section {
                Button {
                    Task { await enrich() }
                } label: {
                    HStack {
                        Spacer()
                        if loading { ProgressView() } else { Label("Prüfen & ergänzen", systemImage: "sparkles").font(.headline) }
                        Spacer()
                    }
                }
                .disabled(inputWords.isEmpty || loading)

                if !ProxyClient.shared.isConfigured || error != nil {
                    Button("Ohne KI hinzufügen (Deutsch selbst eintragen)") { addWithoutAI() }
                        .disabled(inputWords.isEmpty)
                }
            }
        }
    }

    private var reviewStep: some View {
        Form {
            Section {
                ForEach($suggestions) { $suggestion in
                    SuggestionRow(suggestion: $suggestion, isSelected: selected.contains(suggestion.id)) {
                        if selected.contains(suggestion.id) { selected.remove(suggestion.id) } else { selected.insert(suggestion.id) }
                    }
                }
            } header: {
                Text("Stimmt alles? Tipp an, was du übernehmen willst.")
            }

            Section {
                Button {
                    save()
                } label: {
                    HStack {
                        Spacer()
                        Text("\(ready.count) Wörter speichern").font(.headline)
                        Spacer()
                    }
                }
                .disabled(ready.isEmpty)
            } footer: {
                if ready.count < selected.count {
                    Text("Wörter ohne deutsche Bedeutung werden nicht gespeichert.")
                }
            }
        }
    }

    private func enrich() async {
        loading = true
        error = nil
        defer { loading = false }
        do {
            let result = try await ProxyClient.shared.enrich(Array(inputWords.prefix(40)))
            suggestions = result
            selected = Set(result.filter { !$0.german.isEmpty }.map(\.id))
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func save() {
        for suggestion in ready {
            let word = Word(english: suggestion.english.trimmingCharacters(in: .whitespaces),
                            german: suggestion.german.trimmingCharacters(in: .whitespaces),
                            example: suggestion.example)
            context.insert(word)
            word.lesson = lesson
        }
        dismiss()
    }

    private func addWithoutAI() {
        suggestions = inputWords.map {
            ProxyClient.Suggestion(input: $0, english: $0, german: "", example: "", corrected: false, note: "")
        }
        selected = Set(suggestions.map(\.id))
        error = nil
    }
}

private struct SuggestionRow: View {
    @Binding var suggestion: ProxyClient.Suggestion
    let isSelected: Bool
    let toggle: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button(action: toggle) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(isSelected ? .green : .secondary)
            }
            .buttonStyle(.borderless)

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    TextField("english", text: $suggestion.english)
                        .font(.headline)
                        .textInputAutocapitalization(.never)
                    Button { Speaker.shared.speak(suggestion.english) } label: { Image(systemName: "speaker.wave.2.fill") }
                        .buttonStyle(.borderless)
                }
                TextField("Deutsch", text: $suggestion.german)
                if suggestion.corrected {
                    Text("Du hattest: \(suggestion.input)").font(.caption).strikethrough().foregroundStyle(.secondary)
                }
                if !suggestion.note.isEmpty {
                    Label(suggestion.note, systemImage: "lightbulb.fill").font(.caption).foregroundStyle(.orange)
                }
                if !suggestion.example.isEmpty {
                    Text(suggestion.example).font(.caption).italic().foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
