# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an Electron desktop application called "Commonbase Desktop" that implements a knowledge management system with semantic search and intelligent file parsing. Based on the Next.js Commonbase application, this desktop version provides enhanced file handling with drag-and-drop support and local file system integration.

### Core Features
- Electron desktop application with modern React UI
- PostgreSQL database with pgvector for semantic search
- Intelligent file parsing supporting text, PDF, DOCX, CSV, images, and code files
- Drag-and-drop file upload with automatic content extraction
- OpenAI embeddings for semantic search
- Bidirectional linking between entries
- Multiple views: Home, Add, Search, Ledger, Feed, Entry detail

## Development Commands

```bash
# Development
npm start                # Start Electron app in development mode

# Database operations
npm run db:generate     # Generate Drizzle migration files
npm run db:migrate      # Apply migrations
npm run db:push         # Push schema changes (development)

# Building and packaging
npm run package         # Package for current platform
npm run make           # Create installers for current platform
npm run lint           # Run ESLint
```

## Architecture

### Tech Stack
- **Framework**: Electron 38.x with TypeScript
- **UI**: React 18 with Tailwind CSS 4.0
- **Build Tool**: Vite with @vitejs/plugin-react
- **Database**: PostgreSQL with pgvector extension
- **ORM**: Drizzle ORM with migrations
- **AI**: OpenAI API for text-embedding-3-small (1536 dimensions)
- **File Parsing**: pdf-parse, mammoth (DOCX), papaparse (CSV)
- **Icons**: Lucide React

### Project Structure
- `src/main.ts` - Main Electron process with IPC handlers and menu
- `src/preload.ts` - Secure IPC bridge to renderer
- `src/renderer.tsx` - React application entry point
- `src/components/App.tsx` - Main application component with routing
- `src/components/Navigation.tsx` - Sidebar navigation
- `src/components/pages/` - All page components
- `src/lib/commonbase-service.ts` - Core business logic
- `src/lib/file-parser.ts` - File content extraction logic
- `src/lib/embeddings.ts` - OpenAI integration
- `src/lib/db/` - Database schema and connection

### IPC Architecture

The app uses Electron's secure IPC pattern:

**Main Process (`src/main.ts`)**:
- Window management and native menus
- File system operations and dialog handling
- IPC handlers for all database operations
- Drag-and-drop file handling

**Preload Script (`src/preload.ts`)**:
- Secure bridge exposing `window.electronAPI`
- Type-safe IPC method definitions
- Event listener management

**Renderer Process**:
- React application with TypeScript
- Tailwind CSS for styling
- Component-based architecture

## Database Schema

```sql
-- Main entries table
commonbase (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  data TEXT NOT NULL,
  metadata JSONB DEFAULT '{}',
  created TIMESTAMP DEFAULT NOW(),
  updated TIMESTAMP DEFAULT NOW()
);

-- Vector embeddings table
embeddings (
  id UUID PRIMARY KEY REFERENCES commonbase(id) ON DELETE CASCADE,
  embedding VECTOR(1536) NOT NULL
);
```

### Entry Metadata Structure

The `metadata` JSONB field stores:

```typescript
{
  title?: string;          // Entry title
  author?: string;         // For files: filename (as requested)
  source?: string;         // Source URL or reference
  type?: string;           // Entry type (text, pdf, image, etc.)
  filePath?: string;       // Local file path (for file uploads)
  fileSize?: number;       // File size in bytes
  mimeType?: string;       // MIME type
  links?: string[];        // Outgoing links (UUIDs)
  backlinks?: string[];    // Incoming links (UUIDs)
  [key: string]: any;      // Additional metadata
}
```

## File Processing System

### Supported File Types

**Fully Supported (Content Extracted)**:
- Text files: `.txt`, `.md`, `.js`, `.ts`, `.py`, `.rb`, `.php`, `.html`, `.css`, `.json`, `.xml`, `.yaml`, etc.
- Documents: `.pdf`, `.docx`
- Data: `.csv`

