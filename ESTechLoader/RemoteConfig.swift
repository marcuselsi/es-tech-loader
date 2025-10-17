import Foundation
import os

// MARK: - JSON model
struct LoaderItem: Codable {
    let title: String
    let command: String
    let bundleIds: [String]?
    let paths: [String]?
}

struct LoaderConfig: Codable {
    let version: Int
    let items: [LoaderItem]
}

// MARK: - Remote / cached / local config loader
final class RemoteConfig {
    private let logger = Logger(subsystem: "ca.elsipogtog.estechloader", category: "Config")

    /// Default remote URL (change to your raw GitHub URL or any HTTPS file).
    /// Example raw GitHub URL:
    /// https://raw.githubusercontent.com/<user>/es-tech-loader/main/Config/loader-config.json
    private let defaultRemoteURL = URL(string:
        "https://raw.githubusercontent.com/marcuselsi/es-tech-loader/main/Config/loader-config.json"
    )!

    /// Optional per-lab override via preferences (deployed by MDM):
    /// /Library/Preferences/ca.elsipogtog.estechloader.plist  key: RemoteConfigURL (String)
    private var remoteURL: URL {
        if let s = UserDefaults.standard.string(forKey: "RemoteConfigURL"),
           let u = URL(string: s) {
            return u
        }
        return defaultRemoteURL
    }

    /// Optional local file (so IT can deploy a JSON without internet)
    private var localConfigURL: URL {
        URL(fileURLWithPath: "/Library/Application Support/ES Tech Loader/loader-config.json")
    }

    /// Cache file for last good config
    private let cacheURL: URL = {
        let appSup = try! FileManager.default.url(for: .applicationSupportDirectory,
                                                  in: .userDomainMask, appropriateFor: nil, create: true)
        let dir = appSup.appendingPathComponent("ES Tech Loader", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("loader-config.json")
    }()

    // MARK: Public API

    /// Returns local (preferred) → cached config if available.
    func loadPreferred() -> LoaderConfig? {
        // 1) Local deployed file
        if FileManager.default.fileExists(atPath: localConfigURL.path),
           let data = try? Data(contentsOf: localConfigURL),
           let cfg = try? JSONDecoder().decode(LoaderConfig.self, from: data) {
            logger.info("Loaded local config at \(self.localConfigURL.path, privacy: .public)")
            return cfg
        }
        // 2) Cached from last successful remote fetch
        if let data = try? Data(contentsOf: cacheURL),
           let cfg = try? JSONDecoder().decode(LoaderConfig.self, from: data) {
            logger.info("Loaded cached config")
            return cfg
        }
        // 3) Nothing yet
        return nil
    }

    /// Fetch latest from remote (HTTPS) and cache.
    func fetchLatest(completion: @escaping (LoaderConfig?) -> Void) {
        let url = remoteURL
        var req = URLRequest(url: url)
        req.cachePolicy = .reloadIgnoringLocalCacheData
        logger.info("Fetching remote config: \(url.absoluteString, privacy: .public)")

        URLSession.shared.dataTask(with: req) { [weak self] data, response, error in
            guard let self else { return }
            if let error {
                self.logger.error("Config fetch failed: \(error.localizedDescription, privacy: .public)")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            guard let data,
                  let cfg = try? JSONDecoder().decode(LoaderConfig.self, from: data) else {
                self.logger.error("Config decode failed (bad JSON or empty response).")
                DispatchQueue.main.async { completion(nil) }
                return
            }
            // Cache the good JSON
            do { try data.write(to: self.cacheURL, options: .atomic) }
            catch { self.logger.error("Cache write failed: \(error.localizedDescription, privacy: .public)") }

            DispatchQueue.main.async { completion(cfg) }
        }.resume()
    }
}
