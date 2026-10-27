import Foundation

/// Die Herde: zuerst der selbst gewählte Startbegleiter, danach kommen pro Level-Aufstieg zwei Tiere dazu.
public enum Herd {
    public static let animalsPerLevel = 2

    /// Startbegleiter vorn, alle anderen in ihrer festen Reihenfolge dahinter.
    public static func order<Animal: Equatable>(of all: [Animal], starter: Animal) -> [Animal] {
        [starter] + all.filter { $0 != starter }
    }

    /// Wie viele Tiere der Reihenfolge auf diesem Level schon in der Herde sind.
    public static func unlockedCount(atLevel level: Int, total: Int) -> Int {
        min(total, 1 + animalsPerLevel * max(0, level - 1))
    }

    /// Ab welchem Level das Tier an dieser Stelle der Reihenfolge dazukommt.
    public static func unlockLevel(position: Int) -> Int {
        position == 0 ? 1 : 2 + (position - 1) / animalsPerLevel
    }
}
