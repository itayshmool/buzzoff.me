import { useState } from 'react';
import { Outlet } from 'react-router-dom';
import Sidebar from './Sidebar';

export default function AppLayout() {
  const [sidebarOpen, setSidebarOpen] = useState(false);

  return (
    <div className="flex min-h-screen bg-carbon">
      {/* Mobile top bar */}
      <div className="fixed top-0 left-0 right-0 z-40 flex items-center h-12 px-4 bg-surface-raised border-b border-border md:hidden">
        <button
          onClick={() => setSidebarOpen(true)}
          className="p-1 text-text-secondary hover:text-neon transition-colors"
          aria-label="Open menu"
        >
          <svg xmlns="http://www.w3.org/2000/svg" className="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M4 6h16M4 12h16M4 18h16" />
          </svg>
        </button>
        <div className="ml-3 font-heading text-base font-black tracking-wider text-neon text-glow-neon">
          BUZZ<span className="text-hot">OFF</span>
        </div>
      </div>

      <Sidebar isOpen={sidebarOpen} onClose={() => setSidebarOpen(false)} />

      <main className="flex-1 p-4 pt-16 md:p-8 md:pt-8 overflow-auto">
        <Outlet />
      </main>
    </div>
  );
}
