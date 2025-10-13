import fs from 'fs';
import path from 'path';
import mime from 'mime';
// import pdfParse from 'pdf-parse';
import mammoth from 'mammoth';
import Papa from 'papaparse';
import { describeImage } from './embeddings';

export interface ParsedFile {
  content: string;
  metadata: {
    fileName: string;
    filePath: string;
    fileSize: number;
    mimeType: string;
    title: string;
    author: string;
    type: string;
    [key: string]: any;
  };
}

export async function parseFile(filePath: string): Promise<ParsedFile> {
  if (!fs.existsSync(filePath)) {
    throw new Error(`File does not exist: ${filePath}`);
  }

  const stats = fs.statSync(filePath);
  const fileName = path.basename(filePath);
  const mimeType = mime.getType(filePath) || 'application/octet-stream';
  const extension = path.extname(filePath).toLowerCase();

  const baseMetadata = {
    fileName,
    filePath,
    fileSize: stats.size,
    mimeType,
    title: fileName,
    author: fileName, // As requested - author is file name
    type: 'file',
    extension,
    lastModified: stats.mtime.toISOString(),
  };

  // Read file content
  let content = '';

  try {
    if (mimeType.startsWith('text/') || isTextFile(extension)) {
      // Text files - read directly
      content = fs.readFileSync(filePath, 'utf-8');
      return {
        content,
        metadata: {
          ...baseMetadata,
          type: 'text',
          category: getTextFileCategory(extension),
        },
      };
    } else if (mimeType === 'application/pdf') {
      // PDF files - temporarily disabled
      return {
        content: `PDF file: ${fileName}. PDF parsing is temporarily disabled. Please add description or content manually.`,
        metadata: {
          ...baseMetadata,
          type: 'pdf',
          needsDescription: true,
        },
      };
    } else if (mimeType === 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' || extension === '.docx') {
      // DOCX files
      const buffer = fs.readFileSync(filePath);
      const result = await mammoth.extractRawText({ buffer });
      content = result.value;
      return {
        content,
        metadata: {
          ...baseMetadata,
          type: 'docx',
          warnings: result.messages,
        },
      };
    } else if (mimeType === 'text/csv' || extension === '.csv') {
      // CSV files
      const csvContent = fs.readFileSync(filePath, 'utf-8');
      const parsed = Papa.parse(csvContent, { header: true });
      content = JSON.stringify(parsed.data, null, 2);
      return {
        content,
        metadata: {
          ...baseMetadata,
          type: 'csv',
          rowCount: parsed.data.length,
          fields: parsed.meta.fields,
        },
      };
    } else if (mimeType.startsWith('image/')) {
      // Image files - use OpenAI Vision to describe the image
      try {
        const description = await describeImage(filePath, mimeType);
        content = `Image: ${fileName}\n\nDescription: ${description}`;

        return {
          content,
          metadata: {
            ...baseMetadata,
            type: 'image',
            description,
          },
        };
      } catch (error) {
        console.error('Failed to describe image:', error);
        // Fallback if image description fails
        return {
          content: `Image file: ${fileName}. Unable to automatically describe image. Please add description manually.`,
          metadata: {
            ...baseMetadata,
            type: 'image',
            needsDescription: true,
            error: error.message,
          },
        };
      }
    } else if (mimeType.startsWith('video/') || mimeType.startsWith('audio/')) {
      // Video/Audio files - unsupported
      return {
        content: `${mimeType.startsWith('video/') ? 'Video' : 'Audio'} file: ${fileName}. Please add description or transcript that will be embedded.`,
        metadata: {
          ...baseMetadata,
          type: mimeType.startsWith('video/') ? 'video' : 'audio',
          needsDescription: true,
        },
      };
    } else {
      // Other file types
      return {
        content: `File: ${fileName}. Please add description or content that will be embedded.`,
        metadata: {
          ...baseMetadata,
          type: 'unknown',
          needsDescription: true,
        },
      };
    }
  } catch (error) {
    console.error(`Error parsing file ${filePath}:`, error);
    return {
      content: `Error parsing file: ${fileName}. Please add description or content manually.`,
      metadata: {
        ...baseMetadata,
        type: 'error',
        error: error.message,
        needsDescription: true,
      },
    };
  }
}

function isTextFile(extension: string): boolean {
  const textExtensions = [
    '.txt', '.md', '.js', '.ts', '.jsx', '.tsx', '.json', '.xml', '.html', '.htm',
    '.css', '.scss', '.sass', '.less', '.py', '.rb', '.php', '.java', '.c', '.cpp',
    '.h', '.hpp', '.cs', '.go', '.rs', '.swift', '.kt', '.dart', '.sql', '.sh',
    '.bat', '.ps1', '.yaml', '.yml', '.toml', '.ini', '.conf', '.cfg', '.log',
    '.rtf', '.tex', '.r', '.matlab', '.m', '.pl', '.scala', '.clj', '.hs',
    '.elm', '.vue', '.svelte', '.astro'
  ];
  return textExtensions.includes(extension);
}

function getTextFileCategory(extension: string): string {
  const categories = {
    code: ['.js', '.ts', '.jsx', '.tsx', '.py', '.rb', '.php', '.java', '.c', '.cpp', '.h', '.hpp', '.cs', '.go', '.rs', '.swift', '.kt', '.dart', '.scala', '.clj', '.hs', '.elm'],
    config: ['.json', '.xml', '.yaml', '.yml', '.toml', '.ini', '.conf', '.cfg'],
    web: ['.html', '.htm', '.css', '.scss', '.sass', '.less', '.vue', '.svelte', '.astro'],
    data: ['.sql', '.log'],
    document: ['.txt', '.md', '.rtf', '.tex'],
    script: ['.sh', '.bat', '.ps1'],
  };

  for (const [category, extensions] of Object.entries(categories)) {
    if (extensions.includes(extension)) {
      return category;
    }
  }
  return 'text';
}

export function getSupportedFileTypes(): string[] {
  return [
    // Text files
    'text/plain', 'text/markdown', 'text/html', 'text/css', 'text/javascript',
    'application/json', 'application/xml', 'text/xml',
    // Code files
    'application/javascript', 'text/typescript', 'text/x-python', 'text/x-ruby',
    'text/x-php', 'text/x-java-source', 'text/x-c', 'text/x-c++src',
    // Documents
    'application/pdf',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    // Data
    'text/csv', 'application/csv',
    // Images (for metadata only)
    'image/jpeg', 'image/png', 'image/gif', 'image/webp', 'image/svg+xml',
  ];
}