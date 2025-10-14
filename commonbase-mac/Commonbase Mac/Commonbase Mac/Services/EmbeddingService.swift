import Foundation
import CoreData
import NaturalLanguage

class EmbeddingService {
    private let context = PersistenceController.shared.container.viewContext

    init() {
        print("Using OpenAI embeddings API")
    }

    func generateEmbedding(for entry: Entry) async {
        let text = entry.content
        guard let text = text, !text.isEmpty else {
            print("❌ Cannot generate embedding: No text content for entry '\(entry.title ?? "Untitled")'")
            return
        }

        print("🧠 Generating on-device embedding for entry: '\(entry.title ?? "Untitled")'")
        print("📝 Text content: \(String(text.prefix(100)))...")

        await generateAndSaveEmbedding(text: text, for: entry)
    }

    func generateEmbeddings(for entries: [Entry]) async {
        print("Generating embeddings for \(entries.count) entries using Natural Language framework")

        for entry in entries {
            await generateEmbedding(for: entry)
        }
    }

    private func generateAndSaveEmbedding(text: String, for entry: Entry) async {
        print("Generating OpenAI embedding")

        do {
            let vector = try await generateOpenAIEmbedding(from: text)
            let embeddingData = Data(bytes: vector, count: vector.count * MemoryLayout<Float>.size)

            await MainActor.run {
                saveEmbedding(embeddingData, for: entry)
                print("Successfully generated OpenAI embedding for entry: \(entry.title ?? "Untitled") (dimension: \(vector.count))")
            }
        } catch {
            print("❌ Failed to generate OpenAI embedding: \(error)")

            // Fallback to simple embedding if OpenAI fails
            print("🔄 Falling back to simple embedding")
            let vector = generateSimpleEmbedding(from: text)
            let embeddingData = Data(bytes: vector, count: vector.count * MemoryLayout<Float>.size)

            await MainActor.run {
                saveEmbedding(embeddingData, for: entry)
                print("Successfully generated fallback embedding for entry: \(entry.title ?? "Untitled") (dimension: \(vector.count))")
            }
        }
    }

