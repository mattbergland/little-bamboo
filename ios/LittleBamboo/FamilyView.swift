import SwiftUI

struct FamilyView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var profile = FamilyProfile()
    @State private var endpoint = ""
    @State private var key = ""
    @State private var age = ""
    @State private var confirmDelete = false
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        BambooMark(size: 40)
                        Text(store.text("Every family is\nits own little world.", "每一个家，\n都有自己的节奏。"))
                            .font(BambooTheme.display(29)).tracking(-0.5)
                        Text(store.text("Share only what feels comfortable. These details help Little Bamboo tailor its replies.", "只填写你愿意分享的内容，让小竹更懂你家的情况。"))
                            .font(.subheadline).foregroundStyle(BambooTheme.muted)
                    }.padding(.vertical, 8)
                }.listRowBackground(BambooTheme.canvas)

                Section(store.text("Your family · optional", "家庭信息 · 选填")) {
                    TextField(store.text("Child’s nickname", "孩子的小名"), text: $profile.nickname)
                        .onChange(of: profile.nickname) { _, value in profile.nickname = String(value.prefix(60)) }
                    HStack {
                        Text(store.text("Age in months", "月龄"))
                        Spacer()
                        TextField(store.text("Optional", "选填"), text: $age).keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing).frame(width: 100)
                    }
                    TextField(store.text("Anything helpful to know?", "还有什么想让小竹了解的吗？"), text: $profile.context, axis: .vertical)
                        .lineLimit(2...4).onChange(of: profile.context) { _, value in profile.context = String(value.prefix(500)) }
                }.listRowBackground(BambooTheme.soft)

                Section(store.text("Language", "语言")) {
                    Toggle("中文界面", isOn: $profile.chineseUI)
                    Picker(store.text("Reply language", "回复语言"), selection: $profile.language) {
                        ForEach(ReplyLanguage.allCases) { language in Text(language.title).tag(language) }
                    }
                }.listRowBackground(BambooTheme.soft)

                Section {
                    TextField(store.text("Server address", "服务器地址"), text: $endpoint)
                        .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                    SecureField(store.text("Private access key", "私人访问密钥"), text: $key)
                        .textInputAutocapitalization(.never).autocorrectionDisabled()
                        .accessibilityIdentifier("accessKeyField")
                    Label(store.accessKey.isEmpty ? store.text("Access key needed", "请添加访问密钥") : store.text("Access key saved on this device", "密钥已保存在此设备"),
                          systemImage: store.accessKey.isEmpty ? "key" : "lock.shield")
                        .font(.caption).foregroundStyle(BambooTheme.muted)
                } header: { Text(store.text("AI connection", "AI 连接")) }
                footer: { Text(store.text("For this private prototype, use the app access key from your server owner. Your AI provider key stays on the server.", "此私人原型需要服务器提供的应用访问密钥。AI 服务商密钥仅保留在服务器上。")) }
                    .listRowBackground(BambooTheme.soft)

                Section(store.text("Your privacy", "隐私与数据")) {
                    Text(store.text("Chats, saved replies, and family details are stored on this device. When you send a message, recent chat history and your family details go through our server to Anthropic to generate a reply. The app does not sync between devices.", "对话、收藏和家庭信息保存在此设备上。发送消息时，最近的对话记录和家庭信息会通过服务器发送给 Anthropic，以生成回复。目前不支持跨设备同步。"))
                        .font(.footnote).foregroundStyle(BambooTheme.muted)
                    Text(store.text("Little Bamboo offers general parenting support. It cannot diagnose, prescribe, or replace professional care.", "小竹提供一般育儿支持，不能诊断、开药或代替专业照护。"))
                        .font(.footnote).foregroundStyle(BambooTheme.muted)
                    if let persistenceError = store.persistenceError { Text(persistenceError).font(.footnote).foregroundStyle(BambooTheme.error) }
                    Button(store.text("Delete all chats and family data", "删除全部对话和家庭数据"), role: .destructive) { confirmDelete = true }
                        .disabled(store.sendingID != nil)
                }.listRowBackground(BambooTheme.soft)
                if let error { Section { Text(error).foregroundStyle(BambooTheme.error) } }
            }.scrollContentBackground(.hidden).background(BambooTheme.canvas)
                .navigationTitle(store.text("Your family", "你的家庭")).navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button(store.text("Cancel", "取消")) { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) { Button(store.text("Save", "保存"), action: save).fontWeight(.medium) }
                }
                .onAppear {
                    profile = store.data.profile
                    endpoint = store.endpoint
                    key = store.accessKey
                    age = profile.ageMonths.map(String.init) ?? ""
                }
                .confirmationDialog(store.text("Delete all local family data? This cannot be undone.", "删除此设备上的全部家庭数据？此操作无法撤销。"), isPresented: $confirmDelete, titleVisibility: .visible) {
                    Button(store.text("Delete all data", "删除全部数据"), role: .destructive) { store.clearData(); dismiss() }
                }
        }
    }

    private func save() {
        let cleanedAge = age.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanedAge.isEmpty {
            guard let months = Int(cleanedAge), (0...216).contains(months) else {
                error = store.text("Enter an age from 0 to 216 months, or leave it blank.", "月龄请填写 0 至 216 的整数，也可以留空。")
                return
            }
            profile.ageMonths = months
        } else { profile.ageMonths = nil }
        let cleanedEndpoint = endpoint.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: cleanedEndpoint), url.scheme == "https", url.host != nil,
              url.user == nil, url.password == nil, url.query == nil, url.fragment == nil,
              url.path.isEmpty || url.path == "/" else {
            error = store.text("Enter an HTTPS server origin, such as https://little-bamboo.vercel.app.", "请输入 HTTPS 服务器地址，例如 https://little-bamboo.vercel.app。")
            return
        }
        guard store.setAccessKey(key) else {
            error = store.text("The access key couldn’t be saved securely. Please try again.", "无法安全保存密钥，请重试。")
            return
        }
        store.endpoint = cleanedEndpoint
        store.data.profile = profile
        store.persist()
        dismiss()
    }
}
