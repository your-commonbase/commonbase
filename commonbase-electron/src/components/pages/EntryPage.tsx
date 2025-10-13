import React, { useState, useEffect } from 'react';
import {
  Edit,
  Save,
  X,
  Calendar,
  Tag,
  ExternalLink,
  Link,
  ArrowLeft,
  Trash2
} from 'lucide-react';
import ReactMarkdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { Prism as SyntaxHighlighter } from 'react-syntax-highlighter';
import { vscDarkPlus, vs } from 'react-syntax-highlighter/dist/esm/styles/prism';

type Page = 'home' | 'add' | 'search' | 'ledger' | 'feed' | 'entry';

interface EntryPageProps {
  entryId?: string;
  navigateTo: (page: Page, entryId?: string) => void;
}

const getLanguageFromExtension = (extension: string): string => {
  const languageMap: { [key: string]: string } = {
    '.js': 'javascript',
    '.jsx': 'jsx',
    '.ts': 'typescript',
    '.tsx': 'tsx',
    '.py': 'python',
    '.rb': 'ruby',
    '.php': 'php',
    '.java': 'java',
    '.c': 'c',
    '.cpp': 'cpp',
    '.h': 'c',
    '.hpp': 'cpp',
    '.cs': 'csharp',
    '.go': 'go',
    '.rs': 'rust',
    '.swift': 'swift',
    '.kt': 'kotlin',
    '.dart': 'dart',
    '.scala': 'scala',
    '.clj': 'clojure',
    '.hs': 'haskell',
    '.elm': 'elm',
    '.html': 'html',
    '.htm': 'html',
    '.css': 'css',
    '.scss': 'scss',
    '.sass': 'sass',
    '.less': 'less',
    '.json': 'json',
    '.xml': 'xml',
    '.yaml': 'yaml',
    '.yml': 'yaml',
    '.sql': 'sql',
    '.sh': 'bash',
    '.bat': 'batch',
    '.ps1': 'powershell',
    '.vue': 'vue',
    '.svelte': 'svelte',
  };
  return languageMap[extension.toLowerCase()] || 'text';
};

