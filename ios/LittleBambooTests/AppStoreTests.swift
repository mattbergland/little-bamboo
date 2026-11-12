import XCTest
@testable import LittleBamboo

@MainActor final class AppStoreTests: XCTestCase {
    private var directory: URL!
    private var file: URL { directory.appendingPathComponent("family.json") }

    override func setUp() async throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    }

    override func tearDown() async throws {
        if FileManager.default.fileExists(atPath: directory.path) { try FileManager.default.removeItem(at: directory) }
    }

    func testBilingualHistoryProfileAndSavedAdviceSurviveRelaunch() async {
        let store = AppStore(storageURL: file, replyProvider: { _, _, _, _ in "先接住孩子的情绪，再温柔地设立界限。" })
        store.data.profile.nickname = "小宝"
        store.data.profile.language = .zh
        let id = store.createConversation()
        await store.send("孩子发脾气时怎么办？", to: id)
        let conversation = store.conversation(id)!
        XCTAssertEqual(conversation.messages.count, 2)
        store.toggleSaved(conversation.messages.last!, in: conversation)
        let restored = AppStore(storageURL: file)
        XCTAssertEqual(restored.data.profile.nickname, "小宝")
        XCTAssertEqual(restored.data.profile.language, .zh)
        XCTAssertEqual(restored.conversation(id)?.messages.last?.content, "先接住孩子的情绪，再温柔地设立界限。")
        XCTAssertEqual(restored.data.saved.first?.question, "孩子发脾气时怎么办？")
        restored.deleteConversation(id)
        XCTAssertEqual(restored.data.saved.count, 1, "Saved advice should remain after deleting its conversation")
    }

    func testRetryDoesNotDuplicateTheFailedUserTurn() async {
        var attempts = 0
        let store = AppStore(storageURL: file, replyProvider: { _, _, _, _ in
            attempts += 1
            if attempts == 1 { throw ChatError.server("Offline") }
            return "Let’s make a calmer plan together."
        })
        let id = store.createConversation()
        await store.send("Bedtime has been difficult.", to: id)
        XCTAssertEqual(store.conversation(id)?.messages.count, 1)
        XCTAssertEqual(store.errors[id], "Offline")
        XCTAssertNil(store.sendingID)
        await store.send("Do not duplicate a failed turn", to: id)
        XCTAssertEqual(store.conversation(id)?.messages.count, 1)
        await store.retry(id)
        XCTAssertEqual(store.conversation(id)?.messages.map(\.role), ["user", "assistant"])
        XCTAssertNil(store.errors[id])
    }

    func testSavedAdviceCanBeToggledAndAllFamilyDataCleared() async {
        let store = AppStore(storageURL: file, replyProvider: { _, _, _, _ in "Try a story together." })
        let id = store.createConversation()
        await store.send("Help us enjoy Chinese", to: id)
        let conversation = store.conversation(id)!
        let answer = conversation.messages.last!
        store.toggleSaved(answer, in: conversation)
        XCTAssertEqual(store.data.saved.count, 1)
        store.toggleSaved(answer, in: conversation)
        XCTAssertTrue(store.data.saved.isEmpty)
        store.clearData()
        let restored = AppStore(storageURL: file)
        XCTAssertTrue(restored.conversations.isEmpty)
        XCTAssertEqual(restored.data.profile, FamilyProfile())
    }

    func testUnreadableStorageIsPreservedUntilExplicitDeletion() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let original = Data("unreadable content".utf8)
        try original.write(to: file)
        let store = AppStore(storageURL: file)
        XCTAssertNotNil(store.persistenceError)
        store.createConversation()
        XCTAssertEqual(try Data(contentsOf: file), original)
        store.clearData()
        XCTAssertNil(store.persistenceError)
        XCTAssertNoThrow(try JSONDecoder().decode(AppData.self, from: Data(contentsOf: file)))
    }
}
