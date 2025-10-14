import SwiftUI
import AppKit

struct EntryDetailView: View {
    let entry: Entry
    @Environment(\.dismiss) private var dismiss
    @State private var isRegeneratingEmbedding = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text(entry.title ?? "Untitled")
                            .font(.title2)
                            .fontWeight(.semibold)

                        HStack {
                            if let app = entry.sourceApplication {
                                Label(app, systemImage: "app")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Text(entry.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown date")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Spacer()

                    HStack {
                        Button(isRegeneratingEmbedding ? "Regenerating..." : "Regenerate Embedding") {
                            regenerateEmbedding()
                        }
                        .disabled(isRegeneratingEmbedding)

                        if isRegeneratingEmbedding {
                            ProgressView()
                                .scaleEffect(0.8)
                        }

                        Button("Open Source") {
                            openSource()
                        }
                        .disabled(getSourceURL() == nil)
                    }
                }

                Divider()

                // Content
                if entry.contentType == "image", let imageData = entry.imageData {
                    if let nsImage = NSImage(data: imageData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 400)
                            .cornerRadius(8)
                    }
                } else {
                    Text(entry.content ?? "")
                        .font(.body)
                        .textSelection(.enabled)
                        .padding()
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                }

                // Metadata
                if let metadata = entry.metadata as? [String: Any], !metadata.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Metadata")
                            .font(.headline)

                        ForEach(Array(metadata.keys).sorted(), id: \.self) { key in
                            HStack {
                                Text(key)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(metadata[key] ?? "")")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                }

                // Similar entries
                SimilarEntriesView(currentEntry: entry)

                Spacer()
            }
            .padding()
        }
        .frame(minWidth: 500, minHeight: 400)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }

    private func regenerateEmbedding() {
        isRegeneratingEmbedding = true

        Task {
            let embeddingService = EmbeddingService()
            await embeddingService.generateEmbedding(for: entry)

            await MainActor.run {
                isRegeneratingEmbedding = false
            }
        }
    }

    private func getSourceURL() -> String? {
        // First check for sourceURL property
        if let sourceURL = entry.sourceURL, !sourceURL.isEmpty {
            return sourceURL
        }

        // Check metadata for URL
        if let metadata = entry.metadata as? [String: Any], !metadata.isEmpty,
           let url = metadata["url"] as? String, !url.isEmpty {
            return url
        }

        return nil
    }

    private func openSource() {
        guard let urlString = getSourceURL(),
              let url = URL(string: urlString) else {
            print("❌ No source URL found for entry")
            return
        }

        print("🔗 Opening source URL: \(urlString)")

        if urlString.hasPrefix("file://") {
            // Open file in default application
            NSWorkspace.shared.open(url)
        } else if urlString.hasPrefix("http") {
            // Open URL in default browser
            NSWorkspace.shared.open(url)
        } else {
            // Try to open as file path
            let fileURL = URL(fileURLWithPath: urlString)
            NSWorkspace.shared.open(fileURL)
        }
    }
}

struct SimilarEntriesView: View {
    let currentEntry: Entry
    @State private var similarEntries: [Entry] = []
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Similar Entries")
                    .font(.headline)

                Spacer()

                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }

            if similarEntries.isEmpty && !isLoading {
                Text("No similar entries found")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                LazyVStack(spacing: 8) {
                    ForEach(similarEntries, id: \.id) { similarEntry in
                        Button(action: {
                            // Copy entry content to clipboard for now
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(similarEntry.content ?? "", forType: .string)
                            print("📋 Copied similar entry content to clipboard")
                        }) {
                            SimilarEntryRow(entry: similarEntry)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .task {
            await loadSimilarEntries()
        }
    }

    private func loadSimilarEntries() async {
        isLoading = true
        let embeddingService = EmbeddingService()
        let results = await embeddingService.searchSimilar(to: currentEntry.content ?? "", limit: 5)

        await MainActor.run {
            self.similarEntries = results.filter { $0.id != currentEntry.id }
            self.isLoading = false
        }
    }
}

struct SimilarEntryRow: View {
    let entry: Entry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title ?? "Untitled")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(entry.content?.prefix(80) ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(entry.createdAt?.formatted(date: .abbreviated, time: .omitted) ?? "Unknown date")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.clear)
        )
        .contentShape(Rectangle())
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let entry = Entry(context: context)
    entry.id = UUID()
    entry.content = "This is a sample entry for preview"
    entry.title = "Sample Entry"
    entry.contentType = "text"
    entry.createdAt = Date()
    entry.updatedAt = Date()
    entry.sourceApplication = "Xcode"

    return EntryDetailView(entry: entry)
}