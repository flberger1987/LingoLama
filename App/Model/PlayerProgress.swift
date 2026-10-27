import Foundation
import Observation
import VokabelKit

/// Sterne, Serie, Level und Lingos Kleiderschrank. Klein genug für UserDefaults.
@Observable
final class PlayerProgress {
    private let defaults: UserDefaults

    /// Alle jemals verdienten Sterne. Daraus ergibt sich das Level, Ausgeben ändert es nicht.
    private(set) var stars: Int { didSet { defaults.set(stars, forKey: "stars") } }
    private(set) var spentStars: Int { didSet { defaults.set(spentStars, forKey: "spentStars") } }
    private(set) var streakCount: Int { didSet { defaults.set(streakCount, forKey: "streak") } }
    private(set) var lastPractice: Date? { didSet { defaults.set(lastPractice, forKey: "lastPractice") } }
    private(set) var owned: Set<String> { didSet { defaults.set(Array(owned), forKey: "ownedAccessories") } }
    /// Slot-Rohwert → Accessoire-ID
    private var outfit: [String: String] { didSet { defaults.set(outfit, forKey: "outfit") } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        stars = defaults.integer(forKey: "stars")
        spentStars = defaults.integer(forKey: "spentStars")
        streakCount = defaults.integer(forKey: "streak")
        lastPractice = defaults.object(forKey: "lastPractice") as? Date
        owned = Set(defaults.stringArray(forKey: "ownedAccessories") ?? [])
        outfit = defaults.dictionary(forKey: "outfit") as? [String: String] ?? [:]
    }

    var level: Int { Rewards.level(forStars: stars) }
    var levelTitle: String { Self.levelTitles[min(level, Self.levelTitles.count) - 1] }
    var levelProgress: Double { Rewards.levelProgress(forStars: stars) }
    var availableStars: Int { stars - spentStars }
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

    // MARK: Kleiderschrank

    func wearing(_ slot: Slot) -> Accessory? {
        outfit[slot.rawValue].flatMap(Wardrobe.accessory(id:))
    }

    func isWearing(_ item: Accessory) -> Bool {
        outfit[item.slot.rawValue] == item.id
    }

    func purchaseProblem(for item: Accessory) -> Wardrobe.PurchaseProblem? {
        Wardrobe.purchaseProblem(for: item, owned: owned, availableStars: availableStars)
    }

    /// Kauft das Teil und zieht es Lingo gleich an.
    func buy(_ item: Accessory) {
        guard purchaseProblem(for: item) == nil else { return }
        spentStars += item.price
        owned.insert(item.id)
        outfit[item.slot.rawValue] = item.id
    }

    /// Zieht ein gekauftes Teil an oder wieder aus.
    func toggle(_ item: Accessory) {
        guard owned.contains(item.id) else { return }
        outfit[item.slot.rawValue] = isWearing(item) ? nil : item.id
    }

    #if DEBUG
    /// Für die Demodaten: Sterne setzen, Kleiderschrank leeren.
    func setDemoStars(_ value: Int) {
        stars = value
        spentStars = 0
        owned = []
        outfit = [:]
    }
    #endif

    /// Lama-Rang pro Level, ab dem letzten bleibt er gleich.
    private static let levelTitles = [
        "Lama-Baby", "Kleines Lama", "Wolliges Lama", "Flinkes Lama", "Kletter-Lama",
        "Berg-Lama", "Anden-Lama", "Lama-Profi", "Lama-Champion", "Lama-Legende",
    ]
}
