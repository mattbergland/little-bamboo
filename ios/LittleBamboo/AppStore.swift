import Foundation
import Observation

@MainActor @Observable final class AppStore {
    typealias ReplyProvider = @MainActor ([ChatMessage], FamilyProfile, String, String) async throws -> String
    var data: AppData
    var sendingID: UUID?
    var errors: [UUID: String] = [:]
    var persistenceError: String?
    var endpoint: String {
        didSet { UserDefaults.standard.set(endpoint, forKey: "endpoint") }
    }
    private(set) var accessKey: String
    private let storageURL: URL
    private let replyProvider: ReplyProvider

    init(storageURL: URL? = nil, replyProvider: @escaping ReplyProvider = { messages, profile, endpoint, key in
        try await ChatService.reply(messages: messages, profile: profile, endpoint: endpoint, key: key)
    }) {
        self.replyProvider = replyProvider
        let directory = URL.applicationSupportDirectory.appendingPathComponent("LittleBamboo", isDirectory: true)
        self.storageURL = storageURL ?? directory.appendingPathComponent("family.json")
        if let bytes = try? Data(contentsOf: self.storageURL) {
            do { data = try JSONDecoder().decode(AppData.self, from: bytes) }
            catch {
                data = AppData()
                persistenceError = "Your saved data couldn’t be opened. It has not been overwritten."
            }
        } else { data = AppData() }
        endpoint = UserDefaults.standard.string(forKey: "endpoint") ?? ChatService.defaultEndpoint
        accessKey = Keychain.read()
        // Local development provisioning only. Nothing is embedded in the app bundle.
        if let key = ProcessInfo.processInfo.environment["LITTLE_BAMBOO_ACCESS_KEY"], !key.isEmpty {
            if Keychain.save(key) { accessKey = key }
        }
    }

    var isChinese: Bool { data.profile.chineseUI }
    func text(_ english: String, _ chinese: String) -> String { isChinese ? chinese : english }
    var conversations: [Conversation] { data.conversations.sorted { $0.updatedAt > $1.updatedAt } }
    func conversation(_ id: UUID) -> Conversation? { data.conversations.first { $0.id == id } }

    func persist() {
        // Preserve unreadable data until the user explicitly clears it.
        guard persistenceError == nil else { return }
        do {
            try FileManager.default.createDirectory(at: storageURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let bytes = try JSONEncoder().encode(data)
            try bytes.write(to: storageURL, options: [.atomic, .completeFileProtection])
        } catch { persistenceError = "Your changes couldn’t be saved on this device. Please free up space and reopen the app." }
    }

    func setAccessKey(_ key: String) -> Bool {
        let cleaned = key.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Keychain.save(cleaned) else { return false }
        accessKey = cleaned
        return true
    }

    @discardableResult func createConversation() -> UUID {
        let conversation = Conversation()
        data.conversations.append(conversation)
        persist()
        return conversation.id
    }

    func deleteConversation(_ id: UUID) {
        guard sendingID != id else { return }
        data.conversations.removeAll { $0.id == id }
        errors[id] = nil
        persist()
    }

    func send(_ text: String, to id: UUID) async {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty, cleaned.count <= 4000, sendingID == nil,
              let index = data.conversations.firstIndex(where: { $0.id == id }) else { return }
        // A failed user turn must be retried before another message is appended.
        guard data.conversations[index].messages.last?.role != "user" else { return }
        if data.conversations[index].messages.isEmpty { data.conversations[index].title = String(cleaned.prefix(60)) }
        data.conversations[index].messages.append(ChatMessage(role: "user", content: cleaned))
        data.conversations[index].updatedAt = Date()
        persist()
        await requestReply(for: id)
    }

    func retry(_ id: UUID) async {
        guard sendingID == nil, conversation(id)?.messages.last?.role == "user" else { return }
        await requestReply(for: id)
    }

    private func requestReply(for id: UUID) async {
        guard let conversation = conversation(id) else { return }
        sendingID = id
        errors[id] = nil
        defer { sendingID = nil }
        do {
            let reply = try await replyProvider(conversation.messages, data.profile, endpoint, accessKey)
            guard let index = data.conversations.firstIndex(where: { $0.id == id }) else { return }
            data.conversations[index].messages.append(ChatMessage(role: "assistant", content: reply))
            data.conversations[index].updatedAt = Date()
            persist()
        } catch { errors[id] = error.localizedDescription }
    }

    func toggleSaved(_ message: ChatMessage, in conversation: Conversation) {
        if data.saved.contains(where: { $0.id == message.id }) {
            data.saved.removeAll { $0.id == message.id }
        } else {
            let messageIndex = conversation.messages.firstIndex(where: { $0.id == message.id }) ?? 0
            let question = conversation.messages.prefix(messageIndex).last { $0.role == "user" }?.content ?? conversation.title
            data.saved.insert(.init(id: message.id, question: question, answer: message.content, savedAt: Date()), at: 0)
        }
        persist()
    }

    func clearData() {
        guard sendingID == nil else { return }
        data = AppData()
        persistenceError = nil
        persist()
    }
}
