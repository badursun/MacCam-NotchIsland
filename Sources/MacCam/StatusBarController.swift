import AppKit
import SwiftUI

class StatusBarController: NSObject {
    private var statusItem: NSStatusItem
    private let cameraManager = CameraManager()
    private var notchWindow: NotchWindow?
    private var eventMonitor: Any?

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

    private func openNotch() {
        guard let screen = NSScreen.main else { return }

        let menuBarHeight = screen.frame.height
            - screen.visibleFrame.height
            - screen.visibleFrame.origin.y
        let panelWidth = contentBodyWidth + sideGap * 2
        let contentHeight: CGFloat = 360
        let windowHeight = menuBarHeight + contentHeight

        // Window at full size from the start — animation is inside SwiftUI
        let frame = NSRect(
            x: screen.frame.midX - panelWidth / 2,
            y: screen.frame.maxY - windowHeight,
            width: panelWidth,
            height: windowHeight
        )

        let window = NotchWindow(contentRect: frame)
        window.hasShadow = false

        let view = ContentView(cameraManager: cameraManager, menuBarHeight: menuBarHeight)
        window.contentView = NSHostingView(rootView: view)
        window.orderFrontRegardless()
        notchWindow = window

        cameraManager.startSession()

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

        // Smooth fade-out
        NSAnimationContext.runAnimationGroup({ context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            window.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            window.orderOut(nil)
            self?.notchWindow = nil
            self?.cameraManager.stopSession()
        })
    }
}
