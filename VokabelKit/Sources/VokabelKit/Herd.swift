import Foundation

/// Ein Tier aus Lingos Herde, freigeschaltet beim Erreichen eines Levels.
public struct Animal: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let englishName: String
    public let emoji: String
    public let unlockLevel: Int
    /// Auf Englisch, damit auch die Belohnung ein bisschen Englisch ist.
    public let funFact: String
}

/// Lingos Herde: Tiere aus Südamerika, eins pro Level ab Level 2.
public enum Herd {
    public static let animals: [Animal] = [
        Animal(id: "frog", name: "Titicaca-Frosch", englishName: "frog", emoji: "🐸", unlockLevel: 2,
               funFact: "The Titicaca water frog lives in a lake high up in the Andes. It breathes through its baggy skin!"),
        Animal(id: "macaw", name: "Ara", englishName: "macaw", emoji: "🦜", unlockLevel: 3,
               funFact: "Macaws are big, colourful parrots. Some of them live for more than 50 years."),
        Animal(id: "bear", name: "Brillenbär", englishName: "spectacled bear", emoji: "🐻", unlockLevel: 4,
               funFact: "The spectacled bear is the only bear in South America. Paddington Bear comes from Peru, too!"),
        Animal(id: "flamingo", name: "Anden-Flamingo", englishName: "flamingo", emoji: "🦩", unlockLevel: 5,
               funFact: "Andean flamingos live at salty lakes in the mountains. They are pink because of the food they eat."),
        Animal(id: "sloth", name: "Faultier", englishName: "sloth", emoji: "🦥", unlockLevel: 6,
               funFact: "Sloths move so slowly that tiny green algae grow in their fur."),
        Animal(id: "penguin", name: "Humboldt-Pinguin", englishName: "penguin", emoji: "🐧", unlockLevel: 7,
               funFact: "Humboldt penguins live on the beaches of Peru and Chile. There is no ice there at all!"),
        Animal(id: "condor", name: "Andenkondor", englishName: "condor", emoji: "🦅", unlockLevel: 8,
               funFact: "The Andean condor is one of the biggest flying birds in the world. Its wings are about three metres wide."),
        Animal(id: "dolphin", name: "Amazonas-Delfin", englishName: "river dolphin", emoji: "🐬", unlockLevel: 9,
               funFact: "Amazon river dolphins live in rivers, not in the sea. Many of them are pink!"),
        Animal(id: "butterfly", name: "Morphofalter", englishName: "butterfly", emoji: "🦋", unlockLevel: 10,
               funFact: "The blue morpho butterfly shines bright blue, but its wings have no blue colour in them. It is a trick of the light!"),
        Animal(id: "tortoise", name: "Riesenschildkröte", englishName: "giant tortoise", emoji: "🐢", unlockLevel: 11,
               funFact: "Giant tortoises on the Galápagos Islands can live for more than 100 years."),
    ]

    public static func unlocked(atLevel level: Int) -> [Animal] {
        animals.filter { $0.unlockLevel <= level }
    }

    /// Tiere, die beim Aufstieg von `oldLevel` auf `newLevel` dazukommen.
    public static func newlyUnlocked(from oldLevel: Int, to newLevel: Int) -> [Animal] {
        animals.filter { $0.unlockLevel > oldLevel && $0.unlockLevel <= newLevel }
    }
}
