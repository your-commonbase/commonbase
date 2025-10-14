import SwiftUI
import CoreData

struct LedgerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Entry.createdAt, ascending: false)],
        animation: .default)
    private var entries: FetchedResults<Entry>

    @State private var selectedEntry: Entry? = nil
    @State private var showingDetail = false

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(entries, id: \.id) { entry in
                    LedgerRowView(entry: entry)
                        .onTapGesture {
                            selectedEntry = entry
                            showingDetail = true
                        }
                }
                .onDelete(perform: deleteEntries)
            }
            .navigationTitle("Ledger")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: addSampleEntry) {
                        Label("Add Entry", systemImage: "plus")
                    }
                }
            }
        } detail: {
            if let selectedEntry = selectedEntry {
                EntryDetailView(entry: selectedEntry)
            } else {
                Text("Select an entry to view details")
                    .foregroundColor(.secondary)
            }
        }
        .sheet(isPresented: $showingDetail) {
            if let selectedEntry = selectedEntry {
                EntryDetailView(entry: selectedEntry)
                    .frame(minWidth: 600, minHeight: 400)
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

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.title ?? "Untitled")
                        .font(.headline)
                        .lineLimit(1)

                    Text(entry.content.prefix(100))
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

                        Text(entry.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if entry.contentType == "image" {
                    Image(systemName: "photo")
                        .foregroundColor(.blue)
                } else {
                    Image(systemName: "text.alignleft")
                        .foregroundColor(.green)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    LedgerView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}