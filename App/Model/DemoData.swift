#if DEBUG
import Foundation
import SwiftData

/// Beispiel-Lektionen zum Ausprobieren, nur in Debug-Builds.
/// Unit 1 sitzt schon gut, Unit 2 halb, Unit 3 ist neu. Dazu 45 Sterne, damit die erste Runde Level 2 bringt.
enum DemoData {
    private struct Entry {
        let english: String
        let german: String
        let example: String
        /// Fach beider Richtungen; ab Fach 2 ist das Wort erst in ein paar Tagen wieder fällig.
        var box = 1
    }

    private static let lessons: [(name: String, entries: [Entry])] = [
        ("Unit 1 – My family", [
            Entry(english: "mother", german: "die Mutter", example: "My mother is a doctor.", box: 4),
            Entry(english: "father", german: "der Vater", example: "My father likes football.", box: 5),
            Entry(english: "sister", german: "die Schwester", example: "My sister is ten years old.", box: 4),
            Entry(english: "brother", german: "der Bruder", example: "I have got two brothers.", box: 3),
            Entry(english: "grandma", german: "die Oma", example: "Grandma makes the best cake.", box: 3),
            Entry(english: "friend", german: "der Freund, die Freundin", example: "Lisa is my best friend.", box: 2),
            Entry(english: "because", german: "weil", example: "I'm happy because it's Friday.", box: 2),
        ]),
        ("Unit 2 – At school", [
            Entry(english: "teacher", german: "der Lehrer, die Lehrerin", example: "Our teacher is very nice.", box: 3),
            Entry(english: "homework", german: "die Hausaufgaben", example: "I do my homework after lunch.", box: 2),
            Entry(english: "pencil case", german: "das Federmäppchen", example: "My pencil case is blue."),
            Entry(english: "ruler", german: "das Lineal", example: "Can I borrow your ruler?"),
            Entry(english: "to read", german: "lesen", example: "I like to read books about animals.", box: 2),
            Entry(english: "to write", german: "schreiben", example: "Please write your name on the paper."),
            Entry(english: "break", german: "die Pause", example: "We play outside in the break."),
        ]),
        ("Unit 3 – Animals", [
            Entry(english: "llama", german: "das Lama", example: "The llama lives in the mountains."),
            Entry(english: "horse", german: "das Pferd", example: "She rides her horse every Sunday."),
            Entry(english: "bird", german: "der Vogel", example: "A little bird is singing."),
            Entry(english: "beautiful", german: "schön", example: "What a beautiful butterfly!"),
            Entry(english: "to feed", german: "füttern", example: "We feed the ducks at the lake."),
            Entry(english: "wool", german: "die Wolle", example: "Llama wool is very soft."),
        ]),
    ]

    static func load(into context: ModelContext, progress: PlayerProgress, now: Date = .now) {
        for (offset, lesson) in lessons.enumerated() {
            // Ältere Lektionen zuerst anlegen, damit Unit 3 oben steht.
            let created = Calendar.current.date(byAdding: .day, value: offset - lessons.count, to: now)!
            let model = Lesson(name: lesson.name, createdAt: created)
            context.insert(model)
            for entry in lesson.entries {
                let word = Word(english: entry.english, german: entry.german, example: entry.example, createdAt: created)
                word.lesson = model
                if entry.box > 1 {
                    let due = Calendar.current.date(byAdding: .day, value: entry.box, to: now)!
                    word.boxDeEn = entry.box; word.dueDeEn = due
                    word.boxEnDe = entry.box; word.dueEnDe = due
                    word.timesCorrect = entry.box * 2 - 2
                }
            }
        }
        progress.setDemoStars(45)
    }
}
#endif
