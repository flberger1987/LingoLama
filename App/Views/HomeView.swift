import SwiftData
import SwiftUI
import VokabelKit

struct HomeView: View {
    @Environment(PlayerProgress.self) private var progress
    @Environment(\.modelContext) private var context
    @Query(sort: \Lesson.createdAt, order: .reverse) private var lessons: [Lesson]
    @Query private var words: [Word]

    @State private var quiz: QuizRequest?
    @State private var showNewLesson = false
    @State private var newLessonName = ""
    @State private var showWardrobe = false
    @State private var showHerd = false
    @State private var showBuddies = false

    private var dueCount: Int {
        words.reduce(0) { count, word in
            count + Direction.allCases.filter { word.due($0) <= .now }.count
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    CompanionCard(openWardrobe: { showWardrobe = true }, changeBuddy: { showBuddies = true })
                    ProgressHeader()
                    HerdRow { showHerd = true }

                    if words.isEmpty {
                        EmptyHint()
                    } else {
                        PracticeButton(dueCount: dueCount) { mode in
                            quiz = QuizRequest(words: words, mode: mode)
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Lessons").font(.title2.bold())
                            Spacer()
                            Button("New", systemImage: "plus.circle.fill") { showNewLesson = true }
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
            .background(Color("Wool"))
            .navigationTitle("LingoLama")
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: Lesson.self) { LessonView(lesson: $0) }
            .alert("New lesson", isPresented: $showNewLesson) {
                TextField("e.g. Unit 3", text: $newLessonName)
                Button("Create") { addLesson() }
                Button("Cancel", role: .cancel) { newLessonName = "" }
            }
            .fullScreenCover(item: $quiz) { request in
                QuizView(words: request.words, mode: request.mode)
            }
            .sheet(isPresented: $showWardrobe) { WardrobeView() }
            .sheet(isPresented: $showHerd) { HerdView() }
            .sheet(isPresented: $showBuddies) { BuddySwitcherView() }
            .fullScreenCover(isPresented: Binding(get: { progress.starter == nil }, set: { _ in })) {
                StarterPickerView()
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

private struct CompanionCard: View {
    @Environment(PlayerProgress.self) private var progress
    let openWardrobe: () -> Void
    let changeBuddy: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            Button(action: openWardrobe) { CompanionView(size: 100) }
                .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 6) {
                Text("Hello Valerie!").font(.title2.bold())
                if let companion = progress.companion {
                    Text("“\(companion.spruch)\u{2060}”")
                        .font(.subheadline.italic())
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(spacing: 8) {
                    Button("Rewards", systemImage: "gift.fill", action: openWardrobe)
                        .buttonStyle(.borderedProminent)
                    Button("Change buddy", systemImage: "arrow.triangle.2.circlepath", action: changeBuddy)
                        .buttonStyle(.bordered)
                        .labelStyle(.iconOnly)
                        .accessibilityLabel("Change buddy")
                }
                .controlSize(.small)
            }
            Spacer(minLength: 0)
        }
        .padding()
        .background(Color("WoolCard"), in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct HerdRow: View {
    @Environment(PlayerProgress.self) private var progress
    let open: () -> Void

    var body: some View {
        let herd = progress.unlockedHerd
        Button(action: open) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your herd").font(.headline)
                    HStack(spacing: -10) {
                        ForEach(herd.suffix(6).reversed()) { avatar in
                            LernAvatarBild(avatar: avatar)
                                .frame(width: 40, height: 40)
                                .background(Color("Wool"), in: Circle())
                                .clipShape(Circle())
                                .overlay { Circle().strokeBorder(Color("WoolCard"), lineWidth: 2) }
                        }
                    }
                    if herd.count == 1 {
                        Text("New friends join you at level 2").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Text("\(herd.count)/\(progress.herd.count)").font(.subheadline.bold()).foregroundStyle(.secondary)
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            }
            .padding()
            .background(Color("WoolCard"), in: RoundedRectangle(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

private struct ProgressHeader: View {
    @Environment(PlayerProgress.self) private var progress

    var body: some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Stat(value: "\(progress.level)", label: "Level", symbol: "crown.fill", color: .accentColor)
                Stat(value: "\(progress.availableStars)", label: "Stars", symbol: "star.fill", color: .yellow)
                Stat(value: "\(progress.streak)", label: progress.streak == 1 ? "day" : "days", symbol: "flame.fill",
                     color: progress.practicedToday ? .orange : .gray)
            }
            ProgressView(value: progress.levelProgress) {
                Text("\(progress.levelTitle) · next: level \(progress.level + 1)").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color("WoolCard"), in: RoundedRectangle(cornerRadius: 20))
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
            Picker("Direction", selection: $mode) {
                ForEach(QuizMode.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)

            Button { start(mode) } label: {
                VStack(spacing: 4) {
                    Text("Let's practise!").font(.title2.bold())
                    Text(dueCount > 0 ? "\(dueCount) cards are waiting for you" : "All done – one more round?")
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
                Text("\(lesson.words.count) words").font(.subheadline).foregroundStyle(.secondary)
            }
            Spacer()
            MasteryRing(value: lesson.words.isEmpty ? 0 : lesson.words.map(\.mastery).reduce(0, +) / Double(lesson.words.count))
            Image(systemName: "chevron.right").foregroundStyle(.tertiary)
        }
        .padding()
        .background(Color("WoolCard"), in: RoundedRectangle(cornerRadius: 16))
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
        .accessibilityLabel("\(Int(fraction * 100)) percent learned")
    }
}

private struct EmptyHint: View {
    @Environment(PlayerProgress.self) private var progress

    var body: some View {
        VStack(spacing: 8) {
            Text("Let's get started").font(.title3.bold())
            Text("I'm \(progress.companion?.name ?? "your llama"), your learning buddy. Add a lesson and type in your new words. Every right answer earns stars for rewards!")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color("WoolCard"), in: RoundedRectangle(cornerRadius: 20))
    }
}
