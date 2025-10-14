import AppKit
import Foundation

class ScreenSelectionWindow: NSWindow {
    private var startPoint: NSPoint = .zero
    private var currentPoint: NSPoint = .zero
    private var isDragging = false
    private let completion: (CGRect?) -> Void

    init(completion: @escaping (CGRect?) -> Void) {
        self.completion = completion

        // Create a window that covers all screens
        let screenRect = NSScreen.screens.reduce(NSRect.zero) { result, screen in
            result.union(screen.frame)
        }

        super.init(
            contentRect: screenRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        setupWindow()
        setupViews()
        setupEventHandling()
    }

    private func setupWindow() {
        backgroundColor = NSColor.clear
        level = .screenSaver
        ignoresMouseEvents = false
        acceptsMouseMovedEvents = true
        isOpaque = false
        hasShadow = false
    }

    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }

    private func setupViews() {
        contentView = ScreenSelectionView(window: self)
    }

    private func setupEventHandling() {
        // Add global event monitors
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape key
                self?.cancel()
                return nil
            }
            return event
        }
    }

    override func mouseDown(with event: NSEvent) {
        startPoint = event.locationInWindow
        currentPoint = startPoint
        isDragging = true
        contentView?.needsDisplay = true
    }

    override func mouseDragged(with event: NSEvent) {
        if isDragging {
            currentPoint = event.locationInWindow
            contentView?.needsDisplay = true
        }
    }

    override func mouseUp(with event: NSEvent) {
        if isDragging {
            isDragging = false
            let selectionRect = getSelectionRect()
            close()

            if selectionRect.width > 10 && selectionRect.height > 10 {
                // Need to convert from window coordinates to screen coordinates
                // Window coordinates have origin at bottom-left, screen coordinates at top-left
                let windowFrame = self.frame
                let screenRect = CGRect(
                    x: windowFrame.origin.x + min(startPoint.x, currentPoint.x),
                    y: windowFrame.origin.y + min(startPoint.y, currentPoint.y),
                    width: abs(currentPoint.x - startPoint.x),
                    height: abs(currentPoint.y - startPoint.y)
                )
                print("🖼️ Selection rect: \(screenRect)")
                completion(screenRect)
            } else {
                print("❌ Selection too small: \(selectionRect)")
                completion(nil)
            }
        }
    }

    private func getSelectionRect() -> NSRect {
        return NSRect(
            x: min(startPoint.x, currentPoint.x),
            y: min(startPoint.y, currentPoint.y),
            width: abs(currentPoint.x - startPoint.x),
            height: abs(currentPoint.y - startPoint.y)
        )
    }

    private func cancel() {
        close()
        completion(nil)
    }

    func getSelectionRectForDrawing() -> NSRect {
        if isDragging {
            return getSelectionRect()
        }
        return .zero
    }
}

class ScreenSelectionView: NSView {
    weak var selectionWindow: ScreenSelectionWindow?

    init(window: ScreenSelectionWindow) {
        self.selectionWindow = window
        super.init(frame: window.frame)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Fill the entire view with a semi-transparent overlay
        NSColor.black.withAlphaComponent(0.3).setFill()
        dirtyRect.fill()

        // If we have a selection, draw the selection rectangle
        if let selectionWindow = selectionWindow {
            let selectionRect = selectionWindow.getSelectionRectForDrawing()
            if !selectionRect.isEmpty {
                // Clear the selection area
                NSColor.clear.setFill()
                selectionRect.fill(using: .copy)

                // Draw selection border
                NSColor.white.setStroke()
                let borderPath = NSBezierPath(rect: selectionRect)
                borderPath.lineWidth = 2
                borderPath.stroke()

                // Draw corner handles
                drawCornerHandles(for: selectionRect)
            }
        }
    }

    private func drawCornerHandles(for rect: NSRect) {
        let handleSize: CGFloat = 8
        let handleColor = NSColor.white

        let handles = [
            NSPoint(x: rect.minX, y: rect.minY),
            NSPoint(x: rect.maxX, y: rect.minY),
            NSPoint(x: rect.minX, y: rect.maxY),
            NSPoint(x: rect.maxX, y: rect.maxY)
        ]

        handleColor.setFill()
        for handle in handles {
            let handleRect = NSRect(
                x: handle.x - handleSize/2,
                y: handle.y - handleSize/2,
                width: handleSize,
                height: handleSize
            )
            NSBezierPath(ovalIn: handleRect).fill()
        }
    }
}