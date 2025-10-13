import React, { useState, useEffect } from 'react';
import {
  Plus,
  Search,
  List,
  Shuffle,
  FileText,
  Database,
  Zap
} from 'lucide-react';

type Page = 'home' | 'add' | 'search' | 'ledger' | 'feed' | 'entry';

interface HomePageProps {
  navigateTo: (page: Page) => void;
}

const HomePage: React.FC<HomePageProps> = ({ navigateTo }) => {
  const [stats, setStats] = useState({ totalEntries: 0, recentEntries: [] });
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    loadStats();
  }, []);

  const loadStats = async () => {
    try {
      const [entries, recentEntries] = await Promise.all([
        window.electronAPI.listEntries(0, 1), // Just get count
        window.electronAPI.listEntries(0, 5), // Get recent entries
      ]);

      setStats({
        totalEntries: entries.length > 0 ? 1000 : 0, // Placeholder - would need actual count
        recentEntries: recentEntries.slice(0, 3),
      });
    } catch (error) {
      console.error('Failed to load stats:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const quickActions = [
    {
      title: 'Add Text Entry',
      description: 'Create a new text-based entry',
      icon: Plus,
      action: () => navigateTo('add'),
      color: 'bg-blue-500 hover:bg-blue-600',
    },
    {
      title: 'Search Entries',
      description: 'Find entries with semantic or text search',
      icon: Search,
      action: () => navigateTo('search'),
      color: 'bg-green-500 hover:bg-green-600',
    },
    {
      title: 'Browse Ledger',
      description: 'View all entries in chronological order',
      icon: List,
      action: () => navigateTo('ledger'),
      color: 'bg-purple-500 hover:bg-purple-600',
    },
    {
      title: 'Discovery Feed',
      description: 'Explore random entries for serendipity',
      icon: Shuffle,
      action: () => navigateTo('feed'),
      color: 'bg-orange-500 hover:bg-orange-600',
    },
  ];

  return (
    <div className="h-full overflow-auto">
      <div className="max-w-6xl mx-auto px-6 py-8">
        {/* Header */}
        <div className="text-center mb-12">
          <div className="flex items-center justify-center space-x-3 mb-4">
            <FileText className="h-12 w-12 text-blue-600" />
            <h1 className="text-4xl font-bold text-gray-900 dark:text-white">
              Commonbase Desktop
            </h1>
          </div>
          <p className="text-xl text-gray-600 dark:text-gray-400 max-w-2xl mx-auto">
            Your personal knowledge management system with semantic search and intelligent file parsing
          </p>
        </div>

        {/* Stats */}
        {!isLoading && (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-12">
            <div className="bg-white dark:bg-gray-800 p-6 rounded-lg border border-gray-200 dark:border-gray-700">
              <div className="flex items-center">
                <Database className="h-8 w-8 text-blue-600 mr-3" />
                <div>
                  <p className="text-2xl font-bold text-gray-900 dark:text-white">
                    {stats.totalEntries}
                  </p>
                  <p className="text-gray-600 dark:text-gray-400">Total Entries</p>
                </div>
              </div>
            </div>

            <div className="bg-white dark:bg-gray-800 p-6 rounded-lg border border-gray-200 dark:border-gray-700">
              <div className="flex items-center">
                <Zap className="h-8 w-8 text-green-600 mr-3" />
                <div>
                  <p className="text-2xl font-bold text-gray-900 dark:text-white">
                    {stats.recentEntries.length}
                  </p>
                  <p className="text-gray-600 dark:text-gray-400">Recent Entries</p>
                </div>
              </div>
            </div>

            <div className="bg-white dark:bg-gray-800 p-6 rounded-lg border border-gray-200 dark:border-gray-700">
              <div className="flex items-center">
                <FileText className="h-8 w-8 text-purple-600 mr-3" />
                <div>
                  <p className="text-2xl font-bold text-gray-900 dark:text-white">
                    Ready
                  </p>
                  <p className="text-gray-600 dark:text-gray-400">System Status</p>
                </div>
              </div>
            </div>
          </div>
        )}

        {/* Quick Actions */}
        <div className="mb-12">
          <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-6">
            Quick Actions
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
            {quickActions.map((action, index) => {
              const Icon = action.icon;
              return (
                <button
                  key={index}
                  onClick={action.action}
                  className="group bg-white dark:bg-gray-800 p-6 rounded-lg border border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600 transition-all text-left"
                >
                  <div className={`inline-flex items-center justify-center w-12 h-12 rounded-lg text-white ${action.color} mb-4 group-hover:scale-105 transition-transform`}>
                    <Icon className="h-6 w-6" />
                  </div>
                  <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
                    {action.title}
                  </h3>
                  <p className="text-gray-600 dark:text-gray-400 text-sm">
                    {action.description}
                  </p>
                </button>
              );
            })}
          </div>
        </div>

        {/* Recent Entries */}
        {stats.recentEntries.length > 0 && (
          <div>
            <div className="flex items-center justify-between mb-6">
              <h2 className="text-2xl font-bold text-gray-900 dark:text-white">
                Recent Entries
              </h2>
              <button
                onClick={() => navigateTo('ledger')}
                className="text-blue-600 hover:text-blue-700 font-medium"
              >
                View All →
              </button>
            </div>
            <div className="space-y-4">
              {stats.recentEntries.map((entry: any) => (
                <div
                  key={entry.id}
                  className="bg-white dark:bg-gray-800 p-6 rounded-lg border border-gray-200 dark:border-gray-700 cursor-pointer hover:border-gray-300 dark:hover:border-gray-600 transition-colors"
                  onClick={() => navigateTo('entry', entry.id)}
                >
                  <div className="flex items-start justify-between">
                    <div className="flex-1 min-w-0">
                      <h3 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
                        {entry.metadata?.title || 'Untitled Entry'}
                      </h3>
                      <p className="text-gray-600 dark:text-gray-400 line-clamp-2">
                        {entry.data.substring(0, 150)}...
                      </p>
                      <div className="flex items-center space-x-4 mt-3 text-sm text-gray-500 dark:text-gray-400">
                        <span>{new Date(entry.created).toLocaleDateString()}</span>
                        {entry.metadata?.type && (
                          <span className="px-2 py-1 bg-gray-100 dark:bg-gray-700 rounded-full text-xs">
                            {entry.metadata.type}
                          </span>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Getting Started */}
        {stats.totalEntries === 0 && !isLoading && (
          <div className="text-center py-12">
            <div className="max-w-md mx-auto">
              <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">
                Get Started
              </h2>
              <p className="text-gray-600 dark:text-gray-400 mb-6">
                Create your first entry to begin building your knowledge base
              </p>
              <div className="space-y-3">
                <button
                  onClick={() => navigateTo('add')}
                  className="w-full bg-blue-600 text-white py-3 px-6 rounded-lg hover:bg-blue-700 transition-colors"
                >
                  Add Your First Entry
                </button>
                <p className="text-sm text-gray-500 dark:text-gray-400">
                  Or drag files directly into the app to get started
                </p>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default HomePage;