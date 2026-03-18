import { useState, useEffect } from 'react';
import DataTable from '../../components/ui/DataTable';
import StatusBadge from '../../components/ui/StatusBadge';
import { Search, CheckCircle, XCircle, Trash2 } from 'lucide-react';
import { adminAPI } from '../../services/api';

export default function UsersPage() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [total, setTotal] = useState(0);
  const [filterRole, setFilterRole] = useState('');

  useEffect(() => { loadData(); }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const params = {};
      if (search) params.nom = search;
      if (filterRole) params.role = filterRole;
      const res = await adminAPI.getUsers(params);
      setUsers(res.data.users || []);
      setTotal(res.data.pagination?.total || 0);
    } catch (e) { console.error(e); }
    setLoading(false);
  };

  const changeStatut = async (id, statut) => {
    try {
      await adminAPI.updateUserStatut(id, statut);
      loadData();
    } catch (err) { console.error(err); }
  };

  const supprimer = async (id) => {
    if (!confirm('Supprimer cet utilisateur ?')) return;
    try {
      await adminAPI.deleteUser(id);
      loadData();
    } catch (err) { console.error(err); }
  };

  const columns = [
    { key: 'nom', label: 'Utilisateur', render: (row) => (
      <div className="flex items-center gap-3">
        <div className="w-9 h-9 bg-blue-100 rounded-full flex items-center justify-center text-blue-600 font-bold text-sm">{row.nom?.charAt(0) || '?'}</div>
        <div><p className="font-medium">{row.nom}</p><p className="text-xs text-slate-400">{row.email}</p></div>
      </div>
    )},
    { key: 'telephone', label: 'Telephone' },
    { key: 'role', label: 'Role', render: (row) => (
      <span className={`px-2 py-1 rounded-full text-xs font-medium ${
        row.role === 'admin' ? 'bg-purple-100 text-purple-700' :
        row.role === 'gestionnaire' ? 'bg-blue-100 text-blue-700' : 'bg-slate-100 text-slate-600'
      }`}>{row.role}</span>
    )},
    { key: 'statut', label: 'Statut', render: (row) => <StatusBadge status={row.statut} /> },
    { key: 'date', label: 'Inscription', render: (row) => new Date(row.createdAt).toLocaleDateString('fr') },
    { key: 'actions', label: 'Actions', render: (row) => (
      <div className="flex gap-2">
        {row.statut === 'actif' ? (
          <button onClick={() => changeStatut(row._id, 'suspendu')} className="p-1.5 bg-orange-100 text-orange-600 rounded-lg hover:bg-orange-200" title="Suspendre">
            <XCircle size={16} />
          </button>
        ) : (
          <button onClick={() => changeStatut(row._id, 'actif')} className="p-1.5 bg-green-100 text-green-600 rounded-lg hover:bg-green-200" title="Reactiver">
            <CheckCircle size={16} />
          </button>
        )}
        <button onClick={() => supprimer(row._id)} className="p-1.5 bg-red-100 text-red-600 rounded-lg hover:bg-red-200" title="Supprimer">
          <Trash2 size={16} />
        </button>
      </div>
    )},
  ];

  return (
    <div className="p-8">
      <h2 className="text-2xl font-bold text-slate-800 mb-2">Utilisateurs</h2>
      <p className="text-slate-500 mb-6">{total} utilisateur(s)</p>
      <div className="flex gap-3 mb-6">
        <div className="relative flex-1 max-w-md">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400" size={18} />
          <input type="text" placeholder="Rechercher par nom..." value={search}
            onChange={(e) => setSearch(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && loadData()}
            className="w-full pl-10 pr-4 py-2 border border-slate-300 rounded-lg text-sm outline-none" />
        </div>
        <select value={filterRole} onChange={(e) => setFilterRole(e.target.value)}
          className="px-4 py-2 border border-slate-300 rounded-lg text-sm outline-none">
          <option value="">Tous les roles</option>
          <option value="client">Client</option>
          <option value="gestionnaire">Gestionnaire</option>
          <option value="admin">Admin</option>
        </select>
        <button onClick={loadData} className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm hover:bg-blue-700">
          Rechercher
        </button>
      </div>
      {loading ? <p className="text-center text-slate-400 py-12">Chargement...</p> :
        <DataTable columns={columns} data={users} />
      }
    </div>
  );
}
