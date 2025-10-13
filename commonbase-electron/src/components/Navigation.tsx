import React from 'react';
import {
  Home,
  Plus,
  Search,
  List,
  Shuffle,
  FileText
} from 'lucide-react';

type Page = 'home' | 'add' | 'search' | 'ledger' | 'feed' | 'entry';

interface NavigationProps {
  currentPage: Page;
  navigateTo: (page: Page) => void;
}

const Navigation: React.FC<NavigationProps> = ({ currentPage, navigateTo }) => {
  const menuItems = [
    { id: 'home', label: 'Home', icon: Home, shortcut: 'Cmd+1' },
    { id: 'add', label: 'Add', icon: Plus, shortcut: 'Cmd+N' },
    { id: 'search', label: 'Search', icon: Search, shortcut: 'Cmd+F' },
    { id: 'ledger', label: 'Ledger', icon: List, shortcut: 'Cmd+L' },
    { id: 'feed', label: 'Feed', icon: Shuffle, shortcut: 'Cmd+R' },
  ];

  return (
    <nav className="w-64 bg-white dark:bg-gray-800 border-r border-gray-200 dark:border-gray-700">
      <div className="p-6">
        <div className="flex items-center space-x-3 mb-8">
          <FileText className="h-8 w-8 text-blue-600" />
          <h1 className="text-xl font-bold text-gray-900 dark:text-white">
            Commonbase
          </h1>
        </div>

        <ul className="space-y-2">
          {menuItems.map((item) => {
            const Icon = item.icon;
            const isActive = currentPage === item.id;

            return (
              <li key={item.id}>
                <button
                  onClick={() => navigateTo(item.id as Page)}
                  className={`w-full flex items-center justify-between px-4 py-3 text-left rounded-lg transition-colors ${
                    isActive
                      ? 'bg-blue-50 dark:bg-blue-900/20 text-blue-600 dark:text-blue-400'
                      : 'text-gray-700 dark:text-gray-300 hover:bg-gray-50 dark:hover:bg-gray-700'
                  }`}
                >
                  <div className="flex items-center space-x-3">
                    <Icon className="h-5 w-5" />
                    <span className="font-medium">{item.label}</span>
                  </div>
                  <span className="text-xs text-gray-400 dark:text-gray-500">
                    {item.shortcut}
                  </span>
                </button>
              </li>
            );
          })}
        </ul>

        <div className="mt-8 p-4 bg-gray-50 dark:bg-gray-700/50 rounded-lg">
          <p className="text-sm text-gray-600 dark:text-gray-400">
            Drag files here or use <span className="font-mono">Cmd+O</span> to add files
          </p>
        </div>
      </div>
    </nav>
  );
};

export default Navigation;