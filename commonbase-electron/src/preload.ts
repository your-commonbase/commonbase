// See the Electron documentation for details on how to use preload scripts:
// https://www.electronjs.org/docs/latest/tutorial/process-model#preload-scripts

import { contextBridge, ipcRenderer } from 'electron';

export interface CommonbaseEntry {
  id: string;
  data: string;
  metadata: any;
  created: Date;
  updated: Date;
}

contextBridge.exposeInMainWorld('electronAPI', {
  // Commonbase operations
  addEntry: (data: string, metadata?: any, embedding?: number[]) =>
    ipcRenderer.invoke('commonbase:add-entry', data, metadata, embedding),

  addFile: (filePath: string) =>
    ipcRenderer.invoke('commonbase:add-file', filePath),

  getEntry: (id: string) =>
    ipcRenderer.invoke('commonbase:get-entry', id),

  updateEntry: (id: string, data?: string, metadata?: any) =>
    ipcRenderer.invoke('commonbase:update-entry', id, data, metadata),

  deleteEntry: (id: string) =>
    ipcRenderer.invoke('commonbase:delete-entry', id),

  listEntries: (offset = 0, limit = 50) =>
    ipcRenderer.invoke('commonbase:list-entries', offset, limit),

  searchEntries: (query: string, limit = 20) =>
    ipcRenderer.invoke('commonbase:search', query, limit),

  semanticSearch: (query: string, limit = 20) =>
    ipcRenderer.invoke('commonbase:semantic-search', query, limit),

  getRandomEntries: (limit = 10) =>
    ipcRenderer.invoke('commonbase:random-entries', limit),

  linkEntries: (parentId: string, childId: string) =>
    ipcRenderer.invoke('commonbase:link-entries', parentId, childId),

  getSimilarEntries: (entryId: string, limit = 5) =>
    ipcRenderer.invoke('commonbase:get-similar-entries', entryId, limit),

  // Dialog operations
  selectFile: () =>
    ipcRenderer.invoke('dialog:select-file'),

  // File operations
  getFileStats: (filePath: string) =>
    ipcRenderer.invoke('file:get-stats', filePath),

  revealInFinder: (filePath: string) =>
    ipcRenderer.invoke('file:reveal-in-finder', filePath),

  getImageData: (filePath: string) =>
    ipcRenderer.invoke('file:get-image-data', filePath),

  // Navigation events
  onNavigateTo: (callback: (route: string) => void) => {
    ipcRenderer.on('navigate-to', (event, route) => callback(route));
  },

  onFilesAdded: (callback: (count: number) => void) => {
    ipcRenderer.on('files-added', (event, count) => callback(count));
  },

  onFileAdded: (callback: (filePath: string) => void) => {
    ipcRenderer.on('file-added', (event, filePath) => callback(filePath));
  },

  // Remove listeners
  removeAllListeners: (channel: string) => {
    ipcRenderer.removeAllListeners(channel);
  },
});

// Type definitions for TypeScript
declare global {
  interface Window {
    electronAPI: {
      addEntry: (data: string, metadata?: any, embedding?: number[]) => Promise<CommonbaseEntry>;
      addFile: (filePath: string) => Promise<CommonbaseEntry>;
      getEntry: (id: string) => Promise<CommonbaseEntry | null>;
      updateEntry: (id: string, data?: string, metadata?: any) => Promise<CommonbaseEntry | null>;
      deleteEntry: (id: string) => Promise<boolean>;
      listEntries: (offset?: number, limit?: number) => Promise<CommonbaseEntry[]>;
      searchEntries: (query: string, limit?: number) => Promise<CommonbaseEntry[]>;
      semanticSearch: (query: string, limit?: number) => Promise<CommonbaseEntry[]>;
      getRandomEntries: (limit?: number) => Promise<CommonbaseEntry[]>;
      linkEntries: (parentId: string, childId: string) => Promise<void>;
      getSimilarEntries: (entryId: string, limit?: number) => Promise<CommonbaseEntry[]>;
      selectFile: () => Promise<{ canceled: boolean; filePaths: string[] }>;
      getFileStats: (filePath: string) => Promise<{ size: number; type: string; lastModified: string }>;
      revealInFinder: (filePath: string) => Promise<void>;
      getImageData: (filePath: string) => Promise<string>;
      onNavigateTo: (callback: (route: string) => void) => void;
      onFilesAdded: (callback: (count: number) => void) => void;
      onFileAdded: (callback: (filePath: string) => void) => void;
      removeAllListeners: (channel: string) => void;
    };
  }
}
