import SwiftUI

struct ChatView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let conversationID: UUID
    @State private var draft = ""
    @State private var showFamily = false
    @FocusState private var composing: Bool

    private var conversation: Conversation? { store.conversation(conversationID) }
    private var pending: Bool { store.sendingID == conversationID }
    private var needsRetry: Bool { conversation?.messages.last?.role == "user" && !pending }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left").frame(width: 44, height: 44)
                }.accessibilityLabel(store.text("Back", "返回"))
                BambooMark(size: 32)
                VStack(alignment: .leading, spacing: 3) {
                    Text(store.text("Little Bamboo", "小竹")).font(.system(.body, weight: .medium))
                    Text(store.text("Here to listen. Here to help.", "认真听你说，陪你一起想。"))
                        .font(.caption).foregroundStyle(BambooTheme.muted)
                }
                Spacer()
                Button { showFamily = true } label: {
                    Image(systemName: "slider.horizontal.3").frame(width: 44, height: 44)
                }.accessibilityLabel(store.text("Family and AI connection", "家庭与 AI 连接"))
            }.padding(.trailing, 16).foregroundStyle(BambooTheme.ink)
            Rectangle().fill(BambooTheme.line).frame(height: 0.5)
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 24) {
                        if conversation?.messages.isEmpty != false { welcome }
                        ForEach(conversation?.messages ?? []) { message in
                            messageView(message)
                        }
                        if pending {
                            HStack(spacing: 10) {
                                ProgressView().tint(BambooTheme.action)
                                Text(store.text("Thinking with care…", "认真想一想…")).font(.subheadline).foregroundStyle(BambooTheme.muted)
                            }.padding(.vertical, 8).accessibilityIdentifier("thinkingIndicator")
                        }
                        if needsRetry {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(store.errors[conversationID] ?? store.text("That reply was interrupted. You can try again.", "刚才的回复中断了，可以再试一次。"))
                                    .font(.subheadline).foregroundStyle(BambooTheme.body)
                                HStack(spacing: 24) {
                                    Button(store.text("Try again", "重试")) { Task { await store.retry(conversationID) } }
                                    Button(store.text("AI connection", "AI 连接")) { showFamily = true }
                                }.font(.system(.subheadline, weight: .medium))
                            }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                                .background(BambooTheme.card, in: RoundedRectangle(cornerRadius: 12))
                        }
                        Color.clear.frame(height: 1).id("bottom")
                    }.padding(24).frame(maxWidth: 700).frame(maxWidth: .infinity)
                }.scrollDismissesKeyboard(.interactively)
                    .onChange(of: conversation?.messages.count) { _, _ in proxy.scrollTo("bottom", anchor: .bottom) }
                    .onChange(of: pending) { _, _ in proxy.scrollTo("bottom", anchor: .bottom) }
                    .onAppear { proxy.scrollTo("bottom", anchor: .bottom) }
            }
        }.background(BambooTheme.canvas)
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .bottom, spacing: 0) { composer }
            .sheet(isPresented: $showFamily) { FamilyView() }
    }

    private var welcome: some View {
        VStack(alignment: .leading, spacing: 20) {
            TogetherIllustration()
            Text(store.text("Let’s take it\none question at a time.", "一个问题，\n我们慢慢来。"))
                .font(BambooTheme.display(30)).tracking(-0.6)
            Text(store.text("Tell me what’s happening in your family. There’s no perfect way to begin.", "说说你家的近况吧。不必组织好语言，想到什么就说什么。"))
                .font(.body).foregroundStyle(BambooTheme.muted).lineSpacing(4)
        }.padding(.bottom, 24)
    }

    @ViewBuilder private func messageView(_ message: ChatMessage) -> some View {
        if message.role == "user" {
            HStack {
                Spacer(minLength: 32)
                Text(message.content).font(.body).lineSpacing(4).textSelection(.enabled)
                    .padding(16).background(BambooTheme.card, in: RoundedRectangle(cornerRadius: 16))
            }
        } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 5) {
                    BambooMark(size: 22)
                    SectionLabel(title: store.text("LITTLE BAMBOO", "小竹"))
                }
                Text(LocalizedStringKey(message.content)).font(.body).lineSpacing(6).textSelection(.enabled)
                    .foregroundStyle(BambooTheme.body).frame(maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 20) {
                    if let conversation {
                        let saved = store.data.saved.contains { $0.id == message.id }
                        Button { store.toggleSaved(message, in: conversation) } label: {
                            Label(store.text(saved ? "Saved" : "Save", saved ? "已收藏" : "收藏"), systemImage: saved ? "bookmark.fill" : "bookmark")
                        }.accessibilityIdentifier("saveReply")
                    }
                    ShareLink(item: message.content) { Label(store.text("Share", "分享"), systemImage: "square.and.arrow.up") }
                }.font(.caption).foregroundStyle(BambooTheme.muted).buttonStyle(.borderless)
                    .frame(minHeight: 44)
                    .padding(.vertical, 8)
            }
        }
    }

    private var composer: some View {
        VStack(spacing: 8) {
            if store.sendingID != nil && !pending {
                Text(store.text("Finishing your other reply. Your draft can wait here.", "正在完成另一条回复，你可以先在这里写下想说的话。"))
                    .font(.caption).foregroundStyle(BambooTheme.muted)
            }
            HStack(alignment: .bottom, spacing: 8) {
                TextField(store.text("What’s on your mind?", "想聊点什么？"), text: $draft, axis: .vertical)
                    .lineLimit(1...5).padding(.vertical, 12).padding(.leading, 16)
                    .focused($composing).accessibilityIdentifier("chatComposer")
                    .onChange(of: draft) { _, value in if value.count > 4000 { draft = String(value.prefix(4000)) } }
                Button(action: send) {
                    Image(systemName: "arrow.up").font(.system(.body, weight: .medium))
                        .frame(width: 44, height: 44).foregroundStyle(BambooTheme.onAction)
                        .background(canSend ? BambooTheme.action : BambooTheme.muted, in: Circle())
                }.disabled(!canSend).accessibilityLabel(store.text("Send message", "发送消息"))
                    .padding(5)
            }.background(BambooTheme.soft, in: RoundedRectangle(cornerRadius: 24))
                .overlay(RoundedRectangle(cornerRadius: 24).stroke(BambooTheme.line, lineWidth: 1))
            Text(store.text("AI support · For medical concerns, speak with a clinician.", "AI 育儿支持 · 健康问题请咨询医生。"))
                .font(.caption2).foregroundStyle(BambooTheme.muted).multilineTextAlignment(.center)
        }.padding(.horizontal, 20).padding(.top, 12).padding(.bottom, 8).background(BambooTheme.canvas)
    }

    private var canSend: Bool {
        !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && store.sendingID == nil && !needsRetry
    }

    private func send() {
        guard canSend else { return }
        let value = draft
        draft = ""
        composing = false
        Task { await store.send(value, to: conversationID) }
    }
}
