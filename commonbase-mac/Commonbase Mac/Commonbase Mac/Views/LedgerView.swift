import SwiftUI
import CoreData

struct LedgerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.createdAt, ascending: false)],
        animation: .default)
    private var entries: FetchedResults<Entry>

    @State private var selectedEntry: Entry? = nil
    @State private var isGeneratingEmbeddings = false
    @State private var isRegeneratingEmbedding = false

    // Keyboard shortcut preferences
    @AppStorage("shortcut_generate_embeddings") private var generateEmbeddingsShortcut: String = "⌘E"
    @AppStorage("shortcut_regenerate_embedding") private var regenerateEmbeddingShortcut: String = "⌘R"
    @AppStorage("shortcut_delete_entry") private var deleteEntryShortcut: String = "⌫"
    @AppStorage("shortcut_next_entry") private var nextEntryShortcut: String = "↓"
    @AppStorage("shortcut_previous_entry") private var previousEntryShortcut: String = "↑"

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedEntry) {
                ForEach(entries, id: \.id) { entry in
                    LedgerRowView(entry: entry, isSelected: selectedEntry?.id == entry.id)
                        .tag(entry)
                }
                .onDelete(perform: deleteEntries)
            }
            .navigationTitle("Ledger (\(entries.count) entries)")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Generate Embeddings") {
                        generateEmbeddings()
                    }
                    .disabled(isGeneratingEmbeddings)

                    if isGeneratingEmbeddings {
                        ProgressView()
                            .scaleEffect(0.8)
                    }

                    Button(action: addSampleEntry) {
                        Label("Add Entry", systemImage: "plus")
                    }
                }
            }
            .focusedSceneValue(\.selectedEntry, selectedEntry)
        } detail: {
            if let selectedEntry = selectedEntry {
                EntryDetailView(entry: selectedEntry)
            } else {
                Text("Select an entry to view details")
                    .foregroundColor(.secondary)
            }
        }
        .onAppear {
            if selectedEntry == nil && !entries.isEmpty {
                selectedEntry = entries.first
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("GenerateEmbeddings"))) { _ in
            generateEmbeddings()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RegenerateEmbedding"))) { _ in
            if let selectedEntry = selectedEntry {
                regenerateEmbedding(for: selectedEntry)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("DeleteEntry"))) { _ in
            if let selectedEntry = selectedEntry {
                deleteEntry(selectedEntry)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NextEntry"))) { _ in
            selectNextEntry()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("PreviousEntry"))) { _ in
            selectPreviousEntry()
        }
    }

    private func generateEmbeddings() {
        print("🔄 LedgerView: Starting bulk embedding generation for \(entries.count) entries")
        isGeneratingEmbeddings = true

        Task {
            let embeddingService = EmbeddingService()
            let entriesArray = Array(entries)
            await embeddingService.generateEmbeddings(for: entriesArray)
            print("✅ LedgerView: Completed bulk embedding generation")

            await MainActor.run {
                isGeneratingEmbeddings = false
            }
        }
    }

    private func addSampleEntry() {
        withAnimation {
            let newEntry = Entry(context: viewContext)
            newEntry.id = UUID()
            newEntry.content = "Sample entry created at \(Date().formatted())"
            newEntry.title = "Sample Entry"
            newEntry.contentType = "text"
            newEntry.createdAt = Date()
            newEntry.updatedAt = Date()

            do {
                try viewContext.save()
            } catch {
                print("Error saving new entry: \(error)")
            }
        }
    }

    private func regenerateEmbedding(for entry: Entry) {
        print("🔄 Regenerating embedding for entry: '\(entry.title ?? "Untitled")'")
        isRegeneratingEmbedding = true

        Task {
            let embeddingService = EmbeddingService()
            await embeddingService.generateEmbedding(for: entry)

            await MainActor.run {
                isRegeneratingEmbedding = false
            }
        }
    }

    private func deleteEntry(_ entry: Entry) {
        withAnimation {
            // Select next entry before deleting
            if let currentIndex = entries.firstIndex(of: entry) {
                let nextIndex = currentIndex < entries.count - 1 ? currentIndex + 1 : currentIndex - 1
                selectedEntry = nextIndex >= 0 ? entries[nextIndex] : nil
            }

            viewContext.delete(entry)

            do {
                try viewContext.save()
            } catch {
                print("Error deleting entry: \(error)")
            }
        }
    }

    private func selectNextEntry() {
        guard let currentEntry = selectedEntry,
              let currentIndex = entries.firstIndex(of: currentEntry),
              currentIndex < entries.count - 1 else { return }

        selectedEntry = entries[currentIndex + 1]
    }

    private func selectPreviousEntry() {
        guard let currentEntry = selectedEntry,
              let currentIndex = entries.firstIndex(of: currentEntry),
              currentIndex > 0 else { return }

        selectedEntry = entries[currentIndex - 1]
    }

    private func deleteEntries(offsets: IndexSet) {
        withAnimation {
            offsets.map { entries[$0] }.forEach(viewContext.delete)

            do {
                try viewContext.save()
            } catch {
                print("Error deleting entries: \(error)")
            }
        }
    }
}

struct LedgerRowView: View {
    let entry: Entry
    let isSelected: Bool

    private var hasEmbedding: Bool {
        (entry.embeddings?.count ?? 0) > 0
    }

    private var embeddingCount: Int {
        entry.embeddings?.count ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(entry.title ?? "Untitled")
                            .font(.headline)
                            .lineLimit(1)

                        Spacer()

                        // Embedding status indicator
                        HStack(spacing: 4) {
                            if hasEmbedding {
                                Image(systemName: "brain.head.profile")
                                    .foregroundColor(.green)
                                    .font(.caption)
                                if embeddingCount > 1 {
                                    Text("\(embeddingCount)")
                                        .font(.caption2)
                                        .foregroundColor(.green)
                                }
                            } else {
                                Image(systemName: "brain.head.profile")
                                    .foregroundColor(.gray)
                                    .font(.caption)
                            }

                            if entry.contentType == "image" {
                                Image(systemName: "photo")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                            } else {
                                Image(systemName: "text.alignleft")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            }
                        }
                    }

                    Text(entry.content?.prefix(100) ?? "")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    HStack {
                        if let app = entry.sourceApplication {
                            Text(app)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if hasEmbedding, let embedding = entry.embeddings?.first(where: { _ in true }) as? EntryEmbedding {
                            Text("Embedded: \(embedding.model ?? "unknown")")
                                .font(.caption2)
                                .foregroundColor(.green)
                        }

                        Text(entry.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown date")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(4)
    }
}

#Preview {
    LedgerView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}