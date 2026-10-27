import Foundation
import VokabelKit

/// Spricht mit dem eigenen Cloudflare-Proxy. Der Anthropic-Schlüssel liegt nur dort.
struct ProxyClient {
    struct Suggestion: Decodable, Identifiable, Hashable {
        let input: String
        var english: String
        var german: String
        var example: String
        let corrected: Bool
        let note: String
        var id: String { input }
    }

    struct Check: Decodable {
        let verdict: AnswerResult
        let feedback: String
    }

    private struct ErrorBody: Decodable { let error: String }

    enum ProxyError: LocalizedError {
        case notConfigured
        case server(String)

        var errorDescription: String? {
            switch self {
            case .notConfigured: "Die KI ist noch nicht eingerichtet."
            case .server(let message): message
            }
        }
    }

    static let shared = ProxyClient(
        host: Bundle.main.object(forInfoDictionaryKey: "ProxyHost") as? String ?? "",
        token: Bundle.main.object(forInfoDictionaryKey: "AppToken") as? String ?? ""
    )

    let host: String
    let token: String

    var isConfigured: Bool { !token.isEmpty && !host.isEmpty && !host.contains("DEIN-NAME") }

    func enrich(_ words: [String]) async throws -> [Suggestion] {
        struct Response: Decodable { let words: [Suggestion] }
        let response: Response = try await post("enrich", body: ["words": words])
        return response.words
    }

    func check(prompt: String, expected: String, answer: String, direction: Direction) async throws -> Check {
        try await post("check", body: [
            "prompt": prompt,
            "expected": expected,
            "answer": answer,
            "direction": direction == .deToEn ? "de-en" : "en-de",
        ])
    }

    private func post<T: Decodable>(_ path: String, body: [String: Any]) async throws -> T {
        guard isConfigured, let url = URL(string: "https://\(host)/\(path)") else { throw ProxyError.notConfigured }
        var request = URLRequest(url: url, timeoutInterval: 45)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.setValue(token, forHTTPHeaderField: "x-app-token")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            let message = (try? JSONDecoder().decode(ErrorBody.self, from: data))?.error
            throw ProxyError.server(message ?? "Die KI ist gerade nicht erreichbar (\(status)).")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}
