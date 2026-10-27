import SwiftData
import SwiftUI

struct HomeView: View {
    @Environment(PlayerProgress.self) private var progress
    @Environment(\.modelContext) private var context
    @Query(sort: \Lesson.createdAt, order: .reverse) private var lessons: [Lesson]
    @Query private var words: [Word]

    @State private var quiz: QuizRequest?
    @State private var showNewLesson = false
    @State private var newLessonName = ""

    private var dueCount: Int {
        words.reduce(0) { count, word in
            count + Direction.allCases.filter { word.due($0) <= .now }.count
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ProgressHeader()

                    if words.isEmpty {
                        EmptyHint()
                    } else {
                        PracticeButton(dueCount: dueCount) { mode in
                            quiz = QuizRequest(words: words, mode: mode)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Lektionen").font(.title2.bold())
                            Spacer()
                            Button("Neu", systemImage: "plus.circle.fill") { showNewLesson = true }
                                .font(.headline)
                        }
                        ForEach(lessons) { lesson in
                            NavigationLink(value: lesson) { LessonRow(lesson: lesson) }
                                .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("VokabelHeld")
            .navigationDestination(for: Lesson.self) { LessonView(lesson: $0) }
            .alert("Neue Lektion", isPresented: $showNewLesson) {
                TextField("z. B. Unit 3", text: $newLessonName)
                Button("Anlegen") { addLesson() }
                Button("Abbrechen", role: .cancel) { newLessonName = "" }
            }
            .fullScreenCover(item: $quiz) { request in
                QuizView(words: request.words, mode: request.mode)
            }
        }
    }

    private func addLesson() {
        let name = newLessonName.trimmingCharacters(in: .whitespaces)
        newLessonName = ""
        guard !name.isEmpty else { return }
        context.insert(Lesson(name: name))
    }
}

struct QuizRequest: Identifiable {
    let id = UUID()
    let words: [Word]
    let mode: QuizMode
}

private struct ProgressHeader: View {
    @Environment(PlayerProgress.self) private var progress

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Stat(value: "\(progress.level)", label: "Level", symbol: "crown.fill", color: .purple)
                Stat(value: "\(progress.stars)", label: "Sterne", symbol: "star.fill", color: .yellow)
                Stat(value: "\(progress.streak)", label: progress.streak == 1 ? "Tag" : "Tage", symbol: "flame.fill",
                     color: progress.practicedToday ? .orange : .gray)
            }
            ProgressView(value: progress.levelProgress) {
                Text("Bis Level \(progress.level + 1)").font(.caption).foregroundStyle(.secondary)
            }
            .tint(.purple)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }

    private struct Stat: View {
        let value: String
        let label: String
        let symbol: String
        let color: Color

        var body: some View {
            VStack(spacing: 4) {
                Image(systemName: symbol).font(.title2).foregroundStyle(color)
                Text(value).font(.title.bold()).contentTransition(.numericText())
                Text(label).font(.caption).foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct PracticeButton: View {
    let dueCount: Int
    let start: (QuizMode) -> Void

    @State private var mode: QuizMode = .mixed

    var body: some View {
        VStack(spacing: 12) {
            Picker("Richtung", selection: $mode) {
                ForEach(QuizMode.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)

            Button { start(mode) } label: {
                VStack(spacing: 4) {
                    Text("Jetzt üben!").font(.title2.bold())
                    Text(dueCount > 0 ? "\(dueCount) Karten warten auf dich" : "Alles geschafft – extra Runde?")
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 20))
        }
    }
}

private struct LessonRow: View {
    let lesson: Lesson

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(lesson.name).font(.headline)
                Text("\(lesson.words.count) Wörter").font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            MasteryRing(value: lesson.words.isEmpty ? 0 : lesson.words.map(\.mastery).reduce(0, +) / Double(lesson.words.count))
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 16))
    }
}

/// Wie gut eine Lektion sitzt: Fach 1 = leer, Fach 5 = voll.
struct MasteryRing: View {
    let value: Double

    var body: some View {
        let fraction = max(0, (value - 1) / 4)
        ZStack {
            Circle().stroke(.quaternary, lineWidth: 5)
            Circle().trim(from: 0, to: fraction).stroke(.green, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 32, height: 32)
        .accessibilityLabel("\(Int(fraction * 100)) Prozent gelernt")
    }
}

private struct EmptyHint: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("👋 Hallo Valerie!").font(.title2.bold())
            Text("Leg eine Lektion an und tipp deine neuen Vokabeln ein. Dann kann's losgehen.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.background, in: RoundedRectangle(cornerRadius: 20))
    }
}
