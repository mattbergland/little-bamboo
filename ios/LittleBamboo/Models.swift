import Foundation

enum ReplyLanguage: String, Codable, CaseIterable, Identifiable {
    case auto, en, zh
    var id: String { rawValue }
    var title: String {
        switch self {
        case .auto: return "Match my message · 自动"
        case .en: return "English"
        case .zh: return "简体中文"
        }
    }
}

struct FamilyProfile: Codable, Equatable {
    var nickname = ""
    var ageMonths: Int? = nil
    var language: ReplyLanguage = .auto
    var chineseUI = false
    var context = ""
}

struct ChatMessage: Codable, Identifiable, Equatable {
    let id: UUID
    let role: String
    let content: String
    let createdAt: Date

    init(role: String, content: String) {
        id = UUID()
        self.role = role
        self.content = content
        createdAt = Date()
    }
}

struct Conversation: Codable, Identifiable {
    let id: UUID
    var title: String
    var messages: [ChatMessage]
    var updatedAt: Date

    init() {
        id = UUID()
        title = "A little space to talk"
        messages = []
        updatedAt = Date()
    }
}

struct SavedAdvice: Codable, Identifiable {
    let id: UUID
    let question: String
    let answer: String
    let savedAt: Date
}

struct AppData: Codable {
    var conversations: [Conversation] = []
    var saved: [SavedAdvice] = []
    var profile = FamilyProfile()
}

struct Topic: Identifiable {
    let id: String
    let symbol: String
    let english: String
    let chinese: String
    let prompt: String
    let chinesePrompt: String

    static let all: [Topic] = [
        .init(id: "feelings", symbol: "heart", english: "Big feelings", chinese: "接住小情绪",
              prompt: "How can I support my child through a tantrum without shaming them?",
              chinesePrompt: "孩子情绪崩溃时，我该怎样温柔又坚定地回应，不让孩子感到羞耻？"),
        .init(id: "language", symbol: "character.bubble", english: "Two languages", chinese: "双语慢慢来",
              prompt: "My child prefers English. How can we make speaking Chinese feel fun, not like homework?",
              chinesePrompt: "孩子更喜欢说英语，怎样让说中文变得有趣，而不是像做作业？"),
        .init(id: "family", symbol: "person.2", english: "Family harmony", chinese: "和家人一起带娃",
              prompt: "The grandparents and I have different parenting approaches. How can I set kind, clear boundaries?",
              chinesePrompt: "我和长辈的育儿观念不一样，怎样既尊重他们，又能温和地设立界限？"),
        .init(id: "rhythm", symbol: "moon.stars", english: "Daily rhythms", chinese: "日常小节奏",
              prompt: "Can you help us create a calmer bedtime routine? Ask me about my child's age first.",
              chinesePrompt: "能帮我们建立轻松一点的睡前习惯吗？请先了解孩子的年龄。")
    ]
}
