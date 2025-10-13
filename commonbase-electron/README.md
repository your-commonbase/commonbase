# Commonbase Desktop

A desktop knowledge management application built with Electron that provides semantic search, intelligent file parsing, and a modern UI for managing your personal knowledge base.

## Features

- **🔍 Semantic Search**: Find entries using meaning, not just keywords
- **📁 Intelligent File Parsing**: Support for text, PDF, DOCX, images, code files, and more
- **🖱️ Drag & Drop**: Simply drag files into the app to parse and embed their contents
- **🔗 Linking System**: Create bidirectional links between entries
- **⚡ Local Database**: PostgreSQL with pgvector for fast semantic search
- **🌙 Dark Mode**: Clean, modern interface with dark mode support
- **🎯 Discovery Feed**: Serendipitous exploration of your knowledge base

## Quick Start

### Prerequisites

1. **Node.js 18+** - [Download here](https://nodejs.org/)
2. **PostgreSQL with pgvector** - [Installation guide](https://github.com/pgvector/pgvector#installation)
3. **OpenAI API Key** - For generating embeddings

### Installation

1. Clone and navigate to the project:
   ```bash
   cd commonbase-electron
   ```

2. Install dependencies:
   ```bash
   npm install
   ```

3. Set up your environment:
   ```bash
   cp .env.example .env
   # Edit .env with your database URL and OpenAI API key
   ```

4. Create and configure your database:
   ```bash
   createdb commonbase-electron
   psql commonbase-electron -c "CREATE EXTENSION IF NOT EXISTS vector;"
   npm run db:push
   ```

5. Start the application:
   ```bash
   npm start
   ```

## File Support

### Fully Supported (Content Extracted)
- **Text files**: `.txt`, `.md`, `.json`, `.xml`, `.yaml`, etc.
- **Code files**: `.js`, `.ts`, `.py`, `.rb`, `.php`, `.java`, `.c`, `.cpp`, etc.
- **Documents**: `.pdf`, `.docx`
- **Data files**: `.csv`

### Metadata Only (Requires Manual Description)
- **Images**: `.jpg`, `.png`, `.gif`, `.webp`, `.svg`
- **Video**: `.mp4`, `.avi`, `.mkv`, etc.
- **Audio**: `.mp3`, `.wav`, `.flac`, etc.

### File Processing Features

- **Automatic content extraction** from supported file types
- **Metadata preservation** including file path, size, and modification date
- **File path linking** - entries link back to original files on disk
- **Author field** automatically set to filename as requested
- **Title field** automatically set to filename
- **Type categorization** based on file extension and content

## Architecture

```
src/
├── main.ts                    # Main Electron process
├── preload.ts                 # IPC bridge
├── renderer.tsx               # React renderer entry
├── components/
│   ├── App.tsx                # Main app component
│   ├── Navigation.tsx         # Sidebar navigation
│   └── pages/
│       ├── HomePage.tsx       # Dashboard and overview
│       ├── AddPage.tsx        # Add text entries or files
│       ├── SearchPage.tsx     # Text and semantic search
│       ├── LedgerPage.tsx     # All entries in chronological order
│       ├── FeedPage.tsx       # Random entry discovery
│       └── EntryPage.tsx      # View and edit individual entries
└── lib/
    ├── commonbase-service.ts  # Core business logic
    ├── file-parser.ts         # File content extraction
    ├── embeddings.ts          # OpenAI integration
    └── db/
        ├── schema.ts          # Database schema
        └── index.ts           # Database connection
```

## Usage

### Adding Content

1. **Text Entries**: Use the Add page or `Cmd+N`
2. **File Upload**:
   - Drag files directly into the Add page
   - Use `Cmd+O` to select files
   - Drop files on the dock icon (macOS)

### Searching

- **Text Search**: Searches content and metadata using PostgreSQL full-text search
- **Semantic Search**: Uses OpenAI embeddings to find conceptually similar content

### Navigation

- **Cmd+1**: Home
- **Cmd+N**: Add Entry
- **Cmd+F**: Search
- **Cmd+L**: Ledger (all entries)
- **Cmd+R**: Feed (random discovery)

## Database Schema

The application uses PostgreSQL with two main tables:

```sql
-- Main entries table
commonbase (
  id UUID PRIMARY KEY,
  data TEXT NOT NULL,
  metadata JSONB DEFAULT '{}',
  created TIMESTAMP DEFAULT NOW(),
  updated TIMESTAMP DEFAULT NOW()
);

-- Vector embeddings for semantic search
embeddings (
  id UUID PRIMARY KEY REFERENCES commonbase(id) ON DELETE CASCADE,
  embedding VECTOR(1536) NOT NULL
);
```

### Metadata Structure

Entries store rich metadata in JSON format:

```json
{
  "title": "Optional title",
  "author": "Filename for file uploads",
  "type": "text|file|pdf|image|etc",
  "filePath": "/path/to/original/file",
  "fileSize": 1024,
  "mimeType": "text/plain",
  "source": "Optional source URL",
  "links": ["uuid1", "uuid2"],
  "backlinks": ["uuid3", "uuid4"]
}
```

## Development

### Database Operations

```bash
# Generate migration files
npm run db:generate

# Apply migrations
npm run db:migrate

# Push schema changes (development)
npm run db:push
```

### Building

```bash
# Package for current platform
npm run package

# Create installers
npm run make
```

### File Parser Details

The file parser (`src/lib/file-parser.ts`) handles various file types:

- **Text files**: Direct UTF-8 reading
- **PDF files**: Uses `pdf-parse` library
- **DOCX files**: Uses `mammoth` library
- **CSV files**: Uses `papaparse` library
- **Images/Video/Audio**: Metadata only, prompts for description

All files get these metadata fields:
- `fileName`: Original filename
- `filePath`: Full path to file
- `fileSize`: File size in bytes
- `mimeType`: Detected MIME type
- `title`: Filename (as requested)
- `author`: Filename (as requested)
- `type`: File category (text, image, video, etc.)

## Environment Variables

Create a `.env` file with:

```bash
# Database
DATABASE_URL=postgresql://localhost:5432/commonbase-electron

# OpenAI (required for embeddings)
OPENAI_API_KEY=your_openai_api_key_here

# Application
NODE_ENV=development
```

## Troubleshooting

### Database Issues

1. **pgvector not installed**:
   ```bash
   # Install pgvector extension
   psql your_db -c "CREATE EXTENSION IF NOT EXISTS vector;"
   ```

2. **Database connection failed**: Check your `DATABASE_URL` in `.env`

### File Processing Issues

1. **PDF parsing fails**: Ensure file isn't password protected
2. **Large files**: The app handles large files but embedding generation may take time
3. **Unsupported formats**: App will prompt for manual description

### Performance

1. **Slow semantic search**: Ensure pgvector extension is properly installed
2. **Memory usage**: Large files are processed in chunks where possible

## License

MIT - See LICENSE file for details.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

For questions or support, please open an issue on GitHub.