    private func generateOpenAIEmbedding(from text: String) async throws -> [Float] {
        let apiKey = UserDefaults.standard.string(forKey: "openai_api_key") ?? ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? ""

        guard !apiKey.isEmpty else {
            throw NSError(domain: "OpenAI", code: -1, userInfo: [NSLocalizedDescriptionKey: "OpenAI API key not configured. Please set it in Settings."])
        }

        let requestBody: [String: Any] = [
            "model": "text-embedding-3-small",
            "input": text
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            throw NSError(domain: "JSONSerialization", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to serialize request"])
        }

        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/embeddings")!)
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
              let dataArray = json["data"] as? [[String: Any]],
              let firstItem = dataArray.first,
              let embedding = firstItem["embedding"] as? [Double] else {
            throw NSError(domain: "JSONParsing", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to parse OpenAI response"])
        }

        return embedding.map { Float($0) }
    }

    private func generateSimpleEmbedding(from text: String) -> [Float] {
        // Create a simple but effective embedding using character frequencies and n-grams
        let words = text.lowercased().components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        var features = [Float](repeating: 0.0, count: 128) // Fixed dimension

        // Word frequency features
        let wordCounts = words.reduce(into: [String: Int]()) { counts, word in
            counts[word, default: 0] += 1
        }

        for (word, count) in wordCounts {
            let hash = abs(word.hashValue) % 64
            features[hash] += Float(count)
        }

        // Character n-gram features
        for i in 0..<min(text.count - 1, 64) {
            let startIndex = text.index(text.startIndex, offsetBy: i)
            let endIndex = text.index(startIndex, offsetBy: 2)
            if endIndex <= text.endIndex {
                let bigram = String(text[startIndex..<endIndex])
                let hash = abs(bigram.hashValue) % 64
                features[64 + hash] += 1.0
            }
        }

        // Normalize the vector
        let magnitude = sqrt(features.map { $0 * $0 }.reduce(0, +))
        if magnitude > 0 {
            for i in 0..<features.count {
                features[i] /= magnitude
            }
        }

        return features
    }

    @MainActor
    private func saveEmbedding(_ embeddingData: Data, for entry: Entry) {
        print("💾 Saving embedding for entry: '\(entry.title ?? "Untitled")' with ID: \(entry.id?.uuidString ?? "NO ID")")

        // Ensure we're using the same context as the entry
        guard let entryContext = entry.managedObjectContext else {
            print("❌ Entry has no managed object context")
            return
        }

        // Check if embedding already exists for this entry
        let fetchRequest: NSFetchRequest<EntryEmbedding> = EntryEmbedding.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "entry == %@", entry)

        let existingEmbedding = try? entryContext.fetch(fetchRequest).first
        print("🔍 Found existing embedding: \(existingEmbedding != nil)")

        let entryEmbedding: EntryEmbedding
        if let existing = existingEmbedding {
            print("♻️ Updating existing embedding")
            entryEmbedding = existing
        } else {
            print("✨ Creating new embedding")
            entryEmbedding = EntryEmbedding(context: entryContext)
            entryEmbedding.id = UUID()
            entryEmbedding.entry = entry
        }

        let embeddingVector = convertDataToFloatArray(embeddingData)
        entryEmbedding.embedding = embeddingVector
        entryEmbedding.model = "text-embedding-3-small"
        entryEmbedding.createdAt = Date()

        print("🔢 Embedding vector dimension: \(embeddingVector.count)")
        print("🔗 Entry has \(entry.embeddings?.count ?? 0) embeddings before save")

        do {
            try entryContext.save()
            print("✅ Successfully saved embedding to Core Data")

            // Verify the save worked
            let verifyRequest: NSFetchRequest<EntryEmbedding> = EntryEmbedding.fetchRequest()
            let allEmbeddings = try? entryContext.fetch(verifyRequest)
            print("📊 Total embeddings in database: \(allEmbeddings?.count ?? 0)")

            // Check this entry's embeddings
            entryContext.refresh(entry, mergeChanges: true)
            print("🔗 Entry now has \(entry.embeddings?.count ?? 0) embeddings after save")
        } catch {
            print("❌ Failed to save embedding: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
        }
    }

    func searchSimilar(to query: String, limit: Int = 10) async -> [Entry] {
        guard !query.isEmpty else {
            print("❌ Empty query provided to searchSimilar")
            return []
        }

        print("🔍 Performing on-device semantic search for: \"\(query)\"")

        // First, let's check how many total entries and embeddings exist using main context
        let mainContext = PersistenceController.shared.container.viewContext
        let allEntriesRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        let totalEntries = (try? mainContext.fetch(allEntriesRequest))?.count ?? 0
        print("📊 Total entries in database: \(totalEntries)")

        let allEmbeddingsRequest: NSFetchRequest<EntryEmbedding> = EntryEmbedding.fetchRequest()
        let totalEmbeddings = (try? mainContext.fetch(allEmbeddingsRequest))?.count ?? 0
        print("📊 Total embeddings in database: \(totalEmbeddings)")

        // Generate embedding for the query
        guard let queryVector = await generateQueryEmbedding(text: query) else {
            print("❌ Failed to generate query embedding")
            return []
        }

        print("✅ Generated query embedding with dimension: \(queryVector.count)")

        // Fetch all entries with embeddings using main context
        let fetchRequest: NSFetchRequest<Entry> = Entry.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "embeddings.@count > 0")

        guard let entries = try? mainContext.fetch(fetchRequest) else {
            print("❌ Failed to fetch entries with embeddings")
            return []
        }

        print("📊 Found \(entries.count) entries with embeddings out of \(totalEntries) total entries")

        // Calculate similarity scores
        var scoredResults: [(entry: Entry, score: Float)] = []

        for entry in entries {
            guard let embedding = entry.embeddings?.first(where: { _ in true }) as? EntryEmbedding,
                  let embeddingVector = embedding.embedding else {
                print("⚠️ Entry '\(entry.title ?? "Untitled")' has no valid embedding")
                continue
            }

            let similarity = cosineSimilarity(vectorA: queryVector, vectorB: embeddingVector)
            scoredResults.append((entry: entry, score: similarity))
            print("📈 Entry '\(entry.title ?? "Untitled")': similarity = \(similarity)")
        }

        // Sort by similarity and return top results
        scoredResults.sort { $0.score > $1.score }
        let results = Array(scoredResults.prefix(limit)).map { $0.entry }

        print("✅ Returning \(results.count) similar entries")
        if !results.isEmpty {
            print("🏆 Top result: '\(results[0].title ?? "Untitled")' with similarity: \(scoredResults[0].score)")
        }
        return results
    }

    private func generateQueryEmbedding(text: String) async -> [Float]? {
        do {
            return try await generateOpenAIEmbedding(from: text)
        } catch {
            print("❌ Failed to generate OpenAI query embedding, falling back to simple embedding: \(error)")
            return generateSimpleEmbedding(from: text)
        }
    }

    private func convertDataToFloatArray(_ data: Data) -> [Float] {
        return data.withUnsafeBytes { buffer in
            Array(buffer.bindMemory(to: Float.self))
        }
    }

    private func cosineSimilarity(vectorA: [Float], vectorB: [Float]) -> Float {
        guard vectorA.count == vectorB.count, !vectorA.isEmpty else { return 0.0 }

        let dotProduct = zip(vectorA, vectorB).map(*).reduce(0, +)
        let normA = sqrt(vectorA.map { $0 * $0 }.reduce(0, +))
        let normB = sqrt(vectorB.map { $0 * $0 }.reduce(0, +))

        guard normA > 0 && normB > 0 else { return 0.0 }

        return dotProduct / (normA * normB)
    }
}