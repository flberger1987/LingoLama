import Foundation

public enum Rewards {
    public static func stars(for result: AnswerResult) -> Int {
        switch result {
        case .correct: 2
        case .almost: 1
        case .wrong: 0
        }
    }

    /// Level 1 ab 0 Sternen, jedes Level braucht 20 Sterne mehr als das vorige.
    public static func level(forStars stars: Int) -> Int {
        var level = 1
        var needed = 50
        var remaining = stars
        while remaining >= needed {
            remaining -= needed
            level += 1
            needed += 20
        }
        return level
    }

    /// Fortschritt innerhalb des aktuellen Levels, 0...1.
    public static func levelProgress(forStars stars: Int) -> Double {
        var needed = 50
        var remaining = stars
        while remaining >= needed {
            remaining -= needed
            needed += 20
        }
        return Double(remaining) / Double(needed)
    }

    /// Neue Tages-Serie nach einer Übung heute.
    public static func streak(current: Int, lastPractice: Date?, now: Date, calendar: Calendar = .current) -> Int {
        guard let lastPractice else { return 1 }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastPractice), to: calendar.startOfDay(for: now)).day ?? 0
        switch days {
        case ..<1: return max(current, 1)
        case 1: return current + 1
        default: return 1
        }
    }

    /// Serie, wie sie jetzt angezeigt wird (verfällt, wenn gestern nicht geübt wurde).
    public static func displayedStreak(current: Int, lastPractice: Date?, now: Date, calendar: Calendar = .current) -> Int {
        guard let lastPractice else { return 0 }
        let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastPractice), to: calendar.startOfDay(for: now)).day ?? 0
        return days <= 1 ? current : 0
    }
}
