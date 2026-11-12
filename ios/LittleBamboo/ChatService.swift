import Foundation
import Security

enum Keychain {
    private static let service = "land.mattberg.littlebamboo"
    static func read() -> String {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service, kSecAttrAccount as String: "access-key",
            kSecReturnData as String: true, kSecMatchLimit as String: kSecMatchLimitOne]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }

    @discardableResult static func save(_ value: String) -> Bool {
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service, kSecAttrAccount as String: "access-key"]
        if value.isEmpty {
            let status = SecItemDelete(query as CFDictionary)
            return status == errSecSuccess || status == errSecItemNotFound
        }
        let data = Data(value.utf8)
        let status = SecItemUpdate(query as CFDictionary, [kSecValueData as String: data] as CFDictionary)
        if status == errSecSuccess { return true }
        guard status == errSecItemNotFound else { return false }
        var item = query
        item[kSecValueData as String] = data
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        return SecItemAdd(item as CFDictionary, nil) == errSecSuccess
    }
}

enum ChatError: LocalizedError {
    case setup, invalidURL, server(String), empty
    var errorDescription: String? {
        switch self {
        case .setup: return "Add your private access key in Family → AI connection to start chatting."
        case .invalidURL: return "Use a valid HTTPS server address in AI connection."
        case .server(let text): return text
        case .empty: return "Little Bamboo couldn’t finish that reply. Please try again."
        }
    }
}

struct ChatService {
    static let defaultEndpoint = "https://little-bamboo.vercel.app"

    static func reply(messages: [ChatMessage], profile: FamilyProfile, endpoint: String, key: String) async throws -> String {
        guard !key.isEmpty else { throw ChatError.setup }
        guard let base = URL(string: endpoint), base.scheme == "https", base.host != nil else {
            throw ChatError.invalidURL
        }
        struct RequestBody: Encodable {
            struct Message: Encodable { let role: String; let content: String }
            let messages: [Message]
            let profile: FamilyProfile
        }
        var request = URLRequest(url: base.appendingPathComponent("api/chat"))
        request.httpMethod = "POST"
        request.timeoutInterval = 65
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        // Keep the most recent context, beginning with a user turn.
        var context = Array(messages.suffix(20))
        if context.first?.role == "assistant" { context.removeFirst() }
        request.httpBody = try JSONEncoder().encode(RequestBody(
            messages: context.map { .init(role: $0.role, content: $0.content) }, profile: profile))
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ChatError.empty }
        struct Reply: Decodable { let reply: String?; let error: String? }
        let body = try? JSONDecoder().decode(Reply.self, from: data)
        guard http.statusCode == 200 else {
            if http.statusCode == 401 { throw ChatError.setup }
            throw ChatError.server(body?.error ?? "The connection isn’t available right now. Please try again.")
        }
        guard let text = body?.reply, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ChatError.empty
        }
        return text
    }
}
