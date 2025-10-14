import SwiftUI
import Cocoa
import CoreData
import UserNotifications

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
    var mainWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        setupStatusItem()
        setupPopover()
        setupEventMonitor()
        setupGlobalRightClick()
        setupGlobalKeyboardShortcuts()
        setupServices()
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
            if let window = self?.mainWindow, window.isVisible {
                // Only close if the click is outside the window
                if let windowFrame = self?.mainWindow?.frame {
                    let globalClickLocation = NSEvent.mouseLocation
                    if !windowFrame.contains(globalClickLocation) {
                        self?.closePopover()
                    }
                }
            }
        }
    }

    private func setupGlobalRightClick() {
        // Disabled per user request
        /*
        NSEvent.addGlobalMonitorForEvents(matching: .rightMouseDown) { [weak self] event in
            DispatchQueue.main.async {
                self?.handleGlobalRightClick(event)
            }
        }
        */
    }

    private func setupGlobalKeyboardShortcuts() {
        // Use global event monitor for system-wide shortcuts
        NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            _ = self?.handleGlobalKeyDown(event)
        }

        // Also use local event monitor for when app is in focus
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleGlobalKeyDown(event) == true {
                return nil // consume the event
            }
            return event
        }
    }

    private func handleGlobalKeyDown(_ event: NSEvent) -> Bool {
        let modifiers = event.modifierFlags
        let keyCode = event.keyCode
        let character = event.charactersIgnoringModifiers?.lowercased() ?? ""

        // Get current shortcut settings
        let defaults = UserDefaults.standard

        // Check Save Highlighted Text
        let saveTextKey = defaults.string(forKey: "shortcut_save_text_key") ?? "s"
        let saveTextCmd = defaults.bool(forKey: "shortcut_save_text_cmd")
        let saveTextOpt = defaults.bool(forKey: "shortcut_save_text_opt")
        let saveTextShift = defaults.bool(forKey: "shortcut_save_text_shift")

        if checkShortcutMatch(
            character: character,
            keyCode: keyCode,
            modifiers: modifiers,
            settingsKey: saveTextKey,
            settingsCmd: saveTextCmd,
            settingsOpt: saveTextOpt,
            settingsShift: saveTextShift
        ) {
            print("🎯 Save text shortcut matched! Key: \(saveTextKey), Cmd: \(saveTextCmd), Opt: \(saveTextOpt), Shift: \(saveTextShift)")
            DispatchQueue.main.async {
                self.saveHighlightedText()
            }
            return true
        }

        // Check Area Screenshot
        if checkShortcutMatch(
            character: character,
            keyCode: keyCode,
            modifiers: modifiers,
            settingsKey: defaults.string(forKey: "shortcut_area_screenshot_key") ?? "a",
            settingsCmd: defaults.bool(forKey: "shortcut_area_screenshot_cmd"),
            settingsOpt: defaults.bool(forKey: "shortcut_area_screenshot_opt"),
            settingsShift: defaults.bool(forKey: "shortcut_area_screenshot_shift")
        ) {
            DispatchQueue.main.async {
                self.captureArea()
            }
            return true
        }

        // Check Full Screenshot
        if checkShortcutMatch(
            character: character,
            keyCode: keyCode,
            modifiers: modifiers,
            settingsKey: defaults.string(forKey: "shortcut_full_screenshot_key") ?? "f",
            settingsCmd: defaults.bool(forKey: "shortcut_full_screenshot_cmd"),
            settingsOpt: defaults.bool(forKey: "shortcut_full_screenshot_opt"),
            settingsShift: defaults.bool(forKey: "shortcut_full_screenshot_shift")
        ) {
            DispatchQueue.main.async {
                self.captureFullScreen()
            }
            return true
        }

        // Check Generate Embeddings
        if checkShortcutMatch(
            character: character,
            keyCode: keyCode,
            modifiers: modifiers,
            settingsKey: defaults.string(forKey: "shortcut_generate_embeddings_key") ?? "e",
            settingsCmd: defaults.bool(forKey: "shortcut_generate_embeddings_cmd"),
            settingsOpt: defaults.bool(forKey: "shortcut_generate_embeddings_opt"),
            settingsShift: defaults.bool(forKey: "shortcut_generate_embeddings_shift")
        ) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("GenerateEmbeddings"), object: nil)
            }
            return true
        }

        // Check Regenerate Embedding
        if checkShortcutMatch(
            character: character,
            keyCode: keyCode,
            modifiers: modifiers,
            settingsKey: defaults.string(forKey: "shortcut_regenerate_embedding_key") ?? "r",
            settingsCmd: defaults.bool(forKey: "shortcut_regenerate_embedding_cmd"),
            settingsOpt: defaults.bool(forKey: "shortcut_regenerate_embedding_opt"),
            settingsShift: defaults.bool(forKey: "shortcut_regenerate_embedding_shift")
        ) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("RegenerateEmbedding"), object: nil)
            }
            return true
        }

        // Check Delete Entry
        if checkShortcutMatch(
            character: character,
            keyCode: keyCode,
            modifiers: modifiers,
            settingsKey: defaults.string(forKey: "shortcut_delete_entry_key") ?? "Delete",
            settingsCmd: defaults.bool(forKey: "shortcut_delete_entry_cmd"),
            settingsOpt: defaults.bool(forKey: "shortcut_delete_entry_opt"),
            settingsShift: defaults.bool(forKey: "shortcut_delete_entry_shift")
        ) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("DeleteEntry"), object: nil)
            }
            return true
        }

        // Check Next Entry
        if checkShortcutMatch(
            character: character,
            keyCode: keyCode,
            modifiers: modifiers,
            settingsKey: defaults.string(forKey: "shortcut_next_entry_key") ?? "↓",
            settingsCmd: defaults.bool(forKey: "shortcut_next_entry_cmd"),
            settingsOpt: defaults.bool(forKey: "shortcut_next_entry_opt"),
            settingsShift: defaults.bool(forKey: "shortcut_next_entry_shift")
        ) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("NextEntry"), object: nil)
            }
            return true
        }

        // Check Previous Entry
        if checkShortcutMatch(
            character: character,
            keyCode: keyCode,
            modifiers: modifiers,
            settingsKey: defaults.string(forKey: "shortcut_previous_entry_key") ?? "↑",
            settingsCmd: defaults.bool(forKey: "shortcut_previous_entry_cmd"),
            settingsOpt: defaults.bool(forKey: "shortcut_previous_entry_opt"),
            settingsShift: defaults.bool(forKey: "shortcut_previous_entry_shift")
        ) {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("PreviousEntry"), object: nil)
            }
            return true
        }

        return false
    }

    private func checkShortcutMatch(
        character: String,
        keyCode: UInt16,
        modifiers: NSEvent.ModifierFlags,
        settingsKey: String,
        settingsCmd: Bool,
        settingsOpt: Bool,
        settingsShift: Bool
    ) -> Bool {
        // Check key match
        let keyMatches: Bool
        switch settingsKey {
        case "Delete":
            keyMatches = keyCode == 51
        case "↑":
            keyMatches = keyCode == 126
        case "↓":
            keyMatches = keyCode == 125
        case "←":
            keyMatches = keyCode == 123
        case "→":
            keyMatches = keyCode == 124
        case "Space":
            keyMatches = keyCode == 49
        case "Return":
            keyMatches = keyCode == 36
        case "Escape":
            keyMatches = keyCode == 53
        case "Tab":
            keyMatches = keyCode == 48
        default:
            keyMatches = character == settingsKey.lowercased()
        }

        // Check modifier matches
        let cmdMatches = settingsCmd == modifiers.contains(.command)
        let optMatches = settingsOpt == modifiers.contains(.option)
        let shiftMatches = settingsShift == modifiers.contains(.shift)

        return keyMatches && cmdMatches && optMatches && shiftMatches
    }

    private func setupServices() {
        NSApp.servicesProvider = self
        NSUpdateDynamicServices()
    }

    @objc func saveTextToCommonbase(_ pasteboard: NSPasteboard, userData: String?, error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        guard let text = pasteboard.string(forType: .string), !text.isEmpty else {
            error.pointee = "No text found in pasteboard"
            return
        }

        print("📋 Services: Saving text to Commonbase: \(text.prefix(50))")

        let context = getCurrentApplicationContext()
        let dataCapture = DataCaptureService()
        dataCapture.saveText(text, context: context)
        showNotification("Text Saved", subtitle: "Added to Commonbase via Services")
    }

    private func saveHighlightedText() {
        print("🎯 saveHighlightedText() called - COMPLETELY REWRITTEN")

        DispatchQueue.global(qos: .userInitiated).async {
            // Step 1: Get the current foremost application with enhanced Chrome URL detection
            let context = self.getCurrentApplicationContextEnhanced()
            print("📱 Current app: \(context.name) (\(context.bundleId))")
            print("🔗 Current URL: \(context.url ?? "nil")")

            // Step 2: Get selected text using improved method
            if let selectedText = self.getSelectedTextImproved() {
                print("✅ Got selected text: \(String(selectedText.prefix(50)))")

                DispatchQueue.main.async {
                    let dataCapture = DataCaptureService()
                    dataCapture.saveText(selectedText, context: context)
                    self.showNotification("Text Saved to Commonbase", subtitle: "From \(context.name)")
                }
            } else {
                print("❌ No text could be captured")
                DispatchQueue.main.async {
                    self.showNotification("No Text Found", subtitle: "Please select text first")
                }
            }
        }
    }

    @objc private func togglePopover() {
        guard let button = statusItem?.button else { return }

        if let window = mainWindow, window.isVisible {
            closePopover()
        } else {
            showPopover(relativeTo: button.bounds, of: button)
        }
    }

    private func showPopover(relativeTo rect: NSRect, of view: NSView) {
        // If window already exists and is visible, just bring to front
        if let window = mainWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create a new window if needed
        if mainWindow == nil {
            let contentView = ContentView().environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
            let hostingController = NSHostingController(rootView: contentView)

            mainWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            mainWindow?.contentViewController = hostingController
            mainWindow?.title = "Commonbase"
            mainWindow?.isReleasedWhenClosed = false
        }

        // Center the window on screen
        if let window = mainWindow {
            window.center()
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }

        eventMonitor?.start()
    }

    private func closePopover() {
        eventMonitor?.stop()
        mainWindow?.orderOut(nil)
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
        print("🎯 Attempting to get selected text...")

        let pasteboard = NSPasteboard.general
        let oldContents = pasteboard.string(forType: .string)
        print("📋 Old clipboard contents: \(oldContents?.prefix(50) ?? "nil")")

        // Send Cmd+C to copy selected text
        let source = CGEventSource(stateID: .hidSystemState)

        // Check if we can create events (requires accessibility permissions)
        guard let cmdC = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: true) else {
            print("❌ Failed to create CGEvent - check accessibility permissions")
            showNotification("Permission Needed", subtitle: "Grant accessibility access in System Preferences")
            return nil
        }

        cmdC.flags = .maskCommand
        cmdC.post(tap: .cghidEventTap)

        let cmdCUp = CGEvent(keyboardEventSource: source, virtualKey: 8, keyDown: false)
        cmdCUp?.flags = .maskCommand
        cmdCUp?.post(tap: .cghidEventTap)

        // Longer delay to allow clipboard to update
        Thread.sleep(forTimeInterval: 0.2)

        let newContents = pasteboard.string(forType: .string)
        print("📋 New clipboard contents: \(newContents?.prefix(50) ?? "nil")")

        // Only restore if the contents actually changed
        let selectedText = (newContents != oldContents) ? newContents : nil

        if selectedText != nil {
            print("✅ Successfully captured selected text: \(selectedText!.prefix(50))")

            // Restore old clipboard contents if they were different
            if let oldContents = oldContents, oldContents != newContents {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    pasteboard.clearContents()
                    pasteboard.setString(oldContents, forType: .string)
                    print("♻️ Restored original clipboard contents")
                }
            }
        } else {
            print("⚠️ No text was selected or captured")
        }

        return selectedText
    }

    private func getCurrentApplicationContext() -> ApplicationContext {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            print("❌ No frontmost application found")
            return ApplicationContext(bundleId: "", name: "", url: nil)
        }

        let bundleId = frontmostApp.bundleIdentifier ?? ""
        let appName = frontmostApp.localizedName ?? ""
        print("🔍 Current app: \(appName) (\(bundleId))")

        // Try to get current URL or file path for supported applications
        var url: String? = nil

        if bundleId.lowercased().contains("chrome") || bundleId.lowercased().contains("safari") || bundleId.lowercased().contains("firefox") {
            print("🌐 Detected browser, attempting to get URL...")
            url = getBrowserURL(bundleId: bundleId)
            if let url = url {
                print("✅ Got URL: \(url)")
            } else {
                print("❌ Failed to get URL from browser")
            }
        } else if bundleId.lowercased().contains("vscode") || bundleId.lowercased().contains("xcode") || bundleId.lowercased().contains("textmate") {
            url = getEditorFilePath(bundleId: bundleId)
        }

        return ApplicationContext(bundleId: bundleId, name: appName, url: url)
    }

    private func getBrowserURL(bundleId: String) -> String? {
        print("🔍 Getting URL for bundle: \(bundleId)")
        // Try to get URL from Safari using AppleScript
        if bundleId.lowercased().contains("safari") {
            print("🧭 Trying Safari AppleScript...")
            return getSafariURL()
        } else if bundleId.lowercased().contains("chrome") {
            print("🧭 Trying Chrome AppleScript...")
            return getChromeURL()
        } else if bundleId.lowercased().contains("firefox") {
            print("🧭 Trying Firefox AppleScript...")
            return getFirefoxURL()
        }
        return nil
    }

    private func getSafariURL() -> String? {
        let appleScript = """
        tell application "Safari"
            if (count of windows) > 0 then
                return URL of front document
            end if
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: appleScript) {
            let output = scriptObject.executeAndReturnError(&error)
            if error == nil, let urlString = output.stringValue {
                return urlString
            }
        }
        return nil
    }

    private func getChromeURL() -> String? {
        let appleScript = """
        tell application "Google Chrome"
            if (count of windows) > 0 then
                return URL of active tab of front window
            end if
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: appleScript) {
            let output = scriptObject.executeAndReturnError(&error)
            if let error = error {
                print("❌ Chrome AppleScript error: \(error)")
                return nil
            }
            if let urlString = output.stringValue {
                print("✅ Chrome URL: \(urlString)")
                return urlString
            }
        }
        print("⚠️ Chrome AppleScript returned no URL")
        return nil
    }

    private func getFirefoxURL() -> String? {
        let appleScript = """
        tell application "Firefox"
            if (count of windows) > 0 then
                get URL of active tab of front window
            end if
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: appleScript) {
            let output = scriptObject.executeAndReturnError(&error)
            if error == nil, let urlString = output.stringValue {
                return urlString
            }
        }
        return nil
    }

    private func getEditorFilePath(bundleId: String) -> String? {
        // Try to get file path from various editors
        if bundleId.contains("vscode") {
            return getVSCodeFilePath()
        } else if bundleId.contains("textmate") {
            return getTextMateFilePath()
        } else if bundleId.contains("finder") {
            return getFinderSelection()
        }
        return nil
    }

    private func getVSCodeFilePath() -> String? {
        // For VS Code, try to get the active file through AppleScript
        // This is a simplified approach - real implementation might need accessibility API
        return nil
    }

    private func getTextMateFilePath() -> String? {
        let appleScript = """
        tell application "TextMate"
            if (count of documents) > 0 then
                return path of front document
            end if
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: appleScript) {
            let output = scriptObject.executeAndReturnError(&error)
            if error == nil, let filePath = output.stringValue {
                return "file://" + filePath
            }
        }
        return nil
    }

    private func getFinderSelection() -> String? {
        let appleScript = """
        tell application "Finder"
            if (count of selection) > 0 then
                return POSIX path of (item 1 of selection as alias)
            end if
        end tell
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: appleScript) {
            let output = scriptObject.executeAndReturnError(&error)
            if error == nil, let filePath = output.stringValue {
                return "file://" + filePath
            }
        }
        return nil
    }

    // MARK: - New Improved Methods

    private func getSelectedTextImproved() -> String? {
        print("📋 Getting selected text (IMPROVED METHOD)")

        // Get current pasteboard state to restore later
        let pasteboard = NSPasteboard.general
        let originalContents = pasteboard.pasteboardItems?.first
        let originalString = originalContents?.string(forType: .string)

        // Create event source
        guard let eventSource = CGEventSource(stateID: .hidSystemState) else {
            print("❌ Failed to create event source - accessibility permissions needed")
            return nil
        }

        // Send Cmd+C to copy selected text
        let keyDownEvent = CGEvent(keyboardEventSource: eventSource, virtualKey: 8, keyDown: true)
        let keyUpEvent = CGEvent(keyboardEventSource: eventSource, virtualKey: 8, keyDown: false)

        keyDownEvent?.flags = .maskCommand
        keyUpEvent?.flags = .maskCommand

        // Post the events
        keyDownEvent?.post(tap: .cghidEventTap)
        Thread.sleep(forTimeInterval: 0.05)
        keyUpEvent?.post(tap: .cghidEventTap)

        // Wait for copy operation to complete
        Thread.sleep(forTimeInterval: 0.3)

        // Get the copied text
        let copiedText = pasteboard.string(forType: .string)

        // Check if we got new text
        if let copiedText = copiedText,
           !copiedText.isEmpty,
           copiedText != originalString {

            print("✅ Captured text: \(String(copiedText.prefix(50)))")

            // Restore original clipboard after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                if let originalContents = originalContents {
                    pasteboard.clearContents()
                    pasteboard.writeObjects([originalContents])
                    print("♻️ Restored original clipboard")
                } else {
                    pasteboard.clearContents()
                }
            }

            return copiedText
        } else {
            print("❌ No new text captured")
            return nil
        }
    }

    private func getCurrentApplicationContextEnhanced() -> ApplicationContext {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            print("❌ No frontmost application found")
            return ApplicationContext(bundleId: "", name: "", url: nil)
        }

        let bundleId = frontmostApp.bundleIdentifier ?? ""
        let appName = frontmostApp.localizedName ?? ""
        print("🔍 Enhanced context for: \(appName) (\(bundleId))")

        var url: String? = nil

        // Enhanced Chrome URL detection
        if bundleId.contains("com.google.Chrome") {
            print("🌐 Enhanced Chrome URL detection...")
            url = getChromeURLEnhanced()
        } else if bundleId.contains("com.apple.Safari") {
            url = getSafariURL()
        } else if bundleId.contains("org.mozilla.firefox") {
            url = getFirefoxURL()
        } else if bundleId.contains("vscode") || bundleId.contains("xcode") || bundleId.contains("textmate") {
            url = getEditorFilePath(bundleId: bundleId)
        }

        if let url = url {
            print("✅ Got URL: \(url)")
        } else {
            print("❌ No URL captured for \(bundleId)")
        }

        return ApplicationContext(bundleId: bundleId, name: appName, url: url)
    }

    private func getChromeURLEnhanced() -> String? {
        // More robust Chrome AppleScript
        let appleScript = """
        try
            tell application "Google Chrome"
                if (count of windows) > 0 then
                    set frontWindow to front window
                    if frontWindow exists then
                        set activeTab to active tab of frontWindow
                        if activeTab exists then
                            return URL of activeTab
                        end if
                    end if
                end if
            end tell
        on error errMsg
            return "error: " & errMsg
        end try
        return "no-url"
        """

        var error: NSDictionary?
        if let scriptObject = NSAppleScript(source: appleScript) {
            let output = scriptObject.executeAndReturnError(&error)

            if let error = error {
                print("❌ Chrome AppleScript error: \(error)")
                return nil
            }

            if let urlString = output.stringValue,
               !urlString.isEmpty,
               !urlString.contains("error:"),
               urlString != "no-url" {
                print("✅ Chrome URL: \(urlString)")
                return urlString
            } else {
                print("⚠️ Chrome AppleScript returned: \(output.stringValue ?? "nil")")
            }
        }

        return nil
    }

    private func showNotification(_ title: String, subtitle: String) {
        let center = UNUserNotificationCenter.current()

        let content = UNMutableNotificationContent()
        content.title = title
        content.subtitle = subtitle
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        center.add(request) { error in
            if let error = error {
                print("❌ Failed to show notification: \(error)")
            }
        }
    }
}