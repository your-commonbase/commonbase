import Foundation
import CoreData
import AppKit
import ScreenCaptureKit

class DataCaptureService: ObservableObject {
    private let context = PersistenceController.shared.container.viewContext

    func saveText(_ text: String, context: ApplicationContext) {
        let entry = Entry(context: self.context)
        entry.id = UUID()
        entry.content = text
        entry.contentType = "text"
        entry.title = generateTitle(from: text)
        entry.createdAt = Date()
        entry.updatedAt = Date()
        entry.sourceApplication = context.name
        entry.sourceBundleId = context.bundleId
        entry.sourceURL = context.url

        var metadata = context.dictionary
        metadata["type"] = "text"
        metadata["length"] = text.count
        entry.metadata = metadata

        saveContext()
        generateEmbedding(for: entry)
    }

    func saveImage(_ image: NSImage, context: ApplicationContext) {
        let entry = Entry(context: self.context)
        entry.id = UUID()
        entry.content = "Screenshot captured from \(context.name)"
        entry.contentType = "image"
        entry.title = "Screenshot from \(context.name)"
        entry.createdAt = Date()
        entry.updatedAt = Date()
        entry.sourceApplication = context.name
        entry.sourceBundleId = context.bundleId
        entry.sourceURL = context.url

        if let imageData = image.tiffRepresentation {
            entry.imageData = imageData
        }

        var metadata = context.dictionary
        metadata["type"] = "image"
        metadata["size"] = ["width": image.size.width, "height": image.size.height]
        entry.metadata = metadata

        saveContext()
        generateEmbedding(for: entry)
    }

    func captureScreenArea(completion: @escaping (NSImage?) -> Void) {
        DispatchQueue.main.async {
            if #available(macOS 14.0, *) {
                self.captureScreenAreaModern(completion: completion)
            } else {
                self.captureScreenAreaLegacy(completion: completion)
            }
        }
    }

    func captureFullScreen(completion: @escaping (NSImage?) -> Void) {
        DispatchQueue.main.async {
            guard let screen = NSScreen.main else {
                completion(nil)
                return
            }

            let rect = screen.frame
            guard let cgImage = CGWindowListCreateImage(
                rect,
                .optionOnScreenOnly,
                kCGNullWindowID,
                .bestResolution
            ) else {
                completion(nil)
                return
            }

            let image = NSImage(cgImage: cgImage, size: rect.size)
            completion(image)
        }
    }

    @available(macOS 14.0, *)
    private func captureScreenAreaModern(completion: @escaping (NSImage?) -> Void) {
        Task {
            do {
                let availableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                guard let display = availableContent.displays.first else {
                    await MainActor.run { completion(nil) }
                    return
                }

                let filter = SCContentFilter(display: display, excludingWindows: [])
                let config = SCStreamConfiguration()

                let image = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
                let nsImage = NSImage(cgImage: image, size: NSSize(width: image.width, height: image.height))

                await MainActor.run { completion(nsImage) }
            } catch {
                print("Screen capture error: \(error)")
                await MainActor.run { completion(nil) }
            }
        }
    }

    private func captureScreenAreaLegacy(completion: @escaping (NSImage?) -> Void) {
        guard let screen = NSScreen.main else {
            completion(nil)
            return
        }

        let rect = screen.frame
        guard let cgImage = CGWindowListCreateImage(
            rect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        ) else {
            completion(nil)
            return
        }

        let image = NSImage(cgImage: cgImage, size: rect.size)
        completion(image)
    }

    private func generateTitle(from text: String) -> String {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .prefix(6)
        return words.joined(separator: " ") + (words.count >= 6 ? "..." : "")
    }

    private func saveContext() {
        do {
            try context.save()
        } catch {
            print("Failed to save context: \(error)")
        }
    }

    private func generateEmbedding(for entry: Entry) {
        Task {
            let embeddingService = EmbeddingService()
            await embeddingService.generateEmbedding(for: entry)
        }
    }
}