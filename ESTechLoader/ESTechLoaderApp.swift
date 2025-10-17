import SwiftUI

@main
struct ESTechLoaderApp: App {
    // AppDelegate handles lifecycle & custom URL scheme
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No windows; background-only via LSUIElement in Info.plist
        Settings {
            EmptyView()
        }
    }
}
