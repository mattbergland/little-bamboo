import SwiftUI

struct RootView: View {
    @Environment(AppStore.self) private var store
    @State private var tab = 0
    @State private var path: [UUID] = []
    @State private var showFamily = false
    @State private var draft = ""
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack(path: $path) {
            VStack(spacing: 0) {
                header
                Group {
                    switch tab {
                    case 1: conversations
                    case 2: SavedView()
                    default: home
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
                tabBar
            }
            .background(BambooTheme.canvas)
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: UUID.self) { id in ChatView(conversationID: id) }
            .sheet(isPresented: $showFamily) { FamilyView() }
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            BambooMark(size: 30)
            VStack(alignment: .leading, spacing: 1) {
                Text("小竹").font(.system(.title3, weight: .medium))
                Text("LITTLE BAMBOO").font(.system(size: 8, weight: .medium)).tracking(1.6)
            }.foregroundStyle(BambooTheme.ink)
            Spacer()
            Button {
                store.data.profile.chineseUI.toggle()
                store.persist()
            } label: {
                Text(store.isChinese ? "EN" : "中").font(.system(.subheadline, weight: .medium))
                    .frame(width: 44, height: 44)
            }.accessibilityLabel(store.isChinese ? "Switch to English" : "切换到中文")
            Button { showFamily = true } label: {
                Image(systemName: "person.crop.circle").font(.system(size: 25, weight: .ultraLight))
                    .frame(width: 44, height: 44).foregroundStyle(BambooTheme.ink)
            }.accessibilityLabel(store.text("Family and settings", "家庭与设置"))
        }.padding(.horizontal, 24).padding(.vertical, 8)
    }

