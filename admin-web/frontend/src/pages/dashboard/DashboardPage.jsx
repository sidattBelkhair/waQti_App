import { useState, useEffect } from 'react';
import StatCard from '../../components/ui/StatCard';
import { Building2, Users, Ticket, AlertTriangle } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from 'recharts';
import { adminAPI } from '../../services/api';

const COLORS = ['#1565C0', '#2E7D32', '#E65100', '#C62828', '#6A1B9A'];

export default function DashboardPage() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    loadStats();
  }, []);

  const loadStats = async () => {
    try {
      const res = await adminAPI.getStats();
      setStats(res.data.stats);
    } catch (err) {
      setError('Erreur de chargement des stats');
      console.error(err);
    }
    setLoading(false);
  };

  if (loading) return <div className="p-8 text-center text-slate-400">Chargement des statistiques...</div>;
  if (error) return <div className="p-8 text-center text-red-500">{error}</div>;
  if (!stats) return null;

  return (
    <div className="p-8">
      <h2 className="text-2xl font-bold text-slate-800 mb-6">Dashboard</h2>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        <StatCard title="Etablissements actifs" value={stats.etablissements.actifs} icon={Building2} color="blue" />
        <StatCard title="Utilisateurs" value={stats.users.total} icon={Users} color="green" />
        <StatCard title="Tickets aujourd'hui" value={stats.tickets.aujourdHui} icon={Ticket} color="purple" />
        <StatCard title="En attente validation" value={stats.etablissements.enAttente} icon={AlertTriangle} color="orange" />
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-4 gap-4 mb-8">
        <div className="bg-white rounded-xl border border-slate-200 p-4 text-center">
          <p className="text-sm text-slate-500">Total etablissements</p>
          <p className="text-2xl font-bold text-slate-800">{stats.etablissements.total}</p>
        </div>
        <div className="bg-white rounded-xl border border-slate-200 p-4 text-center">
          <p className="text-sm text-slate-500">Suspendus</p>
          <p className="text-2xl font-bold text-red-600">{stats.etablissements.suspendus}</p>
        </div>
        <div className="bg-white rounded-xl border border-slate-200 p-4 text-center">
          <p className="text-sm text-slate-500">Tickets semaine</p>
          <p className="text-2xl font-bold text-slate-800">{stats.tickets.semaine}</p>
        </div>
        <div className="bg-white rounded-xl border border-slate-200 p-4 text-center">
          <p className="text-sm text-slate-500">Tickets mois</p>
          <p className="text-2xl font-bold text-slate-800">{stats.tickets.mois}</p>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
        <div className="lg:col-span-2 bg-white rounded-xl border border-slate-200 p-6">
          <h3 className="text-lg font-semibold text-slate-800 mb-4">Tickets (7 derniers jours)</h3>
          <ResponsiveContainer width="100%" height={300}>
            <BarChart data={stats.ticketsParJour}>
              <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
              <XAxis dataKey="jour" /><YAxis /><Tooltip />
              <Bar dataKey="tickets" fill="#1565C0" radius={[6, 6, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
        <div className="bg-white rounded-xl border border-slate-200 p-6">
          <h3 className="text-lg font-semibold text-slate-800 mb-4">Etablissements par ville</h3>
          <ResponsiveContainer width="100%" height={300}>
            <PieChart>
              <Pie data={stats.parVille} dataKey="value" nameKey="name" cx="50%" cy="50%" outerRadius={100}
                label={({name, percent}) => `${name} ${(percent*100).toFixed(0)}%`}>
                {stats.parVille.map((_, i) => <Cell key={i} fill={COLORS[i % COLORS.length]} />)}
              </Pie>
              <Tooltip />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>

      {stats.topEtablissements.length > 0 && (
        <div className="bg-white rounded-xl border border-slate-200 p-6">
          <h3 className="text-lg font-semibold text-slate-800 mb-4">Top Etablissements</h3>
          <div className="space-y-3">
            {stats.topEtablissements.map((e, i) => (
              <div key={i} className="flex items-center justify-between py-2">
                <div className="flex items-center gap-3">
                  <span className="w-8 h-8 bg-blue-100 text-blue-600 rounded-lg flex items-center justify-center text-sm font-bold">{i + 1}</span>
                  <span className="text-sm font-medium text-slate-700">{e.nom || 'Inconnu'}</span>
                  <span className="text-xs text-slate-400">{e.type}</span>
                </div>
                <span className="text-sm font-bold text-slate-800">{e.totalTickets} tickets</span>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
