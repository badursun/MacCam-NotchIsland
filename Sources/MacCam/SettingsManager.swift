import Foundation
import AppKit
import ServiceManagement

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()

    @Published var saveDirectory: URL {
        didSet { UserDefaults.standard.set(saveDirectory.path, forKey: "saveDirectory") }
    }

    @Published var backdropEnabled: Bool {
        didSet { UserDefaults.standard.set(backdropEnabled, forKey: "backdropEnabled") }
    }

    @Published var launchAtLogin: Bool = false {
        didSet {
            do {
                if launchAtLogin {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                print("MacCam: Login item error - \(error)")
                // Revert on failure
                DispatchQueue.main.async { self.launchAtLogin = !self.launchAtLogin }
            }
        }
    }

    private init() {
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        if let path = UserDefaults.standard.string(forKey: "saveDirectory") {
            let url = URL(fileURLWithPath: path)
            // Use stored path only if it still exists, otherwise reset to Desktop
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                self.saveDirectory = url
            } else {
                self.saveDirectory = desktop
            }
        } else {
            self.saveDirectory = desktop
        }
        self.backdropEnabled = UserDefaults.standard.object(forKey: "backdropEnabled") as? Bool ?? true
        self.launchAtLogin = SMAppService.mainApp.status == .enabled
    }

    /// Set by StatusBarController so we can pause/resume monitors during NSOpenPanel
    var onPanelWillOpen: (() -> Void)?
    var onPanelDidClose: (() -> Void)?

    func chooseSaveDirectory() {
        onPanelWillOpen?()

        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.prompt = "Sec"
        panel.message = "Fotograflarin kaydedilecegi klasoru secin"
        panel.directoryURL = saveDirectory

        if panel.runModal() == .OK, let url = panel.url {
            saveDirectory = url
        }

        onPanelDidClose?()
    }
}
