# Commonbase Mac

A native macOS menu bar application for capturing and organizing knowledge using AI-powered embeddings and semantic search. Built with SwiftUI and inspired by the Commonbase Next web application.

## Features

### 🔍 **Global Right-Click Capture**
- **Text Capture**: Right-click anywhere with selected text to save it to your ledger
- **Screenshot Capture**: Right-click to capture selected screen areas or full screen
- **Context Awareness**: Automatically detects the source application, file paths, and URLs

### 📝 **Ledger Tab**
- View all captured entries in chronological order
- Rich preview with content, metadata, and source information
- Click entries to open detailed view with full content and context
- Delete and manage entries with swipe gestures

### 🔎 **Search Tab**
- **Full-Text Search**: Traditional keyword-based search through your content
- **Semantic Search**: AI-powered similarity search using OpenAI embeddings
- **Hybrid Search**: Combines both methods for comprehensive results
- Real-time search with debouncing and result highlighting

### 🌐 **Graph Tab**
- Visual representation of relationships between entries
- UMAP-based clustering to show semantic similarities
- Interactive nodes showing content type (text/image)
- Click nodes to view detailed entry information

### 🤖 **AI-Powered Features**
- OpenAI embeddings for semantic understanding
- Automatic similarity detection between entries
- Intelligent content clustering and visualization

## Requirements

- **macOS 14.0+** (for modern screen capture APIs)
- **Xcode 15.0+** for building
- **OpenAI API Key** for embedding generation
- **PostgreSQL with pgvector** (optional, for sync with Commonbase Next)

## Setup Instructions

### 1. Clone and Open Project
```bash
cd commonbase-mac
open CommonbaseMac.xcodeproj
```

### 2. Configure API Keys
Set your OpenAI API key using one of these methods:

**Option A: Environment Variable**
```bash
export OPENAI_API_KEY="your-api-key-here"
```

**Option B: User Defaults** (will be configurable in the app)
```bash
defaults write com.commonbase.mac openai_api_key "your-api-key-here"
```

### 3. Database Configuration (Optional)
To sync with Commonbase Next, configure PostgreSQL connection:
```bash
export DATABASE_URL="postgresql://user:password@host:port/database"
# or
defaults write com.commonbase.mac database_url "postgresql://user:password@host:port/database"
```

### 4. Build and Run
1. Open the project in Xcode
2. Select your development team for code signing
3. Build and run (⌘+R)

### 5. Grant Permissions
The app will request the following permissions:
- **Accessibility**: To detect active applications and get context
- **Screen Recording**: To capture screenshots
- **Apple Events**: To interact with other applications

## Architecture

### Core Components
- **CommonbaseMacApp.swift**: Main app delegate with menu bar setup
- **ContentView.swift**: Main tabbed interface
- **PersistenceController.swift**: Core Data stack management

### Data Models
- **Entry**: Main content entity with text, images, and metadata
- **EntryEmbedding**: Vector embeddings for semantic search

### Services
- **DataCaptureService**: Handles text selection and screenshot capture
- **EmbeddingService**: OpenAI API integration for generating embeddings
- **PostgreSQLService**: Database sync (future implementation)
- **EventMonitor**: Global event monitoring for right-click detection

### Views
- **LedgerView**: List and detail views for all entries
- **SearchView**: Multi-modal search interface
- **GraphView**: Interactive graph visualization with Canvas
- **EntryDetailView**: Detailed entry viewer with metadata

## Usage

### Capturing Content
1. **Text**: Select any text in any application, then right-click to save
2. **Screenshots**: Right-click anywhere to choose between area or full-screen capture

### Viewing Content
1. Click the Commonbase icon in the menu bar
2. Navigate between Ledger, Search, and Graph tabs
3. Click any entry to view details and similar content

### Searching
1. Go to Search tab
2. Enter your query
3. Choose search mode:
   - **Full Text**: Traditional keyword search
   - **Semantic**: AI-powered similarity search
   - **Hybrid**: Best of both methods

### Graph Visualization
1. Go to Graph tab
2. Click "Generate Embeddings" if needed
3. Explore the relationship network
4. Click nodes to view entry details

## Development Notes

### Key Files Structure
```
CommonbaseMac/
├── CommonbaseMacApp.swift          # Main app and menu bar setup
├── ContentView.swift               # Main UI container
├── Models/
│   ├── PersistenceController.swift # Core Data management
│   └── ApplicationContext.swift    # Context data structure
├── Services/
│   ├── DataCaptureService.swift   # Screen/text capture
│   ├── EmbeddingService.swift     # OpenAI integration
│   ├── EventMonitor.swift         # Global event handling
│   └── PostgreSQLService.swift    # Database sync
├── Views/
│   ├── LedgerView.swift           # Entry list and management
│   ├── SearchView.swift           # Multi-modal search
│   ├── GraphView.swift            # Interactive visualization
│   └── EntryDetailView.swift      # Entry detail modal
└── CommonbaseDataModel.xcdatamodeld # Core Data schema
```

### Core Data Schema
- **Entry**: id, content, contentType, title, createdAt, updatedAt, sourceApplication, sourceBundleId, sourceURL, imageData, metadata
- **EntryEmbedding**: id, embedding, model, createdAt, relationship to Entry

### Future Enhancements
- [ ] Full PostgreSQL sync with Commonbase Next
- [ ] Advanced UMAP implementation for better clustering
- [ ] Batch operations and data export
- [ ] More sophisticated context detection
- [ ] Custom embedding models
- [ ] Advanced search filters
- [ ] Entry linking and tagging
- [ ] Settings panel for configuration

## License

This project is built as a companion to Commonbase Next and follows the same architectural principles for data compatibility.