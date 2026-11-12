import SwiftUI

struct SavedView: View {
    @Environment(AppStore.self) private var store
    @State private var selected: SavedAdvice?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(title: store.text("KEEP WHAT HELPS", "把有用的，留在身边"))
                    Text(store.text("Little things to keep", "值得收藏的小建议")).font(BambooTheme.display(32)).tracking(-0.6)
                    Text(store.text("Thoughtful advice, ready when you need it.", "需要时，再回来看看。"))
                        .font(.subheadline).foregroundStyle(BambooTheme.muted)
                }.padding(.top, 24)
                if store.data.saved.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bookmark").font(.system(size: 40, weight: .ultraLight))
                        Text(store.text("A good thought is worth keeping.", "好的想法，值得留下。"))
                            .font(BambooTheme.display(22)).multilineTextAlignment(.center)
                        Text(store.text("Tap Save beneath a reply to\nmake a little collection of your own.", "点击回复下的「收藏」，\n慢慢积累属于你家的育儿小锦囊。"))
                            .font(.subheadline).foregroundStyle(BambooTheme.muted).multilineTextAlignment(.center)
                    }.frame(maxWidth: .infinity).padding(.vertical, 96)
                }
                ForEach(store.data.saved) { item in
                    Button { selected = item } label: {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "bookmark.fill")
                                Spacer()
                                Text(item.savedAt, style: .date)
                            }.font(.caption).foregroundStyle(BambooTheme.muted)
                            Text(item.question).font(.system(.body, weight: .medium)).lineLimit(2)
                            Text(item.answer).font(.subheadline).foregroundStyle(BambooTheme.muted).lineLimit(3)
                        }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
                            .background(BambooTheme.card, in: RoundedRectangle(cornerRadius: 12))
                    }.buttonStyle(.plain)
                }
            }.padding(.horizontal, 24).padding(.bottom, 24).frame(maxWidth: 700).frame(maxWidth: .infinity)
        }.sheet(item: $selected) { item in
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text(item.question).font(BambooTheme.display(25))
                        Text(LocalizedStringKey(item.answer)).font(.body).lineSpacing(6).textSelection(.enabled)
                        ShareLink(item: item.answer) { Label(store.text("Share advice", "分享建议"), systemImage: "square.and.arrow.up") }
                        Button(store.text("Remove from saved", "取消收藏"), role: .destructive) {
                            store.data.saved.removeAll { $0.id == item.id }
                            store.persist()
                            selected = nil
                        }.padding(.top, 12)
                    }.padding(24)
                }.background(BambooTheme.canvas).navigationTitle(store.text("Saved advice", "收藏的建议"))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button(store.text("Done", "完成")) { selected = nil } } }
            }
        }
    }
}
