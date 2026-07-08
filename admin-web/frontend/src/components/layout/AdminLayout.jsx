import { useState } from 'react';
import { Outlet } from 'react-router-dom';
import { Menu, Clock } from 'lucide-react';
import Sidebar from './Sidebar';

export default function AdminLayout() {
  const [sidebarOpen, setSidebarOpen] = useState(false);

  return (
    <div className="min-h-screen bg-slate-50">
      <Sidebar isOpen={sidebarOpen} onClose={() => setSidebarOpen(false)} />

      {/* Top-bar mobile/tablette uniquement */}
      <div className="lg:hidden sticky top-0 z-30 flex items-center justify-between bg-slate-900 text-white px-4 py-3">
        <div className="flex items-center gap-2">
          <Clock className="w-6 h-6 text-blue-400" />
          <span className="font-bold">WaQti</span>
        </div>
        <button onClick={() => setSidebarOpen(true)} className="p-2 rounded-lg hover:bg-white/10" aria-label="Ouvrir le menu">
          <Menu size={22} />
        </button>
      </div>

      <main className="lg:pl-64 min-h-screen w-full max-w-full overflow-x-hidden">
        <Outlet />
      </main>
    </div>
  );
}
