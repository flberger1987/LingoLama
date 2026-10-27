import Foundation

/// Karteikasten mit 5 Fächern. Richtig → ein Fach weiter, falsch → zurück in Fach 1.
public enum Leitner {
    public static let boxCount = 5

    /// Tage bis zur nächsten Abfrage je Fach (Index 0 = Fach 1).
    public static let intervals = [0, 1, 3, 7, 14]

    public static func nextBox(after box: Int, result: AnswerResult) -> Int {
        switch result {
        case .correct: min(box + 1, boxCount)
        case .almost: box
        case .wrong: 1
        }
    }

    public static func nextDue(box: Int, from date: Date, calendar: Calendar = .current) -> Date {
        let days = intervals[max(0, min(box, boxCount) - 1)]
        let start = calendar.startOfDay(for: date)
        return calendar.date(byAdding: .day, value: days, to: start) ?? start
    }

    /// Fällige Karten zuerst die aus niedrigen Fächern, dann die am längsten überfälligen.
    public static func sessionOrder<T>(_ cards: [T], box: (T) -> Int, due: (T) -> Date, now: Date, limit: Int) -> [T] {
        cards
            .filter { due($0) <= now }
            .sorted { (box($0), due($0)) < (box($1), due($1)) }
            .prefix(limit)
            .map { $0 }
    }
}
