import SwiftUI
import CoreData

struct SearchView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var searchText = ""
    @State private var searchResults: [Entry] = []
    @State private var isSearching = false
    @State private var searchMode: SearchMode = .fullText
    @State private var selectedEntry: Entry? = nil

    enum SearchMode: String, CaseIterable {
        case fullText = "Full Text"
        case semantic = "Semantic"
        case hybrid = "Hybrid"
    }

    var body: some View {
        VStack(spacing: 0) {
            // Search header
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search your entries...", text: $searchText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            performSearch()
                        }

                    if isSearching {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }

                Picker("Search Mode", selection: $searchMode) {
                    ForEach(SearchMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))

            Divider()

            // Results
            if searchText.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Enter a search query to find entries")
                        .foregroundColor(.secondary)
                        .font(.title2)
                    Spacer()
                }
            } else if searchResults.isEmpty && !isSearching {
                VStack {
                    Spacer()
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No results found")
                        .foregroundColor(.secondary)
                        .font(.title2)
                    Text("Try a different search term or search mode")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List {
                    ForEach(searchResults, id: \.id) { entry in
                        SearchResultRow(entry: entry, searchText: searchText)
                            .onTapGesture {
                                selectedEntry = entry
                            }
                    }
                }
            }
        }
        .onChange(of: searchText) { _, newValue in
            if !newValue.isEmpty {
                // Debounce search
                Task {
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    if searchText == newValue {
                        performSearch()
                    }
                }
            } else {
                searchResults = []
            }
        }
        .onChange(of: searchMode) { _, _ in
            if !searchText.isEmpty {
                performSearch()
            }
        }
        .sheet(item: $selectedEntry) { entry in
            EntryDetailView(entry: entry)
                .frame(minWidth: 600, minHeight: 400)
        }
    }

    private func performSearch() {
        guard !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            searchResults = []
            return
        }

        isSearching = true

        Task {
            let results = await executeSearch(query: searchText, mode: searchMode)
            await MainActor.run {
                self.searchResults = results
                self.isSearching = false
            }
        }
    }

    private func executeSearch(query: String, mode: SearchMode) async -> [Entry] {
        switch mode {
        case .fullText:
            return performFullTextSearch(query: query)
        case .semantic:
            return await performSemanticSearch(query: query)
        case .hybrid:
            return await performHybridSearch(query: query)
        }
    }

    private func performFullTextSearch(query: String) -> [Entry] {
        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        request.predicate = NSPredicate(format: "content CONTAINS[cd] %@", query)
        request.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

        do {
            return try viewContext.fetch(request)
        } catch {
            print("Full text search error: \(error)")
            return []
        }
    }

    private func performSemanticSearch(query: String) async -> [Entry] {
        let embeddingService = EmbeddingService()
        return await embeddingService.searchSimilar(to: query, limit: 50)
    }

    private func performHybridSearch(query: String) async -> [Entry] {
        // Combine both search methods
        let fullTextResults = performFullTextSearch(query: query)
        let semanticResults = await performSemanticSearch(query: query)

        // Merge and deduplicate results
        var combinedResults: [Entry] = []
        var seenIds: Set<UUID> = []

        // Add full text results first
        for entry in fullTextResults {
            if let entryId = entry.id, !seenIds.contains(entryId) {
                combinedResults.append(entry)
                seenIds.insert(entryId)
            }
        }

        // Add semantic results
        for entry in semanticResults {
            if let entryId = entry.id, !seenIds.contains(entryId) {
                combinedResults.append(entry)
                seenIds.insert(entryId)
            }
        }

        return combinedResults
    }
}

struct SearchResultRow: View {
    let entry: Entry
    let searchText: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.title ?? "Untitled")
                        .font(.headline)
                        .lineLimit(1)

                    Text(highlightedContent)
                        .font(.body)
                        .lineLimit(3)

                    HStack {
                        if let app = entry.sourceApplication {
                            Label(app, systemImage: "app")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(entry.createdAt?.formatted(date: .abbreviated, time: .shortened) ?? "Unknown date")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack {
                    if entry.contentType == "image" {
                        Image(systemName: "photo")
                            .foregroundColor(.blue)
                    } else {
                        Image(systemName: "text.alignleft")
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }

    private var highlightedContent: String {
        guard let content = entry.content else { return "" }
        guard !searchText.isEmpty else { return String(content.prefix(200)) }

        // Simple highlighting - in a real app, you might want more sophisticated highlighting
        let range = content.range(of: searchText, options: .caseInsensitive)
        if let range = range {
            let start = max(content.startIndex, content.index(range.lowerBound, offsetBy: -50, limitedBy: content.startIndex) ?? content.startIndex)
            let end = min(content.endIndex, content.index(range.upperBound, offsetBy: 150, limitedBy: content.endIndex) ?? content.endIndex)
            return String(content[start..<end])
        }

        return String(content.prefix(200))
    }
}


#Preview {
    SearchView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}