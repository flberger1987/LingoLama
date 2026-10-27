import Foundation
import Observation
import VokabelKit

/// Sterne, Serie und Level. Klein genug für UserDefaults.
@Observable
final class PlayerProgress {
    private let defaults: UserDefaults

    private(set) var stars: Int { didSet { defaults.set(stars, forKey: "stars") } }
    private(set) var streakCount: Int { didSet { defaults.set(streakCount, forKey: "streak") } }
    private(set) var lastPractice: Date? { didSet { defaults.set(lastPractice, forKey: "lastPractice") } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        stars = defaults.integer(forKey: "stars")
        streakCount = defaults.integer(forKey: "streak")
        lastPractice = defaults.object(forKey: "lastPractice") as? Date
    }

    var level: Int { Rewards.level(forStars: stars) }
    var levelProgress: Double { Rewards.levelProgress(forStars: stars) }
    var streak: Int { Rewards.displayedStreak(current: streakCount, lastPractice: lastPractice, now: .now) }
    var practicedToday: Bool { lastPractice.map(Calendar.current.isDateInToday) ?? false }

    /// Gibt zurück, ob dadurch ein neues Level erreicht wurde.
    @discardableResult
    func award(_ result: AnswerResult) -> Bool {
        let before = level
        stars += Rewards.stars(for: result)
        return level > before
    }

    func finishSession(now: Date = .now) {
        streakCount = Rewards.streak(current: streakCount, lastPractice: lastPractice, now: now)
        lastPractice = now
    }
}
