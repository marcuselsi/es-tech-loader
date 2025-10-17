import AppKit
import os

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private let logger = Logger(subsystem: "ca.elsipogtog.estechloader", category: "App")

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("ES Tech Loader launched")
        // Create menu bar controller (builds initial menu)
        menuBarController = MenuBarController()
    }

    // Handle custom URL scheme: ESTech://<command>
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            handle(url: url)
        }
    }

    private func handle(url: URL) {
        // Accept ESTech://chrome, ESTech://minecraft, ESTech://open?target=chrome, etc.
        let scheme = url.scheme?.lowercased() ?? ""
        guard scheme == "estech" else {
            Logger(subsystem: "ca.elsipogtog.estechloader", category: "App")
                .error("Unexpected scheme: \(scheme, privacy: .public)")
            return
        }

        let host = url.host?.lowercased() ?? ""
        let firstPath = url.pathComponents.dropFirst().first?.lowercased()
        let queryTarget = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name.lowercased() == "target" })?.value?.lowercased()

        let command = [host, firstPath, queryTarget].compactMap { $0 }.first ?? ""
        Logger(subsystem: "ca.elsipogtog.estechloader", category: "App")
            .info("Received URL: \(url.absoluteString, privacy: .public) → command=\(command, privacy: .public)")

        // Route commands to the same launcher used by menu items
        switch command {
        case "minecraft":
            AppLauncher.openMinecraftEducation()
        case "chrome":
            AppLauncher.openChrome()
        case "safari":
            AppLauncher.openSafari()
        case "settings", "preferences":
            AppLauncher.openSystemSettings()
        case "finder":
            AppLauncher.openFinder()
        default:
            Logger(subsystem: "ca.elsipogtog.estechloader", category: "App")
                .error("Unknown command from URL: \(command, privacy: .public)")
        }
    }
}
