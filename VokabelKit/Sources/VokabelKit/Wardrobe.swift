import Foundation

/// Wo der Lernbegleiter ein Accessoire trägt. Pro Platz ist immer nur eins angezogen.
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

/// Der Kleiderschrank: was es zu kaufen gibt und wann ein Kauf klappt.
/// Die IDs stehen in gespeicherten Spielständen und dürfen sich nie ändern.
public enum Wardrobe {
    public static let catalog: [Accessory] = [
        Accessory(id: "cap", name: "Cap", emoji: "🧢", slot: .head, price: 20),
        Accessory(id: "sunhat", name: "Sun hat", emoji: "👒", slot: .head, price: 40),
        Accessory(id: "tophat", name: "Top hat", emoji: "🎩", slot: .head, price: 60),
        Accessory(id: "crown", name: "Crown", emoji: "👑", slot: .head, price: 150),
        Accessory(id: "gradcap", name: "Grad cap", emoji: "🎓", slot: .head, price: 90),
        Accessory(id: "glasses", name: "Glasses", emoji: "👓", slot: .eyes, price: 25),
        Accessory(id: "sunglasses", name: "Sunglasses", emoji: "🕶️", slot: .eyes, price: 35),
        Accessory(id: "bell", name: "Bell", emoji: "🔔", slot: .neck, price: 15),
        Accessory(id: "bow", name: "Bow", emoji: "🎀", slot: .neck, price: 25),
        Accessory(id: "scarf", name: "Scarf", emoji: "🧣", slot: .neck, price: 40),
        Accessory(id: "flower", name: "Flower", emoji: "🌸", slot: .extra, price: 10),
        Accessory(id: "balloon", name: "Balloon", emoji: "🎈", slot: .extra, price: 30),
        Accessory(id: "yarn", name: "Ball of yarn", emoji: "🧶", slot: .extra, price: 50),
        Accessory(id: "sunflower", name: "Sunflower", emoji: "🌻", slot: .extra, price: 20),
        Accessory(id: "butterfly", name: "Butterfly", emoji: "🦋", slot: .extra, price: 45),
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

/// Ein Leckerli wird nicht behalten, sondern sofort verfüttert.
public struct Treat: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let emoji: String
    public let price: Int
}

public enum Treats {
    /// Was Alpakas und Lamas wirklich mögen.
    public static let catalog: [Treat] = [
        Treat(id: "hay", name: "Hay", emoji: "🌾", price: 2),
        Treat(id: "carrot", name: "Carrot", emoji: "🥕", price: 4),
        Treat(id: "apple", name: "Apple", emoji: "🍎", price: 6),
        Treat(id: "melon", name: "Melon", emoji: "🍉", price: 10),
    ]
}
