import React, { useState, useEffect } from 'react';
import {
  Search,
  Zap,
  FileText,
  Calendar,
  Tag
} from 'lucide-react';

type Page = 'home' | 'add' | 'search' | 'ledger' | 'feed' | 'entry';

interface SearchPageProps {
  navigateTo: (page: Page, entryId?: string) => void;
}

const SearchPage: React.FC<SearchPageProps> = ({ navigateTo }) => {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState([]);
  const [semanticResults, setSemanticResults] = useState([]);
  const [isLoading, setIsLoading] = useState(false);
  const [searchType, setSearchType] = useState<'text' | 'semantic'>('text');

  const performSearch = async (searchQuery: string) => {
    if (!searchQuery.trim()) {
      setResults([]);
      setSemanticResults([]);
      return;
    }

    setIsLoading(true);
    try {
      const [textResults, semanticResults] = await Promise.all([
        window.electronAPI.searchEntries(searchQuery, 20),
        window.electronAPI.semanticSearch(searchQuery, 20),
      ]);

      setResults(textResults);
      setSemanticResults(semanticResults);
    } catch (error) {
      console.error('Search failed:', error);
    } finally {
      setIsLoading(false);
    }
  };

  useEffect(() => {
    const timeoutId = setTimeout(() => {
      performSearch(query);
    }, 300);

    return () => clearTimeout(timeoutId);
  }, [query]);

  const currentResults = searchType === 'text' ? results : semanticResults;

  const highlightText = (text: string, query: string) => {
    if (!query.trim()) return text;

    const regex = new RegExp(`(${query.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')})`, 'gi');
    const parts = text.split(regex);

    return parts.map((part, index) =>
      regex.test(part) ? (
        <mark key={index} className="bg-yellow-200 dark:bg-yellow-800 px-1 rounded">
          {part}
        </mark>
      ) : part
    );
  };

  return (
    <div className="h-full flex flex-col">
      <div className="border-b border-gray-200 dark:border-gray-700 px-6 py-4">
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">Search</h1>
        <p className="text-gray-600 dark:text-gray-400 mt-1">
          Find entries using text search or semantic similarity
        </p>
      </div>

      <div className="p-6 border-b border-gray-200 dark:border-gray-700">
        {/* Search Input */}
        <div className="relative mb-4">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-5 w-5 text-gray-400" />
          <input
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            placeholder="Search your entries..."
            className="w-full pl-10 pr-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-white focus:ring-2 focus:ring-blue-500 focus:border-transparent"
          />
        </div>

        {/* Search Type Toggle */}
        <div className="flex items-center space-x-4">
          <button
            onClick={() => setSearchType('text')}
            className={`flex items-center space-x-2 px-4 py-2 rounded-lg transition-colors ${
              searchType === 'text'
                ? 'bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300'
                : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white'
            }`}
          >
            <FileText className="h-4 w-4" />
            <span>Text Search</span>
            {results.length > 0 && (
              <span className="bg-blue-200 dark:bg-blue-800 text-blue-800 dark:text-blue-200 px-2 py-1 rounded-full text-xs">
                {results.length}
              </span>
            )}
          </button>

          <button
            onClick={() => setSearchType('semantic')}
            className={`flex items-center space-x-2 px-4 py-2 rounded-lg transition-colors ${
              searchType === 'semantic'
                ? 'bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300'
                : 'text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-white'
            }`}
          >
            <Zap className="h-4 w-4" />
            <span>Semantic Search</span>
            {semanticResults.length > 0 && (
              <span className="bg-purple-200 dark:bg-purple-800 text-purple-800 dark:text-purple-200 px-2 py-1 rounded-full text-xs">
                {semanticResults.length}
              </span>
            )}
          </button>
        </div>
      </div>

      {/* Results */}
      <div className="flex-1 overflow-auto p-6">
        {isLoading && (
          <div className="text-center py-8">
            <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto"></div>
            <p className="text-gray-600 dark:text-gray-400 mt-2">Searching...</p>
          </div>
        )}

        {!isLoading && query && currentResults.length === 0 && (
          <div className="text-center py-12">
            <Search className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <p className="text-gray-600 dark:text-gray-400">
              No results found for "{query}"
            </p>
          </div>
        )}

        {!isLoading && !query && (
          <div className="text-center py-12">
            <Search className="h-12 w-12 text-gray-400 mx-auto mb-4" />
            <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
              Search Your Knowledge Base
            </h3>
            <p className="text-gray-600 dark:text-gray-400 max-w-md mx-auto">
              Enter keywords to find entries using text search, or use semantic search to find conceptually similar content
            </p>
          </div>
        )}

        {!isLoading && currentResults.length > 0 && (
          <div className="space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
                {searchType === 'text' ? 'Text Search Results' : 'Semantic Search Results'}
              </h3>
              <span className="text-sm text-gray-500 dark:text-gray-400">
                {currentResults.length} result{currentResults.length !== 1 ? 's' : ''}
              </span>
            </div>

            <div className="space-y-3">
              {currentResults.map((entry: any, index: number) => (
                <div
                  key={entry.id}
                  className="bg-white dark:bg-gray-800 p-6 rounded-lg border border-gray-200 dark:border-gray-700 cursor-pointer hover:border-gray-300 dark:hover:border-gray-600 transition-colors"
                  onClick={() => navigateTo('entry', entry.id)}
                >
                  <div className="flex items-start justify-between mb-3">
                    <h4 className="text-lg font-medium text-gray-900 dark:text-white">
                      {entry.metadata?.title || `Entry ${index + 1}`}
                    </h4>
                    {searchType === 'semantic' && entry.similarity && (
                      <span className="bg-purple-100 dark:bg-purple-900/30 text-purple-700 dark:text-purple-300 px-2 py-1 rounded-full text-xs">
                        {Math.round(entry.similarity * 100)}% match
                      </span>
                    )}
                  </div>

                  <p className="text-gray-700 dark:text-gray-300 mb-4 line-clamp-3">
                    {typeof highlightText === 'function' ?
                      highlightText(entry.data.substring(0, 300) + '...', query) :
                      entry.data.substring(0, 300) + '...'
                    }
                  </p>

                  <div className="flex items-center space-x-4 text-sm text-gray-500 dark:text-gray-400">
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
                    {entry.metadata?.source && (
                      <span className="text-blue-600 dark:text-blue-400 truncate max-w-xs">
                        {entry.metadata.source}
                      </span>
                    )}
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default SearchPage;