import React, { useState, useEffect } from 'react';
import {
  Shuffle,
  RefreshCw,
  Calendar,
  Tag,
  ArrowRight
} from 'lucide-react';

type Page = 'home' | 'add' | 'search' | 'ledger' | 'feed' | 'entry';

interface FeedPageProps {
  navigateTo: (page: Page, entryId?: string) => void;
}

const FeedPage: React.FC<FeedPageProps> = ({ navigateTo }) => {
  const [entries, setEntries] = useState([]);
  const [isLoading, setIsLoading] = useState(false);

  useEffect(() => {
    loadRandomEntries();
  }, []);

  const loadRandomEntries = async () => {
    setIsLoading(true);
    try {
      const randomEntries = await window.electronAPI.getRandomEntries(15);
      setEntries(randomEntries);
    } catch (error) {
      console.error('Failed to load random entries:', error);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="h-full flex flex-col">
      <div className="border-b border-gray-200 dark:border-gray-700 px-6 py-4">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Discovery Feed</h1>
            <p className="text-gray-600 dark:text-gray-400 mt-1">
              Serendipitous exploration of your knowledge base
            </p>
          </div>
          <button
            onClick={loadRandomEntries}
            disabled={isLoading}
            className="flex items-center space-x-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 transition-colors"
          >
            <RefreshCw className={`h-4 w-4 ${isLoading ? 'animate-spin' : ''}`} />
            <span>{isLoading ? 'Loading...' : 'Refresh'}</span>
          </button>
        </div>
      </div>

      <div className="flex-1 overflow-auto">
        {isLoading && entries.length === 0 ? (
          <div className="text-center py-12">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
            <p className="text-gray-600 dark:text-gray-400 mt-2">Loading random entries...</p>
          </div>
        ) : entries.length === 0 ? (
          <div className="text-center py-12">
            <Shuffle className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
              No entries to explore
            </h3>
            <p className="text-gray-600 dark:text-gray-400 mb-6">
              Add some entries to start discovering connections
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
            <div className="max-w-4xl mx-auto">
              <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
                {entries.map((entry: any, index: number) => (
                  <div
                    key={entry.id}
                    className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 overflow-hidden hover:border-gray-300 dark:hover:border-gray-600 transition-all cursor-pointer group"
                    onClick={() => navigateTo('entry', entry.id)}
                  >
                    <div className="p-6">
                      <div className="flex items-start justify-between mb-3">
                        <h3 className="text-lg font-medium text-gray-900 dark:text-white line-clamp-1">
                          {entry.metadata?.title || entry.metadata?.author || `Entry ${index + 1}`}
                        </h3>
                        <ArrowRight className="h-4 w-4 text-gray-400 group-hover:text-blue-600 transition-colors flex-shrink-0 ml-2" />
                      </div>

                      <p className="text-gray-700 dark:text-gray-300 text-sm line-clamp-4 mb-4">
                        {entry.data}
                      </p>

                      <div className="flex items-center justify-between text-xs text-gray-500 dark:text-gray-400">
                        <div className="flex items-center space-x-2">
                          <Calendar className="h-3 w-3" />
                          <span>{new Date(entry.created).toLocaleDateString()}</span>
                        </div>
                        {entry.metadata?.type && (
                          <div className="flex items-center space-x-1">
                            <Tag className="h-3 w-3" />
                            <span className="px-2 py-1 bg-gray-100 dark:bg-gray-700 rounded-full">
                              {entry.metadata.type}
                            </span>
                          </div>
                        )}
                      </div>
                    </div>

                    {entry.metadata?.filePath && (
                      <div className="px-6 py-3 bg-gray-50 dark:bg-gray-700/50 border-t border-gray-200 dark:border-gray-600">
                        <p className="text-xs text-blue-600 dark:text-blue-400 truncate">
                          📁 {entry.metadata.filePath}
                        </p>
                      </div>
                    )}
                  </div>
                ))}
              </div>

              <div className="text-center mt-8">
                <p className="text-sm text-gray-500 dark:text-gray-400 mb-4">
                  Discover unexpected connections in your knowledge base
                </p>
                <button
                  onClick={loadRandomEntries}
                  className="text-blue-600 hover:text-blue-700 font-medium"
                >
                  Load More Random Entries
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default FeedPage;