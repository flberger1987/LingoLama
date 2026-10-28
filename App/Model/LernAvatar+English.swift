import Foundation

/// Englische Texte zu den Avataren; LernAvatar.swift kommt unverändert aus der Avatar-Erzeugung.
extension LernAvatar {
    var species: String { tierart == "Lama" ? "Llama" : "Alpaca" }

    var role: String {
        switch self {
        case .rocky: "The brave word adventurer"
        case .nougat: "The curious explorer"
        case .jeppediah: "The calm explainer"
        case .leyla: "The little question asker"
        case .whitney: "The happy word finder"
        case .silk: "The quiet listener"
        case .santana: "The focused thinker"
        case .kuno: "The patient practice partner"
        case .flavio: "The quick repeater"
        case .claire: "The careful reading friend"
        case .catwizzle: "The playful rhyme friend"
        case .diego: "The friendly cheerleader"
        case .dexter: "The clever puzzle solver"
        case .covergirl: "The keen reader"
        case .carry: "The loyal practice friend"
        case .thaios: "The proud star collector"
        case .nalima: "The cheerful learning friend"
        case .diandro: "The patient pronunciation helper"
        case .cloe: "The kind encourager"
        case .callisto: "The curious word collector"
        case .amber: "The calm story friend"
        case .mrRight: "The reliable learning buddy"
        }
    }
}
