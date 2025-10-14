import SwiftUI
import Cocoa
import CoreData

@main
struct CommonbaseMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var eventMonitor: EventMonitor?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        setupPopover()
        setupEventMonitor()
        setupGlobalRightClick()
    }

    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "square.stack.3d.up", accessibilityDescription: "Commonbase")
            button.action = #selector(togglePopover)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    private func setupPopover() {
        popover = NSPopover()
        popover?.contentViewController = NSHostingController(rootView: ContentView().environment(\.managedObjectContext, PersistenceController.shared.container.viewContext))
        popover?.behavior = .transient
    }

    private func setupEventMonitor() {
        eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let popover = self?.popover, popover.isShown {
                self?.closePopover()
            }
        }
    }

    private func setupGlobalRightClick() {
        NSEvent.addGlobalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
            DispatchQueue.main.async {
                self?.handleGlobalRightClick(event)
            }
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }

        if let popover = popover {
            if popover.isShown {
                closePopover()
            } else {
                showPopover(relativeTo: button.bounds, of: button)
            }
        }
    }

    private func showPopover(relativeTo rect: NSRect, of view: NSView) {
        eventMonitor?.start()
        popover?.show(relativeTo: rect, of: view, preferredEdge: .minY)
    }

    private func closePopover() {
        eventMonitor?.stop()
        popover?.performClose(nil)
    }

    private func handleGlobalRightClick(_ event: NSEvent) {
        let dataCapture = DataCaptureService()

        // Get current selected text
        if let selectedText = getSelectedText(), !selectedText.isEmpty {
            let context = getCurrentApplicationContext()
            dataCapture.saveText(selectedText, context: context)
            showNotification("Text saved to Commonbase", subtitle: selectedText.prefix(50) + "...")
        } else {
            // Show context menu for screenshot options
            showScreenshotMenu(at: event.locationInWindow)
        }
    }

    private func showScreenshotMenu(at location: NSPoint) {
        let menu = NSMenu()

        let areaItem = NSMenuItem(title: "Capture Selected Area", action: #selector(captureArea), keyEquivalent: "")
        areaItem.target = self
        menu.addItem(areaItem)

        let fullScreenItem = NSMenuItem(title: "Capture Full Screen", action: #selector(captureFullScreen), keyEquivalent: "")
        fullScreenItem.target = self
        menu.addItem(fullScreenItem)

        menu.popUp(positioning: nil, at: location, in: nil)
    }

    @objc private func captureArea() {
        let dataCapture = DataCaptureService()
        dataCapture.captureScreenArea { [weak self] image in
            if let image = image {
                let context = self?.getCurrentApplicationContext() ?? ApplicationContext(bundleId: "", name: "", url: nil)
                dataCapture.saveImage(image, context: context)
                self?.showNotification("Screenshot saved to Commonbase", subtitle: "Area capture completed")
            }
        }
    }

    @objc private func captureFullScreen() {
        let dataCapture = DataCaptureService()
        dataCapture.captureFullScreen { [weak self] image in
            if let image = image {
                let context = self?.getCurrentApplicationContext() ?? ApplicationContext(bundleId: "", name: "", url: nil)
                dataCapture.saveImage(image, context: context)
                self?.showNotification("Screenshot saved to Commonbase", subtitle: "Full screen capture completed")
            }
        }
    }

    private func getSelectedText() -> String? {
        let pasteboard = NSPasteboard.general
        let oldContents = pasteboard.string(forType: .string)

        // Send Cmd+C to copy selected text
        let source = CGEventSource(stateID: .hidSystemState)
        let cmdC = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: true) // C key
        cmdC?.flags = .maskCommand
        cmdC?.post(tap: .cghidEventTap)

        let cmdCUp = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: false)
        cmdCUp?.flags = .maskCommand
        cmdCUp?.post(tap: .cghidEventTap)

        // Small delay to allow clipboard to update
        Thread.sleep(forTimeInterval: 0.1)

        let newContents = pasteboard.string(forType: .string)

        // Restore old clipboard contents if they were different
        if oldContents != newContents, let oldContents = oldContents {
            pasteboard.clearContents()
            pasteboard.setString(oldContents, forType: .string)
        }

        return newContents != oldContents ? newContents : nil
    }

    private func getCurrentApplicationContext() -> ApplicationContext {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return ApplicationContext(bundleId: "", name: "", url: nil)
        }

        let bundleId = frontmostApp.bundleIdentifier ?? ""
        let appName = frontmostApp.localizedName ?? ""

        // Try to get current URL or file path for supported applications
        var url: String? = nil

        if bundleId.contains("chrome") || bundleId.contains("safari") || bundleId.contains("firefox") {
            url = getBrowserURL(bundleId: bundleId)
        } else if bundleId.contains("vscode") || bundleId.contains("xcode") || bundleId.contains("textmate") {
            url = getEditorFilePath(bundleId: bundleId)
        }

        return ApplicationContext(bundleId: bundleId, name: appName, url: url)
    }

    private func getBrowserURL(bundleId: String) -> String? {
        // This would require AppleScript or accessibility API to get current URL
        // Implementation depends on specific browser and security permissions
        return nil
    }

    private func getEditorFilePath(bundleId: String) -> String? {
        // This would require AppleScript or accessibility API to get current file path
        // Implementation depends on specific editor and security permissions
        return nil
    }

    private func showNotification(_ title: String, subtitle: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.subtitle = subtitle
        notification.soundName = NSUserNotificationDefaultSoundName

        NSUserNotificationCenter.default.deliver(notification)
    }
}