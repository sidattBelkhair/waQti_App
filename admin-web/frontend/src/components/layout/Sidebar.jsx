import { NavLink } from 'react-router-dom';
import { LayoutDashboard, Building2, Users, Settings, LogOut, Clock, X } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

const links = [
  { to: '/', icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/etablissements', icon: Building2, label: 'Etablissements' },
  { to: '/users', icon: Users, label: 'Utilisateurs' },
  { to: '/config', icon: Settings, label: 'Configuration' },
];

export default function Sidebar({ isOpen, onClose }) {
  const { logout, user } = useAuth();
  return (
    <>
      {isOpen && (
        <button type="button" aria-label="Fermer le menu"
          className="fixed inset-0 bg-black/50 z-40 lg:hidden cursor-default" onClick={onClose} />
      )}
      <aside className={`fixed inset-y-0 left-0 z-50 w-64 bg-slate-900 flex flex-col text-white
        transform transition-transform duration-300 ease-in-out
        ${isOpen ? 'translate-x-0' : '-translate-x-full'} lg:translate-x-0`}>
        <div className="p-6 border-b border-white/10 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <Clock className="w-8 h-8 text-blue-400" />
            <div>
              <h1 className="text-xl font-bold">WaQti</h1>
              <p className="text-xs text-slate-400">Admin Dashboard</p>
            </div>
          </div>
          <button onClick={onClose} className="lg:hidden p-1 text-slate-400 hover:text-white" aria-label="Fermer le menu">
            <X size={20} />
          </button>
        </div>
        <nav className="flex-1 p-4 space-y-1 overflow-y-auto">
          {links.map(({ to, icon: Icon, label }) => (
            <NavLink key={to} to={to} onClick={onClose}
              className={({ isActive }) =>
                `flex items-center gap-3 px-4 py-3 rounded-lg transition-colors ${isActive ? 'bg-blue-600 text-white' : 'text-slate-300 hover:bg-white/5'}`
              }>
              <Icon size={20} /><span>{label}</span>
            </NavLink>
          ))}
        </nav>
        <div className="p-4 border-t border-white/10">
          <div className="flex items-center gap-3 px-4 py-2 mb-3">
            <div className="w-8 h-8 bg-blue-600 rounded-full flex items-center justify-center text-sm font-bold">
              {user?.nom?.charAt(0) || 'A'}
            </div>
            <div className="flex-1 min-w-0">
              <p className="text-sm font-medium truncate">{user?.nom || 'Admin'}</p>
              <p className="text-xs text-slate-400">{user?.role}</p>
            </div>
          </div>
          <button onClick={logout} className="flex items-center gap-3 px-4 py-2 w-full text-slate-300 hover:text-red-400 rounded-lg">
            <LogOut size={18} /><span>Deconnexion</span>
          </button>
        </div>
      </aside>
    </>
  );
}
