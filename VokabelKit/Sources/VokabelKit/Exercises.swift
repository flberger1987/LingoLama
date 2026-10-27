import Foundation

/// Wie eine Karte abgefragt wird.
public enum ExerciseKind: String, Sendable {
    /// Antwort eintippen
    case typing
    /// Eine von vier Antworten wählen
    case multipleChoice
    /// Englisches Wort anhören und schreiben
    case listening
    /// Deutsches Wort sehen, englisch aussprechen
    case speaking
}

public enum Exercises {
    /// Neue Wörter kommen als Auswahl, halb gelernte gemischt, gut gelernte meist zum Eintippen, Hören oder Sprechen.
    /// `variant` sorgt für Abwechslung innerhalb einer Runde (z. B. die Position der Karte).
    public static func kind(box: Int, promptIsEnglish: Bool, canSpeak: Bool, variant: Int) -> ExerciseKind {
        switch box {
        case ...1:
            return .multipleChoice
        case 2:
            return [.multipleChoice, .listening, .typing][variant % 3]
        default:
            let kind: ExerciseKind = [.typing, .listening, .typing, .speaking][variant % 4]
            // Gesprochen wird nur Englisch, also nur bei deutschen Vorgaben.
            return kind == .speaking && (promptIsEnglish || !canSpeak) ? .typing : kind
        }
    }

    /// Die richtige Antwort plus Ablenker aus `pool`, gemischt. `nil`, wenn es nicht genug verschiedene Ablenker gibt.
    public static func choices<G: RandomNumberGenerator>(
        correct: String, pool: [String], count: Int = 4, using generator: inout G
    ) -> [String]? {
        var seen: Set<String> = [correct.lowercased()]
        var distractors: [String] = []
        for option in pool.shuffled(using: &generator) where seen.insert(option.lowercased()).inserted {
            distractors.append(option)
            if distractors.count == count - 1 { break }
        }
        guard distractors.count == count - 1 else { return nil }
        return (distractors + [correct]).shuffled(using: &generator)
    }
}