    private var home: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 12) {
                    SectionLabel(title: store.text("A LITTLE SUPPORT, EVERY DAY", "每天，多一点支持"))
                    Text(store.text("Growing together,\none day at a time.", "陪孩子长大，\n也陪你。"))
                        .font(BambooTheme.display(34)).tracking(-0.8).foregroundStyle(BambooTheme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(store.text("For the little questions. And the big feelings.\nA thoughtful space for your family, in 中文 or English.", "育儿的小疑问，心里的大情绪。\n用熟悉的语言，一起慢慢聊。"))
                        .font(.subheadline).foregroundStyle(BambooTheme.muted).lineSpacing(4)
                }.padding(.top, 16)

                VStack(spacing: 0) {
                    TogetherIllustration()
                    HStack(alignment: .firstTextBaseline) {
                        Text(store.text("You don’t have to figure\nit all out alone.", "育儿这条路，\n你不必独自摸索。"))
                            .font(BambooTheme.display(21)).foregroundStyle(BambooTheme.ink)
                        Spacer(minLength: 8)
                        Text("慢慢来").font(.system(.caption)).foregroundStyle(BambooTheme.muted)
                    }.padding(20).padding(.top, -8)
                }.background(BambooTheme.card, in: RoundedRectangle(cornerRadius: BambooTheme.radius))

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text(store.text("What’s on your mind?", "今天，想聊点什么？")).font(.system(.title3, weight: .medium))
                        Spacer()
                    }
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(Topic.all) { topic in
                            Button { openChat(prompt: store.isChinese ? topic.chinesePrompt : topic.prompt) } label: {
                                VStack(alignment: .leading, spacing: 18) {
                                    Image(systemName: topic.symbol).font(.system(size: 23, weight: .light))
                                    VStack(alignment: .leading, spacing: 5) {
                                        Text(store.isChinese ? topic.chinese : topic.english).font(.system(.subheadline, weight: .medium))
                                        Text(store.isChinese ? topic.english : topic.chinese).font(.caption).foregroundStyle(BambooTheme.muted)
                                    }
                                }.frame(maxWidth: .infinity, minHeight: 95, alignment: .leading).padding(16)
                                    .background(BambooTheme.soft, in: RoundedRectangle(cornerRadius: 12))
                            }.buttonStyle(.plain).foregroundStyle(BambooTheme.ink)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 12) {
                    SectionLabel(title: store.text("A GENTLE REMINDER", "送给今天的你"))
                    Text(store.text("Connection before correction.", "先理解，再引导。"))
                        .font(BambooTheme.display(25)).foregroundStyle(BambooTheme.ink)
                    Text(store.text("You can hold a boundary and hold their hand. Both can be true.", "温柔和坚定，可以同时存在。设立界限时，也别忘了牵住孩子的手。"))
                        .font(.subheadline).lineSpacing(4).foregroundStyle(BambooTheme.muted)
                }.padding(.vertical, 4)
            }.padding(.horizontal, 24).padding(.bottom, 24).frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
        }.safeAreaInset(edge: .bottom, spacing: 0) {
            HStack(spacing: 12) {
                TextField(store.text("Ask Little Bamboo…", "和小竹说说…"), text: $draft)
                    .font(.body).submitLabel(.send).onSubmit { sendHome() }
                    .accessibilityIdentifier("homeComposer")
                Button(action: sendHome) {
                    Image(systemName: "arrow.up").font(.system(.body, weight: .medium))
                        .foregroundStyle(BambooTheme.onAction).frame(width: 44, height: 44)
                        .background(BambooTheme.action, in: Circle())
                }.accessibilityLabel(store.text("Start conversation", "开始对话"))
            }.padding(.leading, 18).padding(.trailing, 6).padding(.vertical, 6)
                .background(BambooTheme.canvas, in: RoundedRectangle(cornerRadius: 28))
                .overlay(RoundedRectangle(cornerRadius: 28).stroke(BambooTheme.line, lineWidth: 1))
                .padding(.horizontal, 24).padding(.vertical, 12).background(BambooTheme.canvas)
        }
    }

    private var conversations: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                SectionLabel(title: store.text("ROOM TO TALK", "慢慢说，我在听"))
                Text(store.text("Your conversations", "我们的对话")).font(BambooTheme.display(32)).tracking(-0.6)
                Text(store.text("Pick up where you left off.", "每一次倾诉，都值得被认真对待。"))
                    .font(.subheadline).foregroundStyle(BambooTheme.muted)
            }.padding(.horizontal, 24).padding(.top, 24)
            PrimaryButton(title: store.text("A new conversation", "开始新的对话"), symbol: "plus") { openChat() }
                .padding(.horizontal, 24)
            if store.conversations.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "bubble.left.and.bubble.right").font(.system(size: 40, weight: .ultraLight))
                    Text(store.text("A little space, just for you.", "这里，留一点空间给自己。"))
                        .font(BambooTheme.display(23))
                    Text(store.text("Ask a question, share a worry,\nor simply tell me about your day.", "问个问题，说说烦恼，\n或聊聊今天发生的事。"))
                        .font(.subheadline).multilineTextAlignment(.center).foregroundStyle(BambooTheme.muted)
                }.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(store.conversations) { conversation in
                        Button { path.append(conversation.id) } label: {
                            HStack(spacing: 14) {
                                Image(systemName: "bubble.left").font(.system(size: 22, weight: .light))
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(conversation.messages.isEmpty ? store.text("A little space to talk", "慢慢聊") : conversation.title)
                                        .font(.system(.body, weight: .medium)).lineLimit(2)
                                    Text(conversation.updatedAt, style: .date).font(.caption).foregroundStyle(BambooTheme.muted)
                                }
                                Spacer()
                                Image(systemName: "chevron.right").font(.caption)
                            }.padding(.vertical, 10).foregroundStyle(BambooTheme.ink)
                        }.listRowBackground(BambooTheme.canvas)
                            .swipeActions {
                                if store.sendingID != conversation.id {
                                    Button(store.text("Delete", "删除"), role: .destructive) { store.deleteConversation(conversation.id) }
                                }
                            }
                    }
                }.listStyle(.plain).scrollContentBackground(.hidden)
            }
        }.frame(maxWidth: 700).frame(maxWidth: .infinity)
    }

    private var tabBar: some View {
        HStack {
            tabButton(0, "sun.max", store.text("Today", "今天"))
            tabButton(1, "bubble.left.and.bubble.right", store.text("Conversations", "对话"))
            tabButton(2, "bookmark", store.text("Saved", "收藏"))
        }.padding(.top, 12).padding(.bottom, 4).background(BambooTheme.canvas)
            .overlay(alignment: .top) { Rectangle().fill(BambooTheme.line).frame(height: 0.5) }
    }

    private func tabButton(_ value: Int, _ symbol: String, _ title: String) -> some View {
        Button { tab = value } label: {
            VStack(spacing: 6) {
                Image(systemName: symbol + (tab == value ? ".fill" : "")).font(.system(size: 20, weight: .regular))
                Text(title).font(.system(.caption2, weight: tab == value ? .medium : .regular))
            }.frame(maxWidth: .infinity, minHeight: 44)
                .foregroundStyle(tab == value ? BambooTheme.action : BambooTheme.muted)
        }.buttonStyle(.plain).accessibilityAddTraits(tab == value ? .isSelected : [])
    }

    private func openChat(prompt: String? = nil) {
        let id = store.createConversation()
        path.append(id)
        if let prompt { Task { await store.send(prompt, to: id) } }
    }

    private func sendHome() {
        let prompt = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        draft = ""
        openChat(prompt: prompt.isEmpty ? nil : String(prompt.prefix(4000)))
    }
}