const EntryPage: React.FC<EntryPageProps> = ({ entryId, navigateTo }) => {
  const [entry, setEntry] = useState(null);
  const [isLoading, setIsLoading] = useState(true);
  const [isEditing, setIsEditing] = useState(false);
  const [editData, setEditData] = useState('');
  const [editTitle, setEditTitle] = useState('');
  const [isSaving, setIsSaving] = useState(false);
  const [similarEntries, setSimilarEntries] = useState([]);
  const [loadingSimilar, setLoadingSimilar] = useState(false);
  const [imageDataUrl, setImageDataUrl] = useState<string | null>(null);
  const [imageLoading, setImageLoading] = useState(false);
  const [isDarkMode, setIsDarkMode] = useState(false);

  // Check for dark mode
  useEffect(() => {
    const checkDarkMode = () => {
      setIsDarkMode(document.documentElement.classList.contains('dark') ||
                   window.matchMedia('(prefers-color-scheme: dark)').matches);
    };

    checkDarkMode();
    const mediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    mediaQuery.addListener(checkDarkMode);

    return () => mediaQuery.removeListener(checkDarkMode);
  }, []);

  useEffect(() => {
    if (entryId) {
      loadEntry(entryId);
    }
  }, [entryId]);

  const loadEntry = async (id: string) => {
    setIsLoading(true);
    try {
      const entryData = await window.electronAPI.getEntry(id);
      if (entryData) {
        setEntry(entryData);
        setEditData(entryData.data);
        setEditTitle(entryData.metadata?.title || '');

        // Load similar entries
        loadSimilarEntries(id);

        // Load image if it's an image entry
        if (entryData.metadata?.type === 'image' && entryData.metadata?.filePath) {
          loadImageData(entryData.metadata.filePath);
        }
      }
    } catch (error) {
      console.error('Failed to load entry:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const loadImageData = async (filePath: string) => {
    setImageLoading(true);
    try {
      const dataUrl = await window.electronAPI.getImageData(filePath);
      setImageDataUrl(dataUrl);
    } catch (error) {
      console.error('Failed to load image data:', error);
      setImageDataUrl(null);
    } finally {
      setImageLoading(false);
    }
  };

  const loadSimilarEntries = async (id: string) => {
    setLoadingSimilar(true);
    try {
      const similar = await window.electronAPI.getSimilarEntries(id, 5);
      setSimilarEntries(similar);
    } catch (error) {
      console.error('Failed to load similar entries:', error);
      setSimilarEntries([]);
    } finally {
      setLoadingSimilar(false);
    }
  };

  const handleSave = async () => {
    if (!entry) return;

    setIsSaving(true);
    try {
      const updatedMetadata = {
        ...entry.metadata,
        title: editTitle || undefined,
      };

      const updatedEntry = await window.electronAPI.updateEntry(
        entry.id,
        editData,
        updatedMetadata
      );

      if (updatedEntry) {
        setEntry(updatedEntry);
        setIsEditing(false);
      }
    } catch (error) {
      console.error('Failed to save entry:', error);
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = async () => {
    if (!entry || !confirm('Are you sure you want to delete this entry?')) return;

    try {
      await window.electronAPI.deleteEntry(entry.id);
      navigateTo('ledger');
    } catch (error) {
      console.error('Failed to delete entry:', error);
    }
  };

  if (!entryId) {
    return (
      <div className="h-full flex items-center justify-center">
        <p className="text-gray-500 dark:text-gray-400">No entry selected</p>
      </div>
    );
  }

  if (isLoading) {
    return (
      <div className="h-full flex items-center justify-center">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (!entry) {
    return (
      <div className="h-full flex items-center justify-center">
        <div className="text-center">
          <p className="text-gray-500 dark:text-gray-400 mb-4">Entry not found</p>
          <button
            onClick={() => navigateTo('ledger')}
            className="text-blue-600 hover:text-blue-700"
          >
            ← Back to Ledger
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="h-full flex flex-col">
      {/* Header */}
      <div className="border-b border-gray-200 dark:border-gray-700 px-6 py-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center space-x-4">
            <button
              onClick={() => navigateTo('ledger')}
              className="text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
            >
              <ArrowLeft className="h-5 w-5" />
            </button>
            <div>
              {isEditing ? (
                <input
                  type="text"
                  value={editTitle}
                  onChange={(e) => setEditTitle(e.target.value)}
                  placeholder="Entry title..."
                  className="text-2xl font-bold bg-transparent border-none outline-none text-gray-900 dark:text-white"
                />
              ) : (
                <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
                  {entry.metadata?.title || entry.metadata?.author || 'Untitled Entry'}
                </h1>
              )}
            </div>
          </div>

          <div className="flex items-center space-x-2">
            {isEditing ? (
              <>
                <button
                  onClick={() => setIsEditing(false)}
                  className="p-2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
                >
                  <X className="h-4 w-4" />
                </button>
                <button
                  onClick={handleSave}
                  disabled={isSaving}
                  className="flex items-center space-x-1 px-3 py-1 bg-blue-600 text-white rounded hover:bg-blue-700 disabled:opacity-50"
                >
                  <Save className="h-4 w-4" />
                  <span>{isSaving ? 'Saving...' : 'Save'}</span>
                </button>
              </>
            ) : (
              <>
                <button
                  onClick={() => setIsEditing(true)}
                  className="p-2 text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-200"
                >
                  <Edit className="h-4 w-4" />
                </button>
                <button
                  onClick={handleDelete}
                  className="p-2 text-red-500 hover:text-red-700"
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              </>
            )}
          </div>
        </div>

        {/* Metadata */}
        <div className="flex items-center space-x-4 mt-3 text-sm text-gray-500 dark:text-gray-400">
          <div className="flex items-center space-x-1">
            <Calendar className="h-4 w-4" />
            <span>{new Date(entry.created).toLocaleDateString()}</span>
          </div>
          {entry.metadata?.type && (
            <div className="flex items-center space-x-1">
              <Tag className="h-4 w-4" />
              <span className="px-2 py-1 bg-gray-100 dark:bg-gray-700 rounded-full text-xs">
                {entry.metadata.type}
              </span>
            </div>
          )}
          {entry.metadata?.filePath && (
            <div className="flex items-center space-x-1">
              <Link className="h-4 w-4" />
              <button
                onClick={async () => {
                  try {
                    await window.electronAPI.revealInFinder(entry.metadata.filePath);
                  } catch (error) {
                    console.error('Failed to open file in finder:', error);
                  }
                }}
                className="text-blue-600 dark:text-blue-400 hover:text-blue-700 dark:hover:text-blue-300 hover:underline truncate max-w-xs transition-colors"
                title="Click to open in Finder"
              >
                {entry.metadata.filePath}
              </button>
            </div>
          )}
          {entry.metadata?.source && (
            <div className="flex items-center space-x-1">
              <ExternalLink className="h-4 w-4" />
              <a
                href={entry.metadata.source}
                target="_blank"
                rel="noopener noreferrer"
                className="text-blue-600 dark:text-blue-400 hover:underline truncate max-w-xs"
              >
                {entry.metadata.source}
              </a>
            </div>
          )}
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 overflow-auto p-6">
        {isEditing ? (
          <textarea
            value={editData}
            onChange={(e) => setEditData(e.target.value)}
            className="w-full h-full p-4 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white font-mono text-sm resize-none focus:ring-2 focus:ring-blue-500 focus:border-transparent"
            placeholder="Entry content..."
          />
        ) : (
          <div className="max-w-4xl">
            {entry.metadata?.type === 'image' && entry.metadata?.filePath ? (
              <div className="space-y-4">
                {imageLoading ? (
                  <div className="flex items-center justify-center py-8">
                    <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
                  </div>
                ) : imageDataUrl ? (
                  <img
                    src={imageDataUrl}
                    alt={entry.metadata?.title || entry.metadata?.fileName || 'Image'}
                    className="max-w-full h-auto rounded-lg shadow-lg"
                  />
                ) : (
                  <div className="p-4 border-2 border-dashed border-gray-300 dark:border-gray-600 rounded-lg text-center">
                    <p className="text-gray-500 dark:text-gray-400">Failed to load image</p>
                  </div>
                )}
                <div className="prose dark:prose-invert max-w-none">
                  <ReactMarkdown remarkPlugins={[remarkGfm]}>
                    {entry.data}
                  </ReactMarkdown>
                </div>
              </div>
            ) : entry.metadata?.category === 'code' && entry.metadata?.extension ? (
              <div className="rounded-lg overflow-hidden border border-gray-200 dark:border-gray-700">
                <div className="bg-gray-100 dark:bg-gray-800 px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-300 border-b border-gray-200 dark:border-gray-700">
                  {entry.metadata.fileName} ({getLanguageFromExtension(entry.metadata.extension)})
                </div>
                <SyntaxHighlighter
                  language={getLanguageFromExtension(entry.metadata.extension)}
                  style={isDarkMode ? vscDarkPlus : vs}
                  showLineNumbers={true}
                  wrapLines={true}
                  customStyle={{
                    margin: 0,
                    fontSize: '14px',
                    maxHeight: '70vh',
                    overflow: 'auto'
                  }}
                >
                  {entry.data}
                </SyntaxHighlighter>
              </div>
            ) : entry.metadata?.type === 'text' || entry.data.includes('#') || entry.data.includes('**') ? (
              <div className="prose dark:prose-invert max-w-none">
                <ReactMarkdown remarkPlugins={[remarkGfm]}>
                  {entry.data}
                </ReactMarkdown>
              </div>
            ) : (
              <pre className="whitespace-pre-wrap font-mono text-sm text-gray-800 dark:text-gray-200 leading-relaxed">
                {entry.data}
              </pre>
            )}
          </div>
        )}
      </div>

      {/* Links & Backlinks */}
      {(entry.metadata?.links?.length > 0 || entry.metadata?.backlinks?.length > 0) && (
        <div className="border-t border-gray-200 dark:border-gray-700 p-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {entry.metadata?.links?.length > 0 && (
              <div>
                <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-3">
                  Links ({entry.metadata.links.length})
                </h3>
                <div className="space-y-2">
                  {entry.metadata.links.map((linkId: string) => (
                    <button
                      key={linkId}
                      onClick={() => navigateTo('entry', linkId)}
                      className="block w-full text-left p-3 bg-gray-50 dark:bg-gray-800 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
                    >
                      <span className="text-blue-600 dark:text-blue-400 text-sm">→ {linkId}</span>
                    </button>
                  ))}
                </div>
              </div>
            )}

            {entry.metadata?.backlinks?.length > 0 && (
              <div>
                <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-3">
                  Backlinks ({entry.metadata.backlinks.length})
                </h3>
                <div className="space-y-2">
                  {entry.metadata.backlinks.map((backlinkId: string) => (
                    <button
                      key={backlinkId}
                      onClick={() => navigateTo('entry', backlinkId)}
                      className="block w-full text-left p-3 bg-gray-50 dark:bg-gray-800 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
                    >
                      <span className="text-green-600 dark:text-green-400 text-sm">← {backlinkId}</span>
                    </button>
                  ))}
                </div>
              </div>
            )}
          </div>
        </div>
      )}

      {/* Similar Entries */}
      {(similarEntries.length > 0 || loadingSimilar) && (
        <div className="border-t border-gray-200 dark:border-gray-700 p-6">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-3">
            Similar Entries
          </h3>
          {loadingSimilar ? (
            <div className="flex items-center justify-center py-4">
              <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-blue-600"></div>
            </div>
          ) : (
            <div className="space-y-3 max-h-[25vh] overflow-y-auto">
              {similarEntries.map((similarEntry: any) => (
                <button
                  key={similarEntry.id}
                  onClick={() => navigateTo('entry', similarEntry.id)}
                  className="block w-full text-left p-4 bg-gray-50 dark:bg-gray-800 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700 transition-colors"
                >
                  <div className="flex justify-between items-start mb-2">
                    <h4 className="font-medium text-gray-900 dark:text-white text-sm">
                      {similarEntry.metadata?.title || similarEntry.metadata?.author || 'Untitled Entry'}
                    </h4>
                    <span className="text-xs text-blue-600 dark:text-blue-400 ml-2">
                      {Math.round((similarEntry.similarity || 0) * 100)}% similar
                    </span>
                  </div>
                  <p className="text-sm text-gray-600 dark:text-gray-300 line-clamp-2">
                    {similarEntry.data.substring(0, 120)}...
                  </p>
                  <div className="flex items-center space-x-2 mt-2">
                    {similarEntry.metadata?.type && (
                      <span className="px-2 py-1 bg-gray-200 dark:bg-gray-600 rounded-full text-xs text-gray-700 dark:text-gray-300">
                        {similarEntry.metadata.type}
                      </span>
                    )}
                    <span className="text-xs text-gray-400">
                      {new Date(similarEntry.created).toLocaleDateString()}
                    </span>
                  </div>
                </button>
              ))}
            </div>
          )}
        </div>
      )}
    </div>
  );
};

export default EntryPage;