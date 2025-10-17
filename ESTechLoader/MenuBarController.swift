import AppKit
import os

final class MenuBarController {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
    private let logger = Logger(subsystem: "ca.elsipogtog.estechloader", category: "Menu")

    private let configLoader = RemoteConfig()
    private var currentConfig: LoaderConfig?

    init() {
        // Icon / title
        if let button = statusItem.button {
            if let img = NSImage(named: "DrumIcon") {
                img.isTemplate = true
                button.image = img
                button.imagePosition = .imageOnly
                button.toolTip = "ES Tech Loader"
            } else {
                button.title = "ES"
                button.toolTip = "ES Tech Loader"
            }
        }

        // Build immediately using local/cached config (fast)
        rebuildMenu(using: configLoader.loadPreferred())

        // Then fetch latest remote config and rebuild if changed
        configLoader.fetchLatest { [weak self] cfg in
            guard let self, let cfg else { return }
            if cfg.version != self.currentConfig?.version {
                self.logger.info("Remote config version changed; rebuilding menu.")
                self.rebuildMenu(using: cfg)
            } else {
                self.logger.info("Remote config same version; keeping current menu.")
            }
        }
    }

    // MARK: - Menu building

    private func rebuildMenu(using cfg: LoaderConfig?) {
        self.currentConfig = cfg

        let menu = NSMenu()

        if let items = cfg?.items, !items.isEmpty {
            // Dynamic items from JSON
            for item in items {
                let it = NSMenuItem(title: item.title, action: #selector(dynamicOpen(_:)), keyEquivalent: "")
                it.representedObject = item
                it.target = self
                menu.addItem(it)
            }
        } else {
            // Fallback static menu if no config yet
            menu.addItem(makeItem(title: "Minecraft Education", action: #selector(openMinecraft)))
            menu.addItem(makeItem(title: "Safari", action: #selector(openSafari)))
            menu.addItem(makeItem(title: "Google Chrome", action: #selector(openChrome)))
            menu.addItem(makeItem(title: "System Settings", action: #selector(openSettings)))
            menu.addItem(makeItem(title: "Finder", action: #selector(openFinder)))
        }

        menu.addItem(.separator())

        // Utilities
        menu.addItem(makeItem(title: "Refresh App List", action: #selector(refreshConfig)))

        // Placeholder for future Sparkle integration (safe to leave in)
        let cfu = NSMenuItem(title: "Check for Updates…", action: #selector(checkForUpdates), keyEquivalent: "")
        cfu.target = self
        menu.addItem(cfu)

        // Quit
        let quitItem = NSMenuItem(title: "Quit ES Tech Loader", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        logger.info("Menu rebuilt (\(cfg?.items.count ?? 5)) items")
    }

    private func makeItem(title: String, action: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        return item
    }

    // MARK: - Actions (static fallbacks)
    @objc private func openMinecraft() { AppLauncher.openMinecraftEducation() }
    @objc private func openSafari()    { AppLauncher.openSafari() }
    @objc private func openChrome()    { AppLauncher.openChrome() }
    @objc private func openSettings()  { AppLauncher.openSystemSettings() }
    @objc private func openFinder()    { AppLauncher.openFinder() }

    // MARK: - Actions (dynamic)
    @objc private func dynamicOpen(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? LoaderItem else { return }
        AppLauncher.openApp(bundleIds: item.bundleIds ?? [], fallbackPaths: item.paths ?? [])
    }

    @objc private func refreshConfig() {
        logger.info("Manual refresh requested")
        configLoader.fetchLatest { [weak self] cfg in
            guard let self, let cfg else { return }
            self.rebuildMenu(using: cfg)
        }
    }

    @objc private func checkForUpdates() {
        // Hook Sparkle here later (SPUStandardUpdaterController)
        // For now, just log:
        logger.info("Check for Updates clicked (Sparkle not wired yet).")
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
