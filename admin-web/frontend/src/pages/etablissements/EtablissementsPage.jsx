import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import DataTable from '../../components/ui/DataTable';
import StatusBadge from '../../components/ui/StatusBadge';
import { Building2, Filter, CheckCircle, XCircle, Trash2 } from 'lucide-react';
import { adminAPI } from '../../services/api';

export default function EtablissementsPage() {
  const navigate = useNavigate();
  const [etablissements, setEtablissements] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filters, setFilters] = useState({ ville: '', type: '', statut: '' });
  const [total, setTotal] = useState(0);

  useEffect(() => { loadData(); }, []);

  const loadData = async () => {
    setLoading(true);
    try {
      const res = await adminAPI.getEtablissements(filters);
      setEtablissements(res.data.etablissements || []);
      setTotal(res.data.pagination?.total || 0);
    } catch (e) { console.error(e); }
    setLoading(false);
  };

  const changeStatut = async (id, statut, e) => {
    e.stopPropagation();
    try {
      await adminAPI.updateEtabStatut(id, statut);
      loadData();
    } catch (err) { console.error(err); }
  };

  const supprimer = async (id, e) => {
    e.stopPropagation();
    if (!confirm('Supprimer cet etablissement ?')) return;
    try {
      await adminAPI.deleteEtablissement(id);
      loadData();
    } catch (err) { console.error(err); }
  };

  const columns = [
    { key: 'nom', label: 'Etablissement', render: (row) => (
      <div className="flex items-center gap-3">
        <div className="w-10 h-10 bg-blue-100 rounded-lg flex items-center justify-center"><Building2 size={20} className="text-blue-600" /></div>
        <div><p className="font-medium text-slate-800">{row.nom}</p><p className="text-xs text-slate-400">{row.type} | {row.responsable?.nom || '-'}</p></div>
      </div>
    )},
    { key: 'ville', label: 'Ville', render: (row) => row.adresse?.ville || '-' },
    { key: 'statut', label: 'Statut', render: (row) => <StatusBadge status={row.statut} /> },
    { key: 'note', label: 'Note', render: (row) => <span>★ {row.noteMoyenne || 0}/5</span> },
    { key: 'actions', label: 'Actions', render: (row) => (
      <div className="flex gap-2">
        {row.statut === 'en_attente' && (
          <button onClick={(e) => changeStatut(row._id, 'actif', e)} className="p-1.5 bg-green-100 text-green-600 rounded-lg hover:bg-green-200" title="Activer">
            <CheckCircle size={16} />
          </button>
        )}
        {row.statut === 'actif' && (
          <button onClick={(e) => changeStatut(row._id, 'suspendu', e)} className="p-1.5 bg-orange-100 text-orange-600 rounded-lg hover:bg-orange-200" title="Suspendre">
            <XCircle size={16} />
          </button>
        )}
        {row.statut === 'suspendu' && (
          <button onClick={(e) => changeStatut(row._id, 'actif', e)} className="p-1.5 bg-green-100 text-green-600 rounded-lg hover:bg-green-200" title="Reactiver">
            <CheckCircle size={16} />
          </button>
        )}
        <button onClick={(e) => supprimer(row._id, e)} className="p-1.5 bg-red-100 text-red-600 rounded-lg hover:bg-red-200" title="Supprimer">
          <Trash2 size={16} />
        </button>
      </div>
    )},
  ];

  return (
    <div className="p-8">
      <h2 className="text-2xl font-bold text-slate-800 mb-2">Etablissements</h2>
      <p className="text-slate-500 mb-6">{total} etablissement(s) au total</p>
      <div className="flex gap-3 mb-6">
        <select value={filters.statut} onChange={(e) => setFilters({ ...filters, statut: e.target.value })}
          className="px-4 py-2 border border-slate-300 rounded-lg text-sm outline-none">
          <option value="">Tous les statuts</option>
          <option value="actif">Actif</option>
          <option value="en_attente">En attente</option>
          <option value="suspendu">Suspendu</option>
        </select>
        <select value={filters.type} onChange={(e) => setFilters({ ...filters, type: e.target.value })}
          className="px-4 py-2 border border-slate-300 rounded-lg text-sm outline-none">
          <option value="">Tous les types</option>
          <option value="hopital">Hopital</option><option value="banque">Banque</option>
          <option value="ambassade">Ambassade</option><option value="mairie">Mairie</option>
          <option value="poste">Poste</option><option value="telecom">Telecom</option>
        </select>
        <input type="text" placeholder="Ville..." value={filters.ville} onChange={(e) => setFilters({ ...filters, ville: e.target.value })}
          className="px-4 py-2 border border-slate-300 rounded-lg text-sm outline-none" />
        <button onClick={loadData} className="px-4 py-2 bg-blue-600 text-white rounded-lg text-sm hover:bg-blue-700 flex items-center gap-2">
          <Filter size={16} /> Filtrer
        </button>
      </div>
      {loading ? <p className="text-center text-slate-400 py-12">Chargement...</p> :
        <DataTable columns={columns} data={etablissements} onRowClick={(row) => navigate(`/etablissements/${row._id}`)} />
      }
    </div>
  );
}
