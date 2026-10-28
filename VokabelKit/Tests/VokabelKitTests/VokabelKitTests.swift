import Foundation
import Testing
@testable import VokabelKit

struct AnswerCheckerTests {
    @Test func exactAndNormalized() {
        #expect(AnswerChecker.check(answer: "Dog", expected: "dog") == .correct)
        #expect(AnswerChecker.check(answer: " the dog ", expected: "dog") == .correct)
        #expect(AnswerChecker.check(answer: "go", expected: "to go") == .correct)
        #expect(AnswerChecker.check(answer: "Hund", expected: "der Hund") == .correct)
        #expect(AnswerChecker.check(answer: "don’t", expected: "don't") == .correct)
    }

    @Test func alternativesAndBrackets() {
        #expect(AnswerChecker.check(answer: "Hündin", expected: "der Hund, die Hündin") == .correct)
        #expect(AnswerChecker.check(answer: "go", expected: "to go (went, gone)") == .correct)
    }

    @Test func smallTypoIsAlmost() {
        #expect(AnswerChecker.check(answer: "becuse", expected: "because") == .almost)
        #expect(AnswerChecker.check(answer: "freind", expected: "friend") == .unsure)
        #expect(AnswerChecker.check(answer: "beautifull", expected: "beautiful") == .almost)
    }

    @Test func farOffIsWrong() {
        #expect(AnswerChecker.check(answer: "", expected: "dog") == .wrong)
        #expect(AnswerChecker.check(answer: "elephant", expected: "dog") == .wrong)
    }
}

struct LeitnerTests {
    @Test func boxes() {
        #expect(Leitner.nextBox(after: 1, result: .correct) == 2)
        #expect(Leitner.nextBox(after: 5, result: .correct) == 5)
        #expect(Leitner.nextBox(after: 4, result: .wrong) == 1)
        #expect(Leitner.nextBox(after: 3, result: .almost) == 3)
    }

    @Test func dueDates() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Berlin")!
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let today = calendar.startOfDay(for: now)
        #expect(Leitner.nextDue(box: 1, from: now, calendar: calendar) == today)
        #expect(Leitner.nextDue(box: 3, from: now, calendar: calendar) == calendar.date(byAdding: .day, value: 3, to: today))
    }

    @Test func sessionOrderPrefersLowBoxes() {
        let now = Date()
        let cards = [(box: 3, due: now.addingTimeInterval(-10)), (box: 1, due: now), (box: 2, due: now.addingTimeInterval(100))]
        let order = Leitner.sessionOrder(cards, box: \.box, due: \.due, now: now, limit: 10)
        #expect(order.map(\.box) == [1, 3])
    }
}

struct RewardsTests {
    @Test func levels() {
        #expect(Rewards.level(forStars: 0) == 1)
        #expect(Rewards.level(forStars: 49) == 1)
        #expect(Rewards.level(forStars: 50) == 2)
        #expect(Rewards.level(forStars: 120) == 3)
        #expect(Rewards.levelProgress(forStars: 85) == 0.5)
    }

    @Test func streaks() {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date()
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!
        let lastWeek = calendar.date(byAdding: .day, value: -7, to: now)!
        #expect(Rewards.streak(current: 4, lastPractice: yesterday, now: now, calendar: calendar) == 5)
        #expect(Rewards.streak(current: 4, lastPractice: now, now: now, calendar: calendar) == 4)
        #expect(Rewards.streak(current: 4, lastPractice: lastWeek, now: now, calendar: calendar) == 1)
        #expect(Rewards.streak(current: 0, lastPractice: nil, now: now, calendar: calendar) == 1)
        #expect(Rewards.displayedStreak(current: 4, lastPractice: lastWeek, now: now, calendar: calendar) == 0)
    }
}

struct WardrobeTests {
    @Test func catalogIsConsistent() {
        let ids = Wardrobe.catalog.map(\.id)
        #expect(Set(ids).count == ids.count)
        #expect(Wardrobe.catalog.allSatisfy { $0.price > 0 })
        #expect(Set(Wardrobe.catalog.map(\.slot)) == Set(Slot.allCases))
    }

    @Test func purchaseRules() {
        let cap = Wardrobe.accessory(id: "cap")!
        #expect(Wardrobe.purchaseProblem(for: cap, owned: [], availableStars: 20) == nil)
        #expect(Wardrobe.purchaseProblem(for: cap, owned: [], availableStars: 5) == .notEnoughStars(missing: 15))
        #expect(Wardrobe.purchaseProblem(for: cap, owned: ["cap"], availableStars: 100) == .alreadyOwned)
    }

    /// Gekaufte Teile stehen mit ihrer ID im Spielstand; fehlt eine, wäre sie nach einem Update weg.
    @Test func shippedIDsStayAvailable() {
        let shipped = ["cap", "sunhat", "tophat", "crown", "glasses", "sunglasses", "bell", "bow", "scarf", "flower", "balloon", "yarn"]
        for id in shipped { #expect(Wardrobe.accessory(id: id) != nil, "\(id) fehlt") }
    }

    @Test func treats() {
        #expect(Set(Treats.catalog.map(\.id)).count == Treats.catalog.count)
        #expect(Treats.catalog.allSatisfy { $0.price > 0 })
    }
}

struct HerdTests {
    @Test func starterComesFirst() {
        #expect(Herd.order(of: ["a", "b", "c", "d"], starter: "c") == ["c", "a", "b", "d"])
    }

    @Test func twoAnimalsPerLevel() {
        #expect(Herd.unlockedCount(atLevel: 1, total: 21) == 1)
        #expect(Herd.unlockedCount(atLevel: 2, total: 21) == 3)
        #expect(Herd.unlockedCount(atLevel: 11, total: 21) == 21)
        #expect(Herd.unlockedCount(atLevel: 30, total: 21) == 21)
        #expect(Herd.unlockLevel(position: 0) == 1)
        #expect(Herd.unlockLevel(position: 1) == 2)
        #expect(Herd.unlockLevel(position: 2) == 2)
        #expect(Herd.unlockLevel(position: 20) == 11)
        // Beide Rechnungen passen zusammen.
        for position in 0..<21 {
            #expect(Herd.unlockedCount(atLevel: Herd.unlockLevel(position: position), total: 21) > position)
        }
    }
}

struct ExercisesTests {
    @Test func kindFollowsBox() {
        #expect(Exercises.kind(box: 1, promptIsEnglish: false, canSpeak: true, variant: 7) == .multipleChoice)
        #expect(Exercises.kind(box: 2, promptIsEnglish: false, canSpeak: true, variant: 1) == .listening)
        #expect(Exercises.kind(box: 4, promptIsEnglish: false, canSpeak: true, variant: 3) == .speaking)
        #expect(Exercises.kind(box: 4, promptIsEnglish: true, canSpeak: true, variant: 3) == .typing)
        #expect(Exercises.kind(box: 4, promptIsEnglish: false, canSpeak: false, variant: 3) == .typing)
    }

    @Test func choices() {
        var generator = SystemRandomNumberGenerator()
        let options = Exercises.choices(correct: "dog", pool: ["cat", "Dog", "bird", "horse", "cat"], using: &generator)
        #expect(options?.count == 4)
        #expect(options?.contains("dog") == true)
        #expect(Set(options?.map { $0.lowercased() } ?? []).count == 4)
        #expect(Exercises.choices(correct: "x", pool: ["a", "A", "b"], using: &generator) == nil)
    }
}
