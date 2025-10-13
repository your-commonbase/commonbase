import React, { useState, useEffect } from 'react';
import Navigation from './Navigation';
import HomePage from './pages/HomePage';
import AddPage from './pages/AddPage';
import SearchPage from './pages/SearchPage';
import LedgerPage from './pages/LedgerPage';
import FeedPage from './pages/FeedPage';
import EntryPage from './pages/EntryPage';

type Page = 'home' | 'add' | 'search' | 'ledger' | 'feed' | 'entry';

interface AppState {
  currentPage: Page;
  selectedEntryId?: string;
}

const App: React.FC = () => {
  const [appState, setAppState] = useState<AppState>({
    currentPage: 'home'
  });

  useEffect(() => {
    // Listen for navigation events from main process
    window.electronAPI.onNavigateTo((route: string) => {
      const routeMap: Record<string, Page> = {
        '/': 'home',
        '/add': 'add',
        '/search': 'search',
        '/ledger': 'ledger',
        '/feed': 'feed'
      };

      const page = routeMap[route];
      if (page) {
        setAppState({ currentPage: page });
      }
    });

    // Listen for file addition events
    window.electronAPI.onFilesAdded((count: number) => {
      // Show notification or refresh current view
      console.log(`Added ${count} file(s)`);
    });

    window.electronAPI.onFileAdded((filePath: string) => {
      console.log(`Added file: ${filePath}`);
    });

    return () => {
      // Cleanup listeners
      window.electronAPI.removeAllListeners('navigate-to');
      window.electronAPI.removeAllListeners('files-added');
      window.electronAPI.removeAllListeners('file-added');
    };
  }, []);

  const navigateTo = (page: Page, entryId?: string) => {
    setAppState({ currentPage: page, selectedEntryId: entryId });
  };

  const renderCurrentPage = () => {
    switch (appState.currentPage) {
      case 'home':
        return <HomePage navigateTo={navigateTo} />;
      case 'add':
        return <AddPage navigateTo={navigateTo} />;
      case 'search':
        return <SearchPage navigateTo={navigateTo} />;
      case 'ledger':
        return <LedgerPage navigateTo={navigateTo} />;
      case 'feed':
        return <FeedPage navigateTo={navigateTo} />;
      case 'entry':
        return <EntryPage entryId={appState.selectedEntryId} navigateTo={navigateTo} />;
      default:
        return <HomePage navigateTo={navigateTo} />;
    }
  };

  return (
    <div className="flex h-screen bg-gray-50 dark:bg-gray-900">
      <Navigation
        currentPage={appState.currentPage}
        navigateTo={navigateTo}
      />
      <main className="flex-1 overflow-hidden">
        {renderCurrentPage()}
      </main>
    </div>
  );
};

export default App;