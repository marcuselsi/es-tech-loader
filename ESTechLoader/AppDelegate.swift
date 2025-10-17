import AppKit
import os

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var menuBarController: MenuBarController?
    private let logger = Logger(subsystem: "ca.elsipogtog.estechloader", category: "App")

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("ES Tech Loader launched")
        menuBarController = MenuBarController()
    }

    // Handle custom URL scheme: ESTech://<command>
    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            handle(url: url)
        }
    }

    private func handle(url: URL) {
        // Accept formats like ESTech://chrome or ESTech://open?target=chrome
        // 'host' is often the first component after scheme; path may also carry data.
        let scheme = url.scheme ?? ""
        let host = url.host?.lowercased() ?? ""
        let pathComponent = url.pathComponents.dropFirst().first?.lowercased() // skip leading '/'

        logger.info("Received URL: \(url.absoluteString, privacy: .public) (scheme: \(scheme), host: \(host), path: \(pathComponent ?? "nil"))")

        // Command resolution priority: host > first path component > query item "target"
        let command: String? = {
            if !host.isEmpty { return host }
            if let p = pathComponent, !p.isEmpty { return p }
            if let q = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?.first(where: { $0.name.lowercased() == "target" })?.value?.lowercased() {
                return q
            }
            return nil
        }()

        guard let cmd = command else {
            logger.error("No command found in URL")
            return
        }

        switch cmd {
        case "minecraft-edu":
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
            logger.error("Unknown command: \(cmd, privacy: .public)")
        }
    }
}
