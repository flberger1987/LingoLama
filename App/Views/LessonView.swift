import SwiftData
import SwiftUI

struct LessonView: View {
    @Bindable var lesson: Lesson
    @Environment(\.modelContext) private var context

    @State private var showAdd = false
    @State private var editing: Word?
    @State private var quiz: QuizRequest?

    private var words: [Word] { lesson.words.sorted { $0.createdAt < $1.createdAt } }

    var body: some View {
        List {
            if !words.isEmpty {
                Section {
                    Menu {
                        ForEach(QuizMode.allCases) { mode in
                            Button(mode.label) { quiz = QuizRequest(words: lesson.words, mode: mode) }
                        }
                    } label: {
                        Label("Diese Lektion üben", systemImage: "play.fill").font(.headline)
                    }
                }
            }

            Section("\(words.count) Wörter") {
                ForEach(words) { word in
                    Button { editing = word } label: { WordRow(word: word) }
                        .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    for index in offsets { context.delete(words[index]) }
                }

                Button("Wörter hinzufügen", systemImage: "plus") { showAdd = true }
            }
        }
        .navigationTitle(lesson.name)
        .toolbar {
            Button("Hinzufügen", systemImage: "plus") { showAdd = true }
        }
        .sheet(isPresented: $showAdd) { AddWordsView(lesson: lesson) }
        .sheet(item: $editing) { EditWordView(word: $0) }
        .fullScreenCover(item: $quiz) { QuizView(words: $0.words, mode: $0.mode) }
        .overlay {
            if words.isEmpty {
                ContentUnavailableView("Noch keine Wörter", systemImage: "text.book.closed",
                                       description: Text("Tipp oben auf + und gib die englischen Wörter ein."))
            }
        }
    }
}

private struct WordRow: View {
    let word: Word

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(word.english).font(.headline)
                Text(word.german).foregroundStyle(.secondary)
            }
            Spacer()
            Button { Speaker.shared.speak(word.english) } label: {
                Image(systemName: "speaker.wave.2.fill")
            }
            .buttonStyle(.borderless)
            MasteryRing(value: word.mastery)
        }
        .contentShape(Rectangle())
    }
}

struct EditWordView: View {
    @Bindable var word: Word
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Englisch") { TextField("english", text: $word.english).textInputAutocapitalization(.never) }
                Section("Deutsch") { TextField("Deutsch", text: $word.german) }
                Section("Beispielsatz") { TextField("Example", text: $word.example, axis: .vertical) }
                Section {
                    Button("Neu lernen (zurück in Fach 1)") {
                        word.boxDeEn = 1; word.boxEnDe = 1
                        word.dueDeEn = .distantPast; word.dueEnDe = .distantPast
                    }
                }
            }
            .navigationTitle(word.english)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Fertig") { dismiss() } }
        }
    }
}