**Metadata Only (Requires Description)**:
- Images: `.jpg`, `.png`, `.gif`, `.webp`, `.svg`
- Video: `.mp4`, `.avi`, `.mkv`, etc.
- Audio: `.mp3`, `.wav`, `.flac`, etc.

### File Processing Flow

1. **File Drop/Selection**: Files received via drag-drop or file dialog
2. **Type Detection**: MIME type and extension analysis
3. **Content Extraction**:
   - Text files: Direct UTF-8 reading
   - PDF: `pdf-parse` library
   - DOCX: `mammoth` library
   - CSV: `papaparse` library
   - Images/Video/Audio: Metadata only, prompts user for description
4. **Metadata Generation**:
   - `author` = filename (as specifically requested)
   - `title` = filename
   - `filePath` = full local path for linking back to original file
   - `type` = categorized file type
5. **Embedding Generation**: Content sent to OpenAI for vector embedding
6. **Database Storage**: Entry and embedding stored with foreign key relationship

## Key Features Implementation

### Drag and Drop
- Main process handles OS file drop events
- AddPage component has drag-over states and file preview
- Automatic batch processing of multiple files
- Progress indication during file processing

### Search System
- **Text Search**: PostgreSQL full-text search using `ILIKE` patterns
- **Semantic Search**: pgvector cosine similarity with OpenAI embeddings
- **Dual Results**: Both search types shown simultaneously
- **Query Highlighting**: Text matches highlighted in results

### Navigation System
- React-based routing without external router
- Keyboard shortcuts handled in main process
- Menu items trigger IPC events to navigate
- Navigation state managed in App component

### File Linking
- Entries store original file paths in metadata
- Local file system integration for file references
- Bidirectional linking system between entries

## Environment Setup

Required environment variables in `.env`:

```bash
DATABASE_URL=postgresql://localhost:5432/commonbase-electron
OPENAI_API_KEY=your_openai_api_key_here
NODE_ENV=development
```

## Development Notes

### Database Requirements
- PostgreSQL with pgvector extension installed
- Extension must be enabled: `CREATE EXTENSION IF NOT EXISTS vector;`
- Database connection configured in `src/lib/db/index.ts`

### File Parser Categories
The file parser categorizes files into:
- `code`: Programming language files
- `config`: Configuration files (JSON, YAML, etc.)
- `web`: HTML, CSS, web-related files
- `data`: SQL, log files
- `document`: Text, Markdown, RTF
- `script`: Shell scripts, batch files

### OpenAI Integration
- Uses `text-embedding-3-small` model with 1536 dimensions
- Embedding generation is optional - entries can be created without embeddings
- Errors in embedding generation don't prevent entry creation

### UI Components
- All components use Tailwind CSS for styling
- Dark mode support throughout
- Responsive design principles
- Lucide React for consistent iconography
- Custom scrollbar styling and line-clamp utilities

## Common Development Tasks

### Adding New File Types
1. Update `isTextFile()` function in `file-parser.ts`
2. Add MIME type handling in `parseFile()`
3. Update file filters in main process dialogs
4. Test content extraction and metadata generation

### Database Schema Changes
1. Modify `src/lib/db/schema.ts`
2. Run `npm run db:generate` to create migration
3. Apply with `npm run db:migrate` or `npm run db:push` (dev)

### Adding New Pages
1. Create component in `src/components/pages/`
2. Add route handling in `App.tsx`
3. Update `Page` type definition
4. Add navigation menu item if needed

### IPC Communication
1. Add handler in `src/main.ts` with `ipcMain.handle()`
2. Expose method in `src/preload.ts` via `contextBridge`
3. Update TypeScript definitions in preload global interface
4. Use in renderer with `window.electronAPI.methodName()`

## Security Considerations

- Context isolation enabled in BrowserWindow
- Node integration disabled in renderer
- All main process communication through secure IPC
- File system access controlled through main process
- No direct database access from renderer

This desktop application provides the full Commonbase experience with enhanced file handling capabilities while maintaining security through Electron's process isolation model.