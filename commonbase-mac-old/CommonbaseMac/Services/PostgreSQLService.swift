import Foundation
import CoreData

// PostgreSQL integration service for future implementation
// This would connect to the same database as Commonbase Next
class PostgreSQLService {
    private let connectionString: String
    private var isConnected = false

    init() {
        // Read connection string from environment or user defaults
        if let connString = ProcessInfo.processInfo.environment["DATABASE_URL"] {
            self.connectionString = connString
        } else if let connString = UserDefaults.standard.string(forKey: "database_url") {
            self.connectionString = connString
        } else {
            self.connectionString = ""
            print("Warning: No database connection string found. Set DATABASE_URL environment variable or in user defaults.")
        }
    }

    func connect() async -> Bool {
        guard !connectionString.isEmpty else {
            print("Cannot connect: No connection string configured")
            return false
        }

        // Implementation would use a PostgreSQL Swift client library
        // For now, return false to indicate we're using Core Data locally
        isConnected = false
        return isConnected
    }

    func syncEntry(_ entry: Entry) async -> Bool {
        guard isConnected else { return false }

        // Implementation would sync Core Data entries to PostgreSQL
        // This would ensure data is shared between the Mac app and web interface
        return false
    }

    func syncEmbedding(_ embedding: EntryEmbedding) async -> Bool {
        guard isConnected else { return false }

        // Implementation would sync embeddings to pgvector
        return false
    }

    func fetchEntriesFromRemote() async -> [RemoteEntry] {
        guard isConnected else { return [] }

        // Implementation would fetch entries from PostgreSQL
        return []
    }
}

// Temporary struct for remote entries
struct RemoteEntry {
    let id: UUID
    let data: String
    let metadata: [String: Any]
    let created: Date
    let updated: Date
}

// MARK: - Settings and Configuration

class CommonbaseSettings: ObservableObject {
    @Published var openAIAPIKey: String {
        didSet {
            UserDefaults.standard.set(openAIAPIKey, forKey: "openai_api_key")
        }
    }

    @Published var databaseURL: String {
        didSet {
            UserDefaults.standard.set(databaseURL, forKey: "database_url")
        }
    }

    @Published var syncEnabled: Bool {
        didSet {
            UserDefaults.standard.set(syncEnabled, forKey: "sync_enabled")
        }
    }

    init() {
        self.openAIAPIKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
        self.databaseURL = UserDefaults.standard.string(forKey: "database_url") ?? ""
        self.syncEnabled = UserDefaults.standard.bool(forKey: "sync_enabled")
    }
}