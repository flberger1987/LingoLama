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
}

struct HerdTests {
    @Test func oneAnimalPerLevelFromTwo() {
        #expect(Herd.animals.map(\.unlockLevel) == Array(2...(Herd.animals.count + 1)))
        #expect(Set(Herd.animals.map(\.id)).count == Herd.animals.count)
    }

    @Test func unlocking() {
        #expect(Herd.unlocked(atLevel: 1).isEmpty)
        #expect(Herd.unlocked(atLevel: 4).map(\.id) == ["frog", "macaw", "bear"])
        #expect(Herd.newlyUnlocked(from: 3, to: 4).map(\.id) == ["bear"])
        #expect(Herd.newlyUnlocked(from: 2, to: 4).count == 2)
        #expect(Herd.newlyUnlocked(from: 4, to: 4).isEmpty)
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
