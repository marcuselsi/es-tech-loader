import Foundation
import Sparkle

final class UpdaterController: NSObject, SPUUpdaterDelegate {
    static let shared = UpdaterController()

    // This object owns the updater and starts background checks
    let updaterController = SPUStandardUpdaterController(
        startingUpdater: true,           // check on launch & periodically
        updaterDelegate: nil,
        userDriverDelegate: nil
    )

    // Optional: expose a manual “check now”
    func checkNow() { updaterController.checkForUpdates(nil) }
}
