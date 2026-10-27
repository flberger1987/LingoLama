import Foundation

/// Wo Lingo ein Accessoire trägt. Pro Platz ist immer nur eins angezogen.
public enum Slot: String, CaseIterable, Sendable {
    case head, eyes, neck, extra
}

public struct Accessory: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let emoji: String
    public let slot: Slot
    public let price: Int
}

/// Lingos Kleiderschrank: was es zu kaufen gibt und wann ein Kauf klappt.
public enum Wardrobe {
    public static let catalog: [Accessory] = [
        Accessory(id: "cap", name: "Kappe", emoji: "🧢", slot: .head, price: 20),
        Accessory(id: "sunhat", name: "Sonnenhut", emoji: "👒", slot: .head, price: 40),
        Accessory(id: "tophat", name: "Zylinder", emoji: "🎩", slot: .head, price: 60),
        Accessory(id: "crown", name: "Krone", emoji: "👑", slot: .head, price: 150),
        Accessory(id: "glasses", name: "Brille", emoji: "👓", slot: .eyes, price: 25),
        Accessory(id: "sunglasses", name: "Sonnenbrille", emoji: "🕶️", slot: .eyes, price: 35),
        Accessory(id: "bell", name: "Glöckchen", emoji: "🔔", slot: .neck, price: 15),
        Accessory(id: "bow", name: "Schleife", emoji: "🎀", slot: .neck, price: 25),
        Accessory(id: "scarf", name: "Schal", emoji: "🧣", slot: .neck, price: 40),
        Accessory(id: "flower", name: "Blume", emoji: "🌸", slot: .extra, price: 10),
        Accessory(id: "balloon", name: "Luftballon", emoji: "🎈", slot: .extra, price: 30),
        Accessory(id: "yarn", name: "Wollknäuel", emoji: "🧶", slot: .extra, price: 50),
    ]

    public static func accessory(id: String) -> Accessory? {
        catalog.first { $0.id == id }
    }

    public enum PurchaseProblem: Equatable, Sendable {
        case alreadyOwned
        case notEnoughStars(missing: Int)
    }

    /// `nil`, wenn der Kauf klappt.
    public static func purchaseProblem(for item: Accessory, owned: Set<String>, availableStars: Int) -> PurchaseProblem? {
        if owned.contains(item.id) { return .alreadyOwned }
        if availableStars < item.price { return .notEnoughStars(missing: item.price - availableStars) }
        return nil
    }
}
