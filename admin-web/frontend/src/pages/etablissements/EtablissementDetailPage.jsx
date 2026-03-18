import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import StatusBadge from '../../components/ui/StatusBadge';
import { ArrowLeft, MapPin, Phone, Star, Users } from 'lucide-react';
import { etablissementAPI } from '../../services/api';

export default function EtablissementDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [etab, setEtab] = useState(null);
  const [services, setServices] = useState([]);
  const [personnel, setPersonnel] = useState([]);
  const [avis, setAvis] = useState([]);
  const [tab, setTab] = useState('infos');

  useEffect(() => {
    Promise.all([
      etablissementAPI.getById(id), etablissementAPI.getServices(id),
      etablissementAPI.getPersonnel(id), etablissementAPI.getAvis(id),
    ]).then(([e, s, p, a]) => {
      setEtab(e.data.etablissement); setServices(s.data.services || []);
      setPersonnel(p.data.agents || []); setAvis(a.data.avis || []);
    }).catch(console.error);
  }, [id]);

  if (!etab) return <div className="p-8 text-center text-slate-400">Chargement...</div>;

  return (
    <div className="p-8">
      <button onClick={() => navigate('/etablissements')} className="flex items-center gap-2 text-slate-500 hover:text-slate-700 mb-6">
        <ArrowLeft size={18} /> Retour
      </button>
      <div className="bg-white rounded-xl border border-slate-200 p-6 mb-6">
        <div className="flex items-center gap-3 mb-2">
          <h2 className="text-2xl font-bold text-slate-800">{etab.nom}</h2>
          <StatusBadge status={etab.statut} />
          <span className="px-3 py-1 bg-blue-100 text-blue-700 rounded-full text-sm">{etab.type}</span>
        </div>
        <p className="text-slate-500 mb-3">{etab.description || 'Pas de description'}</p>
        <div className="flex gap-4 text-sm text-slate-600">
          <span className="flex items-center gap-1"><MapPin size={16} />{etab.adresse?.ville}</span>
          <span className="flex items-center gap-1"><Phone size={16} />{etab.telephone}</span>
          <span className="flex items-center gap-1"><Star size={16} className="text-yellow-500" />{etab.noteMoyenne}/5</span>
        </div>
      </div>
      <div className="flex gap-1 mb-6 bg-slate-100 p-1 rounded-lg w-fit">
        {['infos', 'services', 'personnel', 'avis'].map(t => (
          <button key={t} onClick={() => setTab(t)} className={`px-4 py-2 rounded-md text-sm font-medium ${tab === t ? 'bg-white text-blue-600 shadow-sm' : 'text-slate-500'}`}>
            {t === 'infos' ? 'Informations' : t === 'services' ? `Services (${services.length})` : t === 'personnel' ? `Personnel (${personnel.length})` : `Avis (${avis.length})`}
          </button>
        ))}
      </div>
      {tab === 'infos' && etab.horaires && (
        <div className="bg-white rounded-xl border border-slate-200 p-6">
          <h3 className="text-lg font-semibold mb-4">Horaires</h3>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
            {Object.entries(etab.horaires).map(([jour, h]) => (
              <div key={jour} className={`p-3 rounded-lg ${h.ouvert ? 'bg-green-50' : 'bg-slate-50'}`}>
                <p className="text-sm font-medium capitalize">{jour}</p>
                <p className="text-xs text-slate-500">{h.ouvert ? `${h.debut} - ${h.fin}` : 'Ferme'}</p>
              </div>
            ))}
          </div>
        </div>
      )}
      {tab === 'services' && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {services.map(s => (
            <div key={s._id} className="bg-white rounded-xl border border-slate-200 p-5">
              <div className="flex justify-between mb-2"><h4 className="font-semibold">{s.nom}</h4><span className="text-xs bg-blue-100 text-blue-700 px-2 py-1 rounded-full">{s.dureeEstimee} min</span></div>
              <p className="text-sm text-slate-500">{s.description}</p>
            </div>
          ))}
        </div>
      )}
      {tab === 'personnel' && (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {personnel.map(a => (
            <div key={a._id} className="bg-white rounded-xl border border-slate-200 p-5 flex items-center gap-3">
              <div className="w-10 h-10 bg-purple-100 rounded-full flex items-center justify-center"><Users size={18} className="text-purple-600" /></div>
              <div><h4 className="font-semibold">{a.nom}</h4><p className="text-xs text-slate-500">{a.role} - {a.specialite || 'General'}</p></div>
              <StatusBadge status={a.statut} />
            </div>
          ))}
        </div>
      )}
      {tab === 'avis' && (
        <div className="space-y-4">
          {avis.map(a => (
            <div key={a._id} className="bg-white rounded-xl border border-slate-200 p-5">
              <div className="flex items-center gap-3 mb-2">
                <span className="font-medium">{a.utilisateur?.nom || 'Anonyme'}</span>
                <div className="flex">{[1,2,3,4,5].map(n => <Star key={n} size={14} className={n <= a.note ? 'text-yellow-500 fill-yellow-500' : 'text-slate-300'} />)}</div>
              </div>
              <p className="text-sm text-slate-600">{a.commentaire || '-'}</p>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
