import Foundation
import CoreData

struct OpenAIEmbeddingResponse: Codable {
    let data: [EmbeddingData]
    let model: String
    let usage: Usage

    struct EmbeddingData: Codable {
        let embedding: [Float]
        let index: Int
    }

    struct Usage: Codable {
        let prompt_tokens: Int
        let total_tokens: Int
    }
}

class EmbeddingService {
    private let apiKey: String
    private let baseURL = "https://api.openai.com/v1/embeddings"

    init() {
        // Read API key from environment or user defaults
        if let key = ProcessInfo.processInfo.environment["OPENAI_API_KEY"] {
            self.apiKey = key
        } else if let key = UserDefaults.standard.string(forKey: "openai_api_key") {
            self.apiKey = key
        } else {
            self.apiKey = ""
            print("Warning: No OpenAI API key found. Set OPENAI_API_KEY environment variable or in user defaults.")
        }
    }

    func generateEmbedding(for entry: Entry) async {
        guard !apiKey.isEmpty else {
            print("Cannot generate embedding: No API key configured")
            return
        }

        let text = entry.content
        guard !text.isEmpty else { return }

        do {
            let embedding = try await requestEmbedding(text: text)
            await saveEmbedding(embedding, for: entry)
        } catch {
            print("Failed to generate embedding: \(error)")
        }
    }

    func generateEmbeddings(for entries: [Entry]) async {
        guard !apiKey.isEmpty else {
            print("Cannot generate embeddings: No API key configured")
            return
        }

        for entry in entries {
            await generateEmbedding(for: entry)
            // Add small delay to avoid rate limiting
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
    }

    func searchSimilar(to query: String, limit: Int = 10) async -> [Entry] {
        guard !apiKey.isEmpty else {
            print("Cannot search: No API key configured")
            return []
        }

        do {
            let queryEmbedding = try await requestEmbedding(text: query)
            return await findSimilarEntries(embedding: queryEmbedding, limit: limit)
        } catch {
            print("Failed to search similar entries: \(error)")
            return []
        }
    }

    private func requestEmbedding(text: String) async throws -> [Float] {
        guard let url = URL(string: baseURL) else {
            throw EmbeddingError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let requestBody = [
            "input": text,
            "model": "text-embedding-3-small"
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(OpenAIEmbeddingResponse.self, from: data)

        guard let embedding = response.data.first?.embedding else {
            throw EmbeddingError.noEmbeddingReturned
        }

        return embedding
    }

    private func saveEmbedding(_ embedding: [Float], for entry: Entry) async {
        await MainActor.run {
            let context = PersistenceController.shared.container.viewContext

            let entryEmbedding = EntryEmbedding(context: context)
            entryEmbedding.id = UUID()
            entryEmbedding.embedding = embedding
            entryEmbedding.model = "text-embedding-3-small"
            entryEmbedding.createdAt = Date()
            entryEmbedding.entry = entry

            do {
                try context.save()
            } catch {
                print("Failed to save embedding: \(error)")
            }
        }
    }

    private func findSimilarEntries(embedding: [Float], limit: Int) async -> [Entry] {
        return await MainActor.run {
            let context = PersistenceController.shared.container.viewContext

            let request: NSFetchRequest<EntryEmbedding> = EntryEmbedding.fetchRequest()

            do {
                let embeddings = try context.fetch(request)
                let similarities = embeddings.compactMap { entryEmbedding -> (Entry, Double)? in
                    guard let entry = entryEmbedding.entry else { return nil }
                    let similarity = cosineSimilarity(embedding, entryEmbedding.embedding)
                    return (entry, similarity)
                }

                let sortedEntries = similarities
                    .sorted { $0.1 > $1.1 }
                    .prefix(limit)
                    .map { $0.0 }

                return Array(sortedEntries)
            } catch {
                print("Failed to fetch embeddings for similarity search: \(error)")
                return []
            }
        }
    }

    private func cosineSimilarity(_ a: [Float], _ b: [Float]) -> Double {
        guard a.count == b.count else { return 0.0 }

        var dotProduct: Float = 0
        var normA: Float = 0
        var normB: Float = 0

        for i in 0..<a.count {
            dotProduct += a[i] * b[i]
            normA += a[i] * a[i]
            normB += b[i] * b[i]
        }

        let denominator = sqrt(normA) * sqrt(normB)
        return denominator > 0 ? Double(dotProduct / denominator) : 0.0
    }
}

enum EmbeddingError: Error {
    case invalidURL
    case noEmbeddingReturned
    case apiError(String)
}