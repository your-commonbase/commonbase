import Foundation
import CoreData
import AppKit
import ScreenCaptureKit
import UserNotifications

class DataCaptureService: ObservableObject {
    private let context = PersistenceController.shared.container.viewContext

    func saveText(_ text: String, context: ApplicationContext) {
        print("💾 DataCaptureService.saveText() called")
        print("📱 App context: \(context.name) (\(context.bundleId))")
        print("🔗 URL from context: \(context.url ?? "nil")")
        print("📝 Text preview: \(String(text.prefix(50)))")

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

        // Ensure URL is in metadata as well
        if let url = context.url {
            metadata["url"] = url
            print("✅ Added URL to metadata: \(url)")
        } else {
            print("❌ No URL to add to metadata")
        }

        entry.metadata = metadata

        saveContext()
        generateEmbedding(for: entry)

        // Show notification
        DispatchQueue.main.async {
            self.showNotification("Text saved to Commonbase", subtitle: String(text.prefix(50)) + (text.count > 50 ? "..." : ""))
        }
    }

    func saveImage(_ image: NSImage, context: ApplicationContext) {
        print("💾 DataCaptureService.saveImage() called")
        print("📱 App context: \(context.name) (\(context.bundleId))")
        print("🔗 URL from context: \(context.url ?? "nil")")

        // Ensure we're on the main thread for Core Data operations
        DispatchQueue.main.async {
            let entry = Entry(context: self.context)
            entry.id = UUID()
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

            // Ensure URL is in metadata as well
            if let url = context.url {
                metadata["url"] = url
                print("✅ Added URL to metadata: \(url)")
            } else {
                print("❌ No URL to add to metadata")
            }

            entry.metadata = metadata

            // Save the entry first without transcription
            self.saveContext()

            // Transcribe image using OpenAI Vision API
            Task {
                do {
                    let transcription = try await self.transcribeImage(image)
                    await MainActor.run {
                        entry.content = transcription
                        self.saveContext()
                        self.generateEmbedding(for: entry)
                        self.showNotification("Image saved to Commonbase", subtitle: "Image transcribed and saved")
                    }
                } catch {
                    print("❌ Failed to transcribe image: \(error)")
                    // Fallback to basic description
                    await MainActor.run {
                        entry.content = "Screenshot captured from \(context.name)"
                        self.saveContext()
                        self.generateEmbedding(for: entry)
                        self.showNotification("Image saved to Commonbase", subtitle: "Screenshot saved without transcription")
                    }
                }
            }
        }
    }

    func captureScreenArea(completion: @escaping (NSImage?) -> Void) {
        print("📸 Starting area screenshot capture...")
        DispatchQueue.main.async {
            self.showAreaSelectionUI(completion: completion)
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
        // Create a selection overlay window
        let selectionWindow = ScreenSelectionWindow { selectedRect in
            guard let selectedRect = selectedRect else {
                completion(nil)
                return
            }

            guard let cgImage = CGWindowListCreateImage(
                selectedRect,
                .optionOnScreenOnly,
                kCGNullWindowID,
                .bestResolution
            ) else {
                completion(nil)
                return
            }

            let image = NSImage(cgImage: cgImage, size: selectedRect.size)
            completion(image)
        }

        selectionWindow.makeKeyAndOrderFront(nil)
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

    private func transcribeImage(_ image: NSImage) async throws -> String {
        let apiKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""

        guard !apiKey.isEmpty else {
            throw NSError(domain: "OpenAI", code: -1, userInfo: [NSLocalizedDescriptionKey: "OpenAI API key not configured. Please set it in Settings."])
        }

        // Convert NSImage to base64 JPEG
        guard let imageData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: imageData),
              let jpegData = bitmap.representation(using: .jpeg, properties: [:]) else {
            throw NSError(domain: "ImageProcessing", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image to JPEG"])
        }

        let base64Image = jpegData.base64EncodedString()

        let requestBody: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": "Describe this image in detail. Focus on the main content, text, and any important visual elements. If there's text in the image, transcribe it accurately."
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 500
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw NSError(domain: "JSONSerialization", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize request"])
        }

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/chat/completions")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "Network", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }

        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "OpenAI", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "OpenAI API error (\(httpResponse.statusCode)): \(errorMessage)"])
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw NSError(domain: "JSONParsing", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse OpenAI response"])
        }

        return content
    }

    private func showAreaSelectionUI(completion: @escaping (NSImage?) -> Void) {
        print("🖼️ Showing area selection UI...")

        let selectionWindow = ScreenSelectionWindow { rect in
            if let rect = rect, rect.width > 10 && rect.height > 10 {
                print("📐 Selected area: \(rect)")
                self.captureArea(rect: NSRect(x: rect.origin.x, y: rect.origin.y, width: rect.size.width, height: rect.size.height), completion: completion)
            } else {
                print("❌ Selection cancelled or too small")
                completion(nil)
            }
        }

        selectionWindow.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func captureArea(rect: NSRect, completion: @escaping (NSImage?) -> Void) {
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

    private func generateEmbedding(for entry: Entry) {
        print("🚀 DataCaptureService: Starting embedding generation for entry '\(entry.title ?? "Untitled")' with ID: \(entry.id?.uuidString ?? "NO ID")")
        print("📝 Entry content preview: \(String(entry.content?.prefix(50) ?? "NO CONTENT"))")

        Task {
            let embeddingService = EmbeddingService()
            await embeddingService.generateEmbedding(for: entry)
            print("🏁 DataCaptureService: Completed embedding generation for entry '\(entry.title ?? "Untitled")'")
        }
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