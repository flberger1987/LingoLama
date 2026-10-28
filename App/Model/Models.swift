import Foundation
import SwiftData
import VokabelKit

@Model
final class Lesson {
    var name: String
    var createdAt: Date
    @Relationship(deleteRule: .cascade, inverse: \Word.lesson)
    var words: [Word] = []

    init(name: String, createdAt: Date = .now) {
        self.name = name
        self.createdAt = createdAt
    }
}

/// Jede Vokabel hat zwei Karteikarten: Deutsch → Englisch und Englisch → Deutsch.
@Model
final class Word {
    var english: String
    var german: String
    var example: String
    var createdAt: Date
    var lesson: Lesson?

    var boxDeEn: Int = 1
    var dueDeEn: Date = Date.distantPast
    var boxEnDe: Int = 1
    var dueEnDe: Date = Date.distantPast
    var timesCorrect: Int = 0
    var timesWrong: Int = 0

    init(english: String, german: String, example: String = "", createdAt: Date = .now) {
        self.english = english
        self.german = german
        self.example = example
        self.createdAt = createdAt
    }

    func box(_ direction: Direction) -> Int {
        direction == .deToEn ? boxDeEn : boxEnDe
    }

    func due(_ direction: Direction) -> Date {
        direction == .deToEn ? dueDeEn : dueEnDe
    }

    func record(_ result: AnswerResult, direction: Direction, now: Date = .now) {
        let box = Leitner.nextBox(after: box(direction), result: result)
        // "Fast richtig" kommt morgen noch einmal dran.
        let due = result == .almost
            ? Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: now))!
            : Leitner.nextDue(box: box, from: now)
        switch direction {
        case .deToEn: boxDeEn = box; dueDeEn = due
        case .enToDe: boxEnDe = box; dueEnDe = due
        }
        if result == .wrong { timesWrong += 1 } else { timesCorrect += 1 }
    }

    /// Durchschnittliches Fach beider Richtungen, 1...5.
    var mastery: Double { Double(boxDeEn + boxEnDe) / 2 }
}

enum Direction: String, CaseIterable, Codable, Identifiable {
    case deToEn, enToDe
    var id: String { rawValue }

    var label: String {
        switch self {
        case .deToEn: "German → English"
        case .enToDe: "English → German"
        }
    }
}

enum QuizMode: String, CaseIterable, Identifiable {
    case deToEn, enToDe, mixed
    var id: String { rawValue }

    var label: String {
        switch self {
        case .deToEn: "🇩🇪 → 🇬🇧"
        case .enToDe: "🇬🇧 → 🇩🇪"
        case .mixed: "Mixed"
        }
    }

    var directions: [Direction] {
        switch self {
        case .deToEn: [.deToEn]
        case .enToDe: [.enToDe]
        case .mixed: Direction.allCases
        }
    }
}

struct Card: Identifiable, Hashable {
    let word: Word
    let direction: Direction
    var id: String { "\(word.persistentModelID.hashValue)-\(direction.rawValue)" }

    var prompt: String { direction == .deToEn ? word.german : word.english }
    var expected: String { direction == .deToEn ? word.english : word.german }

    static func == (a: Card, b: Card) -> Bool { a.id == b.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }

    /// Fällige Karten; reicht das nicht, wird mit den schwächsten aufgefüllt, damit man immer üben kann.
    static func session(from words: [Word], mode: QuizMode, limit: Int = 12, now: Date = .now) -> [Card] {
        let all = words.flatMap { word in mode.directions.map { Card(word: word, direction: $0) } }
        var cards = Leitner.sessionOrder(all, box: { $0.word.box($0.direction) }, due: { $0.word.due($0.direction) }, now: now, limit: limit)
        if cards.count < min(limit, all.count) {
            let extra = all
                .filter { !cards.contains($0) }
                .sorted { $0.word.box($0.direction) < $1.word.box($1.direction) }
                .prefix(min(limit, all.count) - cards.count)
            cards += extra
        }
        return cards.shuffled()
    }
}
