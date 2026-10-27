import Foundation

public enum AnswerResult: String, Codable, Sendable {
    case correct, almost, wrong
}

/// Prüft Antworten lokal. Nur wenn das nicht eindeutig ist, fragt die App die KI.
public enum AnswerChecker {
    public enum Verdict: Equatable, Sendable {
        case correct
        case almost
        /// Lokal nicht entscheidbar, z. B. mögliches Synonym.
        case unsure
        case wrong
    }

    public static func check(answer: String, expected: String) -> Verdict {
        let given = normalize(answer)
        guard !given.isEmpty else { return .wrong }

        let options = alternatives(of: expected)
        if options.contains(given) { return .correct }

        let closest = options.map { distance(given, $0) }.min() ?? .max
        let longest = options.map(\.count).max() ?? 0
        if closest == 1 || (closest == 2 && longest >= 8) { return .almost }
        // Weit daneben: KI muss nicht gefragt werden.
        if closest > max(3, longest / 2) { return .wrong }
        return .unsure
    }

    /// "der Hund, die Hündin" → ["hund", "hündin"]; "to go (went)" → ["go"]
    static func alternatives(of expected: String) -> Set<String> {
        let withoutBrackets = expected.replacingOccurrences(of: #"\([^)]*\)"#, with: "", options: .regularExpression)
        let parts = withoutBrackets.split(whereSeparator: { ",;/".contains($0) })
        return Set(parts.map { normalize(String($0)) }.filter { !$0.isEmpty })
    }

    static let ignoredPrefixes = ["to ", "the ", "a ", "an ", "der ", "die ", "das ", "ein ", "eine "]

    static func normalize(_ text: String) -> String {
        var result = text
            .lowercased()
            .replacingOccurrences(of: "’", with: "'")
            .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters.subtracting(["'"])))
        result = result.split(separator: " ").joined(separator: " ")
        for prefix in ignoredPrefixes where result.hasPrefix(prefix) {
            result.removeFirst(prefix.count)
            break
        }
        return result
    }

    static func distance(_ a: String, _ b: String) -> Int {
        let a = Array(a), b = Array(b)
        if a.isEmpty { return b.count }
        if b.isEmpty { return a.count }
        var previous = Array(0...b.count)
        for i in 1...a.count {
            var current = [i] + Array(repeating: 0, count: b.count)
            for j in 1...b.count {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                current[j] = min(previous[j] + 1, current[j - 1] + 1, previous[j - 1] + cost)
            }
            previous = current
        }
        return previous[b.count]
    }
}
