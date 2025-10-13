import React, { useState, useEffect } from 'react';
import {
  FileText,
  Calendar,
  Tag,
  ExternalLink,
  Folder,
  Image,
  Code,
  File
} from 'lucide-react';

type Page = 'home' | 'add' | 'search' | 'ledger' | 'feed' | 'entry';

interface LedgerPageProps {
  navigateTo: (page: Page, entryId?: string) => void;
}

const LedgerPage: React.FC<LedgerPageProps> = ({ navigateTo }) => {
  const [entries, setEntries] = useState([]);
  const [isLoading, setIsLoading] = useState(true);
  const [offset, setOffset] = useState(0);
  const [hasMore, setHasMore] = useState(true);

  useEffect(() => {
    loadEntries();
  }, []);

  const loadEntries = async (loadMore = false) => {
    try {
      setIsLoading(!loadMore);
      const newOffset = loadMore ? offset : 0;
      const newEntries = await window.electronAPI.listEntries(newOffset, 50);

      if (loadMore) {
        setEntries(prev => [...prev, ...newEntries]);
      } else {
        setEntries(newEntries);
      }

      setOffset(newOffset + newEntries.length);
      setHasMore(newEntries.length === 50);
    } catch (error) {
      console.error('Failed to load entries:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const getTypeIcon = (metadata: any) => {
    const type = metadata?.type;
    switch (type) {
      case 'image':
        return <Image className="h-4 w-4 text-blue-500" />;
      case 'code':
      case 'text':
        return <Code className="h-4 w-4 text-green-500" />;
      case 'pdf':
      case 'docx':
        return <FileText className="h-4 w-4 text-red-500" />;
      default:
        return <File className="h-4 w-4 text-gray-500" />;
    }
  };

  const formatDate = (dateString: string) => {
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

    if (diffDays === 0) return 'Today';
    if (diffDays === 1) return 'Yesterday';
    if (diffDays < 7) return `${diffDays} days ago`;
    return date.toLocaleDateString();
  };

  return (
    <div className="h-full flex flex-col">
      <div className="border-b border-gray-200 dark:border-gray-700 px-6 py-4">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Ledger</h1>
        <p className="text-gray-600 dark:text-gray-400 mt-1">
          All entries in chronological order
        </p>
      </div>

      <div className="flex-1 overflow-auto">
        {isLoading && entries.length === 0 ? (
          <div className="text-center py-12">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
            <p className="text-gray-600 dark:text-gray-400 mt-2">Loading entries...</p>
          </div>
        ) : entries.length === 0 ? (
          <div className="text-center py-12">
            <Folder className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
              No entries yet
            </h3>
            <p className="text-gray-600 dark:text-gray-400 mb-6">
              Start by adding your first entry or uploading some files
            </p>
            <button
              onClick={() => navigateTo('add')}
              className="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700 transition-colors"
            >
              Add Entry
            </button>
          </div>
        ) : (
          <div className="p-6">
            <div className="space-y-4">
              {entries.map((entry: any) => (
                <div
                  key={entry.id}
                  className="bg-white dark:bg-gray-800 p-6 rounded-lg border border-gray-200 dark:border-gray-700 cursor-pointer hover:border-gray-300 dark:hover:border-gray-600 transition-colors"
                  onClick={() => navigateTo('entry', entry.id)}
                >
                  <div className="flex items-start justify-between mb-3">
                    <div className="flex items-start space-x-3 flex-1 min-w-0">
                      {getTypeIcon(entry.metadata)}
                      <div className="flex-1 min-w-0">
                        <h3 className="text-lg font-medium text-gray-900 dark:text-white">
                          {entry.metadata?.title || entry.metadata?.author || 'Untitled Entry'}
                        </h3>
                        {entry.metadata?.filePath && (
                          <p className="text-sm text-blue-600 dark:text-blue-400 truncate">
                            {entry.metadata.filePath}
                          </p>
                        )}
                      </div>
                    </div>
                    <div className="flex items-center space-x-2 text-sm text-gray-500 dark:text-gray-400">
                      <Calendar className="h-4 w-4" />
                      <span>{formatDate(entry.created)}</span>
                    </div>
                  </div>

                  <p className="text-gray-700 dark:text-gray-300 mb-4 line-clamp-2">
                    {entry.data.substring(0, 200)}
                    {entry.data.length > 200 && '...'}
                  </p>

                  <div className="flex items-center justify-between">
                    <div className="flex items-center space-x-3">
                      {entry.metadata?.type && (
                        <span className="flex items-center space-x-1 px-2 py-1 bg-gray-100 dark:bg-gray-700 rounded-full text-xs text-gray-600 dark:text-gray-400">
                          <Tag className="h-3 w-3" />
                          <span>{entry.metadata.type}</span>
                        </span>
                      )}
                      {entry.metadata?.fileSize && (
                        <span className="text-xs text-gray-500 dark:text-gray-400">
                          {Math.round(entry.metadata.fileSize / 1024)}KB
                        </span>
                      )}
                      {entry.metadata?.source && (
                        <span className="flex items-center space-x-1 text-xs text-blue-600 dark:text-blue-400 truncate max-w-xs">
                          <ExternalLink className="h-3 w-3" />
                          <span>{entry.metadata.source}</span>
                        </span>
                      )}
                    </div>

                    {(entry.metadata?.links?.length > 0 || entry.metadata?.backlinks?.length > 0) && (
                      <div className="flex items-center space-x-2 text-xs text-gray-500 dark:text-gray-400">
                        {entry.metadata?.links?.length > 0 && (
                          <span>→ {entry.metadata.links.length} link{entry.metadata.links.length !== 1 ? 's' : ''}</span>
                        )}
                        {entry.metadata?.backlinks?.length > 0 && (
                          <span>← {entry.metadata.backlinks.length} backlink{entry.metadata.backlinks.length !== 1 ? 's' : ''}</span>
                        )}
                      </div>
                    )}
                  </div>
                </div>
              ))}
            </div>

            {hasMore && (
              <div className="text-center mt-8">
                <button
                  onClick={() => loadEntries(true)}
                  disabled={isLoading}
                  className="bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 px-6 py-2 rounded-lg hover:bg-gray-300 dark:hover:bg-gray-600 disabled:opacity-50 transition-colors"
                >
                  {isLoading ? 'Loading...' : 'Load More'}
                </button>
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
};

export default LedgerPage;