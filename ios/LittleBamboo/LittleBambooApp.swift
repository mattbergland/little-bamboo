import SwiftUI

@main struct LittleBambooApp: App {
    @State private var store = AppStore()
    var body: some Scene {
        WindowGroup {
            RootView().environment(store).tint(BambooTheme.action).preferredColorScheme(.light)
        }
    }
}
