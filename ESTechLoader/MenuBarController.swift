//
//  MenuBarController.swift
//  ESTechLoader
//
//  Created by Marcus on 2025-10-17.
//


import AppKit
import os

final class MenuBarController {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let logger = Logger(subsystem: "ca.elsipogtog.estechloader", category: "Menu")

    init() {
        if let button = statusItem.button {
            // Use your glyph from Assets.xcassets named "DrumIcon"
            if let img = NSImage(named: "DrumIcon") {
                img.isTemplate = true
                button.image = img
                button.imagePosition = .imageOnly
                button.toolTip = "ES Tech Loader"
            } else {
                button.title = "ES" // fallback
            }
        }

        let menu = NSMenu()

        // Add your launcher items
        menu.addItem(makeItem(title: "Minecraft Education", action: #selector(openMinecraft)))
        menu.addItem(makeItem(title: "Safari", action: #selector(openSafari)))
        menu.addItem(makeItem(title: "Google Chrome", action: #selector(openChrome)))
        menu.addItem(makeItem(title: "System Settings", action: #selector(openSettings)))
        menu.addItem(makeItem(title: "Finder", action: #selector(openFinder)))

        menu.addItem(.separator())

        // Quit item
        let quitItem = NSMenuItem(title: "Quit ES Tech Loader", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu

        logger.info("Menu created")
    }

    private func makeItem(title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    // MARK: - Actions
    @objc private func openMinecraft() { AppLauncher.openMinecraftEducation() }
    @objc private func openSafari() { AppLauncher.openSafari() }
    @objc private func openChrome() { AppLauncher.openChrome() }
    @objc private func openSettings() { AppLauncher.openSystemSettings() }
    @objc private func openFinder() { AppLauncher.openFinder() }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

// MARK: - AppLauncher: central place for opening apps by bundle id or path

enum AppLauncher {
    private static let logger = Logger(subsystem: "ca.elsipogtog.estechloader", category: "Launch")

    /// Tries each bundle id, then each path. Logs outcomes.
    private static func openApp(bundleIds: [String], fallbackPaths: [String] = []) {
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
        // Optional: show a one-off alert the first time this happens.
    }

    static func openMinecraftEducation() {
        // Minecraft: Education Edition bundle id can vary by build/source.
        // Common candidates; we try several. Adjust to your deployed build if needed:
        let candidates = [
            "com.microsoft.minecraft-edu", // newer Microsoft build
            "com.mojang.minecrafteducation",    // alt
            "com.mojang.minecraftEdu"           // legacy
        ]
        let paths = [
            "/Applications/Minecraft Education.app",
            "/Applications/Minecraft Education Edition.app",
            "/Applications/minecraft education edition.app"
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
        // Monterey uses System Preferences, Ventura+ uses System Settings (different bundle IDs)
        // Try Ventura+ first, then Monterey:
        openApp(bundleIds: ["com.apple.SystemSettings", "com.apple.systempreferences"])
    }

    static func openFinder() {
        // Finder can be opened by bundle id or simply by opening the home folder.
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
