import React, { useState, useRef, useCallback } from 'react';
import {
  Upload,
  FileText,
  Image,
  Video,
  Music,
  File,
  X,
  CheckCircle,
  AlertCircle
} from 'lucide-react';

type Page = 'home' | 'add' | 'search' | 'ledger' | 'feed' | 'entry';

interface AddPageProps {
  navigateTo: (page: Page, entryId?: string) => void;
}

interface DroppedFile {
  path: string;
  name: string;
  size: number;
  type: string;
}

const AddPage: React.FC<AddPageProps> = ({ navigateTo }) => {
  const [textContent, setTextContent] = useState('');
  const [metadata, setMetadata] = useState({ title: '', source: '' });
  const [isLoading, setIsLoading] = useState(false);
  const [dragActive, setDragActive] = useState(false);
  const [droppedFiles, setDroppedFiles] = useState<DroppedFile[]>([]);
  const [processingFiles, setProcessingFiles] = useState<string[]>([]);
  const [processedFiles, setProcessedFiles] = useState<string[]>([]);
  const [message, setMessage] = useState<{ type: 'success' | 'error', content: string } | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleDrag = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    if (e.type === 'dragenter' || e.type === 'dragover') {
      setDragActive(true);
    } else if (e.type === 'dragleave') {
      setDragActive(false);
    }
  }, []);

  const handleDrop = useCallback((e: React.DragEvent) => {
    e.preventDefault();
    e.stopPropagation();
    setDragActive(false);

    const files = Array.from(e.dataTransfer.files);
    const newFiles: DroppedFile[] = files.map(file => ({
      path: (file as any).path || file.name, // Electron provides path
      name: file.name,
      size: file.size,
      type: file.type
    }));

    setDroppedFiles(prev => [...prev, ...newFiles]);
  }, []);

  const getFileIcon = (type: string, name: string) => {
    if (type.startsWith('image/')) return <Image className="h-5 w-5 text-blue-500" />;
    if (type.startsWith('video/')) return <Video className="h-5 w-5 text-purple-500" />;
    if (type.startsWith('audio/')) return <Music className="h-5 w-5 text-green-500" />;
    if (type.startsWith('text/') || name.endsWith('.md') || name.endsWith('.txt')) {
      return <FileText className="h-5 w-5 text-gray-600" />;
    }
    return <File className="h-5 w-5 text-gray-500" />;
  };

  const formatFileSize = (bytes: number) => {
    if (bytes === 0) return '0 Bytes';
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  const removeFile = (path: string) => {
    setDroppedFiles(prev => prev.filter(file => file.path !== path));
  };

  const processFiles = async () => {
    if (droppedFiles.length === 0) return;

    setIsLoading(true);
    setProcessingFiles(droppedFiles.map(f => f.path));
    setProcessedFiles([]);

    try {
      const results = [];
      for (const file of droppedFiles) {
        try {
          const result = await window.electronAPI.addFile(file.path);
          results.push(result);
          setProcessedFiles(prev => [...prev, file.path]);
        } catch (error) {
          console.error(`Failed to process file ${file.name}:`, error);
          setMessage({ type: 'error', content: `Failed to process ${file.name}: ${error.message}` });
        }
      }

      if (results.length > 0) {
        setMessage({ type: 'success', content: `Successfully processed ${results.length} file(s)` });
        setDroppedFiles([]);
        setTimeout(() => {
          navigateTo('ledger');
        }, 1500);
      }
    } catch (error) {
      setMessage({ type: 'error', content: `Error processing files: ${error.message}` });
    } finally {
      setIsLoading(false);
      setProcessingFiles([]);
    }
  };

  const handleTextSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!textContent.trim()) return;

    setIsLoading(true);
    try {
      const entry = await window.electronAPI.addEntry(
        textContent,
        {
          type: 'text',
          title: metadata.title || undefined,
          source: metadata.source || undefined,
        }
      );

      setMessage({ type: 'success', content: 'Entry added successfully!' });
      setTextContent('');
      setMetadata({ title: '', source: '' });

      setTimeout(() => {
        navigateTo('entry', entry.id);
      }, 1500);
    } catch (error) {
      setMessage({ type: 'error', content: `Failed to add entry: ${error.message}` });
    } finally {
      setIsLoading(false);
    }
  };

  const selectFiles = async () => {
    try {
      const result = await window.electronAPI.selectFile();
      if (!result.canceled && result.filePaths.length > 0) {
        const newFiles: DroppedFile[] = await Promise.all(
          result.filePaths.map(async (path) => {
            try {
              // Get file stats from the main process via IPC
              const fileStats = await window.electronAPI.getFileStats(path);
              return {
                path,
                name: path.split('/').pop() || path,
                size: fileStats.size,
                type: fileStats.type
              };
            } catch (error) {
              // Fallback if unable to read stats
              return {
                path,
                name: path.split('/').pop() || path,
                size: 0,
                type: ''
              };
            }
          })
        );
        setDroppedFiles(prev => [...prev, ...newFiles]);
      }
    } catch (error) {
      setMessage({ type: 'error', content: `Failed to select files: ${error.message}` });
    }
  };

  return (
    <div className="h-full flex flex-col">
      <div className="border-b border-gray-200 dark:border-gray-700 px-6 py-4">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Add Entry</h1>
        <p className="text-gray-600 dark:text-gray-400 mt-1">
          Add text content or drag files to parse and embed
        </p>
      </div>

      <div className="flex-1 overflow-auto p-6">
        {message && (
          <div className={`mb-6 p-4 rounded-lg ${
            message.type === 'success'
              ? 'bg-green-50 dark:bg-green-900/20 text-green-800 dark:text-green-200'
              : 'bg-red-50 dark:bg-red-900/20 text-red-800 dark:text-red-200'
          }`}>
            <div className="flex items-center">
              {message.type === 'success' ? (
                <CheckCircle className="h-5 w-5 mr-2" />
              ) : (
                <AlertCircle className="h-5 w-5 mr-2" />
              )}
              {message.content}
            </div>
          </div>
        )}

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
          {/* Text Entry Form */}
          <div className="space-y-6">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">Text Entry</h2>

            <form onSubmit={handleTextSubmit} className="space-y-4">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    Title (optional)
                  </label>
                  <input
                    type="text"
                    value={metadata.title}
                    onChange={(e) => setMetadata(prev => ({ ...prev, title: e.target.value }))}
                    className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    placeholder="Entry title"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                    Source (optional)
                  </label>
                  <input
                    type="text"
                    value={metadata.source}
                    onChange={(e) => setMetadata(prev => ({ ...prev, source: e.target.value }))}
                    className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    placeholder="Source URL or reference"
                  />
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                  Content
                </label>
                <textarea
                  value={textContent}
                  onChange={(e) => setTextContent(e.target.value)}
                  className="w-full h-64 px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent resize-none"
                  placeholder="Enter your text content here..."
                  required
                />
              </div>

              <button
                type="submit"
                disabled={isLoading || !textContent.trim()}
                className="w-full bg-blue-600 text-white py-2 px-4 rounded-md hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
              >
                {isLoading ? 'Adding Entry...' : 'Add Text Entry'}
              </button>
            </form>
          </div>

          {/* File Drop Zone */}
          <div className="space-y-6">
            <h2 className="text-lg font-semibold text-gray-900 dark:text-white">File Upload</h2>

            <div
              className={`border-2 border-dashed rounded-lg p-8 text-center transition-colors ${
                dragActive
                  ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
                  : 'border-gray-300 dark:border-gray-600 hover:border-gray-400 dark:hover:border-gray-500'
              }`}
              onDragEnter={handleDrag}
              onDragLeave={handleDrag}
              onDragOver={handleDrag}
              onDrop={handleDrop}
            >
              <Upload className={`mx-auto h-12 w-12 ${
                dragActive ? 'text-blue-500' : 'text-gray-400'
              }`} />
              <p className="mt-2 text-lg font-medium text-gray-900 dark:text-white">
                Drop files here
              </p>
              <p className="text-gray-600 dark:text-gray-400">
                or{' '}
                <button
                  onClick={selectFiles}
                  className="text-blue-600 hover:text-blue-700 underline"
                >
                  browse to select
                </button>
              </p>
              <p className="text-sm text-gray-500 dark:text-gray-400 mt-2">
                Supports text, PDF, DOCX, images, and more
              </p>
            </div>

            {/* File List */}
            {droppedFiles.length > 0 && (
              <div className="space-y-2">
                <h3 className="font-medium text-gray-900 dark:text-white">Files to Process</h3>
                <div className="space-y-2 max-h-40 overflow-y-auto">
                  {droppedFiles.map((file) => (
                    <div
                      key={file.path}
                      className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-800 rounded-md"
                    >
                      <div className="flex items-center space-x-3 flex-1 min-w-0">
                        {getFileIcon(file.type, file.name)}
                        <div className="flex-1 min-w-0">
                          <p className="text-sm font-medium text-gray-900 dark:text-white truncate">
                            {file.name}
                          </p>
                          <p className="text-xs text-gray-500 dark:text-gray-400">
                            {formatFileSize(file.size)}
                          </p>
                        </div>
                        {processingFiles.includes(file.path) && (
                          <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-blue-600"></div>
                        )}
                        {processedFiles.includes(file.path) && (
                          <CheckCircle className="h-4 w-4 text-green-500" />
                        )}
                      </div>
                      <button
                        onClick={() => removeFile(file.path)}
                        className="text-gray-400 hover:text-red-500 p-1"
                        disabled={processingFiles.length > 0}
                      >
                        <X className="h-4 w-4" />
                      </button>
                    </div>
                  ))}
                </div>

                <button
                  onClick={processFiles}
                  disabled={isLoading || droppedFiles.length === 0}
                  className="w-full bg-green-600 text-white py-2 px-4 rounded-md hover:bg-green-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                >
                  {isLoading ? 'Processing Files...' : `Process ${droppedFiles.length} File(s)`}
                </button>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
};

export default AddPage;