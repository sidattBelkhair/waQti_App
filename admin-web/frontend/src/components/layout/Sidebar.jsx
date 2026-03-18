import { NavLink } from 'react-router-dom';
import { LayoutDashboard, Building2, Users, Settings, LogOut, Clock } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';

const links = [
  { to: '/', icon: LayoutDashboard, label: 'Dashboard' },
  { to: '/etablissements', icon: Building2, label: 'Etablissements' },
  { to: '/users', icon: Users, label: 'Utilisateurs' },
  { to: '/config', icon: Settings, label: 'Configuration' },
];

export default function Sidebar() {
  const { logout, user } = useAuth();
  return (
    <aside className="w-64 bg-slate-900 min-h-screen flex flex-col text-white">
      <div className="p-6 border-b border-white/10">
        <div className="flex items-center gap-3">
          <Clock className="w-8 h-8 text-blue-400" />
          <div>
            <h1 className="text-xl font-bold">WaQti</h1>
            <p className="text-xs text-slate-400">Admin Dashboard</p>
          </div>
        </div>
      </div>
      <nav className="flex-1 p-4 space-y-1">
        {links.map(({ to, icon: Icon, label }) => (
          <NavLink key={to} to={to}
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
  );
}
