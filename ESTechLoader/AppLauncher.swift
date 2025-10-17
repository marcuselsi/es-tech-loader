import AppKit
import os

/// Centralized app-launch logic (bundle IDs + fallback paths + logging)
enum AppLauncher {
    private static let logger = Logger(subsystem: "ca.elsipogtog.estechloader", category: "Launch")

    /// Public method used by dynamic menu items (and URL scheme handler)
    static func openApp(bundleIds: [String], fallbackPaths: [String] = []) {
        let ws = NSWorkspace.shared

        // Try bundle identifiers first
        for bid in bundleIds {
            if let appURL = ws.urlForApplication(withBundleIdentifier: bid) {
                logger.info("Launching via bundle id \(bid, privacy: .public) at \(appURL.path, privacy: .public)")
                ws.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: { _,_  in })
                return
            } else {
                logger.debug("Bundle id not found: \(bid, privacy: .public)")
            }
        }

        // Try known paths next
        for path in fallbackPaths {
            let url = URL(fileURLWithPath: path)
            if FileManager.default.fileExists(atPath: url.path) {
                logger.info("Launching via path \(url.path, privacy: .public)")
                ws.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: { _,_  in })
                return
            } else {
                logger.debug("Path not found: \(url.path, privacy: .public)")
            }
        }

        logger.error("Failed to locate app via provided bundle ids and paths")
    }

    // Convenience wrappers for your standard items

    static func openMinecraftEducation() {
        // Your confirmed bundle id first; keep extras as fallbacks just in case
        let candidates = [
            "com.microsoft.minecraft-edu",
            "com.microsoft.minecrafteducation",
            "com.mojang.minecrafteducation",
            "com.mojang.minecraftEdu"
        ]
        let paths = [
            "/Applications/Minecraft Education.app",
            "/Applications/Minecraft Education Edition.app"
        ]
        openApp(bundleIds: candidates, fallbackPaths: paths)
    }

    static func openChrome() {
        openApp(bundleIds: ["com.google.Chrome"], fallbackPaths: ["/Applications/Google Chrome.app"])
    }

    static func openSafari() {
        openApp(bundleIds: ["com.apple.Safari"])
    }

    static func openSystemSettings() {
        // Ventura+ (System Settings) then Monterey (System Preferences)
        openApp(bundleIds: ["com.apple.SystemSettings", "com.apple.systempreferences"])
    }

    static func openFinder() {
        let ws = NSWorkspace.shared
        if let url = ws.urlForApplication(withBundleIdentifier: "com.apple.finder") {
            logger.info("Opening Finder via bundle id")
            ws.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: { _,_  in })
        } else {
            logger.info("Opening Finder by revealing the home directory")
            NSWorkspace.shared.open(FileManager.default.homeDirectoryForCurrentUser)
        }
    }
}
