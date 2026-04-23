import AppKit
import SwiftUI
import Combine

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem
    private let cameraManager = CameraManager()
    private let settings = SettingsManager.shared
    private var notchWindow: NotchWindow?
    private var backdropWindow: NSWindow?
    private var eventMonitor: Any?
    private var keyMonitor: Any?
    private var backdropSub: AnyCancellable?

    private let sideGap: CGFloat = 20
    private let contentBodyWidth: CGFloat = 300

    override init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "camera.fill",
                                   accessibilityDescription: "MacCam")
            button.action = #selector(statusBarButtonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.target = self
        }
    }

    @objc func statusBarButtonClicked(_ sender: AnyObject?) {
        guard let event = NSApp.currentEvent else { return }
        if event.type == .rightMouseUp {
            showQuitMenu()
        } else {
            toggleCamera()
        }
    }

    private func toggleCamera() {
        if notchWindow != nil { closeNotch() } else { openNotch() }
    }

    private func showQuitMenu() {
        let menu = NSMenu()
        let item = NSMenuItem(title: "MacCam'i Kapat", action: #selector(quitApp), keyEquivalent: "")
        item.target = self
        menu.addItem(item)
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        DispatchQueue.main.async { self.statusItem.menu = nil }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }

    private func createBackdrop(screen: NSScreen) {
        let backdrop = NSWindow(
            contentRect: screen.frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        backdrop.isOpaque = false
        backdrop.backgroundColor = .clear
        backdrop.level = .init(rawValue: Int(CGWindowLevelForKey(.popUpMenuWindow)) - 1)
        backdrop.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        backdrop.ignoresMouseEvents = false

        // White frosted glass container
        let container = NSView(frame: screen.frame)
        container.wantsLayer = true
        container.layer?.backgroundColor = NSColor.white.withAlphaComponent(0.15).cgColor

        let blur = NSVisualEffectView(frame: screen.frame)
        blur.blendingMode = .behindWindow
        blur.material = .hudWindow
        blur.state = .active
        blur.autoresizingMask = [.width, .height]

        container.addSubview(blur)
        container.autoresizingMask = [.width, .height]
        backdrop.contentView = container

        backdrop.alphaValue = 0
        backdrop.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.35
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            backdrop.animator().alphaValue = 1.0
        }

        backdropWindow = backdrop
    }

    private func openNotch() {
        guard let screen = NSScreen.main else { return }

        // Backdrop (if enabled)
        if settings.backdropEnabled {
            createBackdrop(screen: screen)
        }

        let menuBarHeight = screen.frame.height
            - screen.visibleFrame.height
            - screen.visibleFrame.origin.y
        let panelWidth = contentBodyWidth + sideGap * 2
        let contentHeight: CGFloat = 420
        let windowHeight = menuBarHeight + contentHeight

        let frame = NSRect(
            x: screen.frame.midX - panelWidth / 2,
            y: screen.frame.maxY - windowHeight,
            width: panelWidth,
            height: windowHeight
        )

        let window = NotchWindow(contentRect: frame)
        window.hasShadow = false

        let view = ContentView(
            cameraManager: cameraManager,
            settings: settings,
            menuBarHeight: menuBarHeight,
            onClose: { [weak self] in self?.closeNotch() }
        )
        window.contentView = NSHostingView(rootView: view)
        window.orderFrontRegardless()
        notchWindow = window

        cameraManager.startSession()

        // React to backdrop toggle in real-time
        backdropSub = settings.$backdropEnabled
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                guard let self, self.notchWindow != nil else { return }
                if enabled {
                    if self.backdropWindow == nil, let screen = NSScreen.main {
                        self.createBackdrop(screen: screen)
                    }
                } else {
                    self.backdropWindow?.orderOut(nil)
                    self.backdropWindow = nil
                }
            }

        // Pause/resume monitors for NSOpenPanel
        settings.onPanelWillOpen = { [weak self] in
            self?.pauseMonitors()
            self?.backdropWindow?.orderOut(nil)
            self?.notchWindow?.orderOut(nil)
        }
        settings.onPanelDidClose = { [weak self] in
            self?.backdropWindow?.orderFrontRegardless()
            self?.notchWindow?.orderFrontRegardless()
            self?.resumeMonitors()
        }

        // ESC key to close
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC
                self?.closeNotch()
                return nil
            }
            return event
        }

        // Click outside to close
        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            self?.closeNotch()
        }
    }

    private func pauseMonitors() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }
    }

    private func resumeMonitors() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 {
                self?.closeNotch()
                return nil
            }
            return event
        }
        eventMonitor = NSEvent.addGlobalMonitorForEvents(
            matching: [.leftMouseDown, .rightMouseDown]
        ) { [weak self] _ in
            self?.closeNotch()
        }
    }

    private func closeNotch() {
        guard let window = notchWindow else { return }

        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
        if let monitor = keyMonitor {
            NSEvent.removeMonitor(monitor)
            keyMonitor = nil
        }

        backdropSub?.cancel()
        backdropSub = nil

        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.25
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
            self.backdropWindow?.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            window.orderOut(nil)
            self?.notchWindow = nil
            self?.backdropWindow?.orderOut(nil)
            self?.backdropWindow = nil
            self?.cameraManager.stopSession()
        })
    }
}
