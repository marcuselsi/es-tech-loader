import SwiftUI

@main
struct ESTechLoaderApp: App {
    // Use AppDelegate for URL handling + lifecycle bits
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No visible windows. The app is menu-bar only via LSUIElement.
        Settings {
            // If you ever want a Settings window, put a SwiftUI view here.
            EmptyView()
        }
    }
}
