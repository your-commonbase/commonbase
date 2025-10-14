import SwiftUI
import CoreData

struct GraphView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \Entry.createdAt, ascending: false)])
    private var entries: FetchedResults<Entry>

    @State private var graphData: [GraphNode] = []
    @State private var isLoading = false
    @State private var selectedNode: GraphNode? = nil
    @State private var selectedEntry: Entry? = nil

    var body: some View {
        VStack {
            if isLoading {
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                    Text("Generating graph visualization...")
                        .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if graphData.isEmpty {
                VStack {
                    Image(systemName: "point.3.connected.trianglepath.dotted")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No entries with embeddings found")
                        .font(.title2)
                        .foregroundColor(.secondary)
                    Text("Add some content to see the relationship graph")
                        .foregroundColor(.secondary)
                    Button("Generate Embeddings") {
                        generateEmbeddings()
                    }
                    .padding(.top)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                GeometryReader { geometry in
                    GraphCanvas(
                        nodes: graphData,
                        size: geometry.size,
                        selectedNode: $selectedNode
                    )
                    .onTapGesture { location in
                        if let node = findNode(at: location, in: geometry.size) {
                            selectedNode = node
                            selectedEntry = entries.first { $0.id == node.entryId }
                        }
                    }
                }
            }
        }
        .navigationTitle("Graph")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Refresh") {
                    loadGraphData()
                }
            }
        }
        .onAppear {
            loadGraphData()
        }
        .sheet(item: $selectedEntry) { entry in
            EntryDetailView(entry: entry)
                .frame(minWidth: 600, minHeight: 400)
        }
    }

    private func loadGraphData() {
        isLoading = true

        Task {
            let nodes = await generateGraphNodes()
            await MainActor.run {
                self.graphData = nodes
                self.isLoading = false
            }
        }
    }

    private func generateEmbeddings() {
        isLoading = true

        Task {
            let embeddingService = EmbeddingService()
            let entriesArray = Array(entries)
            await embeddingService.generateEmbeddings(for: entriesArray)

            await MainActor.run {
                loadGraphData()
            }
        }
    }

    private func generateGraphNodes() async -> [GraphNode] {
        let entriesWithEmbeddings = entries.compactMap { entry -> (Entry, [Float])? in
            guard let embedding = entry.embeddings?.first(where: { _ in true }) as? EntryEmbedding else {
                return nil
            }
            return (entry, embedding.embedding)
        }

        guard entriesWithEmbeddings.count > 1 else { return [] }

        // Apply UMAP-like dimensionality reduction (simplified version)
        let positions = await reduceTo2D(embeddings: entriesWithEmbeddings.map { $0.1 })

        return zip(entriesWithEmbeddings, positions).map { (entryEmbedding, position) in
            let (entry, _) = entryEmbedding
            return GraphNode(
                id: entry.id,
                entryId: entry.id,
                title: entry.title ?? "Untitled",
                content: String(entry.content.prefix(100)),
                x: position.x,
                y: position.y,
                contentType: entry.contentType
            )
        }
    }

    private func reduceToShortString(_ text: String, maxLength: Int = 50) -> String {
        if text.count <= maxLength {
            return text
        }
        return String(text.prefix(maxLength - 3)) + "..."
    }

    private func reduceTo2D(embeddings: [[Float]]) async -> [CGPoint] {
        // Simplified 2D reduction using PCA-like approach
        // In a real implementation, you would use UMAP or t-SNE
        guard !embeddings.isEmpty else { return [] }

        let dimensions = embeddings[0].count
        var points: [CGPoint] = []

        // Simple projection to first two principal components (approximated)
        for embedding in embeddings {
            let x = embedding.prefix(dimensions/2).reduce(0, +) / Float(dimensions/2)
            let y = embedding.suffix(dimensions/2).reduce(0, +) / Float(dimensions/2)

            let normalizedX = (CGFloat(x) + 1.0) * 0.5
            let normalizedY = (CGFloat(y) + 1.0) * 0.5

            points.append(CGPoint(x: normalizedX, y: normalizedY))
        }

        return points
    }

    private func findNode(at location: CGPoint, in size: CGSize) -> GraphNode? {
        let nodeRadius: CGFloat = 8
        return graphData.first { node in
            let nodeX = node.x * size.width
            let nodeY = node.y * size.height
            let distance = sqrt(pow(location.x - nodeX, 2) + pow(location.y - nodeY, 2))
            return distance <= nodeRadius
        }
    }
}

struct GraphNode: Identifiable {
    let id: UUID
    let entryId: UUID
    let title: String
    let content: String
    let x: CGFloat
    let y: CGFloat
    let contentType: String
}

struct GraphCanvas: View {
    let nodes: [GraphNode]
    let size: CGSize
    @Binding var selectedNode: GraphNode?

    var body: some View {
        Canvas { context, size in
            // Draw connections between similar nodes
            drawConnections(context: context, size: size)

            // Draw nodes
            for node in nodes {
                drawNode(context: context, node: node, size: size)
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
    }

    private func drawConnections(context: GraphicsContext, size: CGSize) {
        let threshold: CGFloat = 0.1 // Distance threshold for connections

        for i in 0..<nodes.count {
            for j in (i+1)..<nodes.count {
                let node1 = nodes[i]
                let node2 = nodes[j]

                let distance = sqrt(pow(node1.x - node2.x, 2) + pow(node1.y - node2.y, 2))
                if distance < threshold {
                    let start = CGPoint(x: node1.x * size.width, y: node1.y * size.height)
                    let end = CGPoint(x: node2.x * size.width, y: node2.y * size.height)

                    var path = Path()
                    path.move(to: start)
                    path.addLine(to: end)

                    context.stroke(path, with: .color(.secondary.opacity(0.3)), lineWidth: 1)
                }
            }
        }
    }

    private func drawNode(context: GraphicsContext, node: GraphNode, size: CGSize) {
        let x = node.x * size.width
        let y = node.y * size.height
        let radius: CGFloat = 8

        let isSelected = selectedNode?.id == node.id
        let color: Color = {
            if isSelected {
                return .accentColor
            } else if node.contentType == "image" {
                return .blue
            } else {
                return .green
            }
        }()

        // Draw node
        let nodeRect = CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)
        context.fill(Path(ellipseIn: nodeRect), with: .color(color))

        // Draw border
        context.stroke(Path(ellipseIn: nodeRect), with: .color(.primary), lineWidth: isSelected ? 2 : 1)

        // Draw label for selected node
        if isSelected {
            let text = Text(node.title)
                .font(.caption)
                .foregroundColor(.primary)

            context.draw(text, at: CGPoint(x: x, y: y + radius + 10))
        }
    }
}

#Preview {
    GraphView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}