import { useState } from 'react';
import { Save, Bell, Tag, Timer, CreditCard } from 'lucide-react';

export default function ConfigPage() {
  const [config, setConfig] = useState({ ticketExpiration: 120, maxTickets: 3, maxServices: 20 });
  return (
    <div className="p-8 space-y-6">
      <h2 className="text-2xl font-bold text-slate-800">Configuration</h2>
      <div className="bg-white rounded-xl border border-slate-200 p-6">
        <div className="flex items-center gap-3 mb-4"><Tag size={20} className="text-blue-600" /><h3 className="text-lg font-semibold">Categories</h3></div>
        <div className="flex flex-wrap gap-2">
          {['hopital','banque','ambassade','mairie','poste','telecom','universite'].map(c => (
            <span key={c} className="px-4 py-2 bg-blue-50 text-blue-700 rounded-lg text-sm font-medium capitalize">{c}</span>
          ))}
        </div>
      </div>
      <div className="bg-white rounded-xl border border-slate-200 p-6">
        <div className="flex items-center gap-3 mb-4"><Timer size={20} className="text-orange-600" /><h3 className="text-lg font-semibold">Parametres</h3></div>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div><label className="block text-sm font-medium text-slate-700 mb-1">Expiration ticket (min)</label>
            <input type="number" value={config.ticketExpiration} onChange={(e) => setConfig({...config, ticketExpiration: e.target.value})} className="w-full px-4 py-2 border border-slate-300 rounded-lg outline-none" /></div>
          <div><label className="block text-sm font-medium text-slate-700 mb-1">Max tickets/user</label>
            <input type="number" value={config.maxTickets} onChange={(e) => setConfig({...config, maxTickets: e.target.value})} className="w-full px-4 py-2 border border-slate-300 rounded-lg outline-none" /></div>
          <div><label className="block text-sm font-medium text-slate-700 mb-1">Max services/etab</label>
            <input type="number" value={config.maxServices} onChange={(e) => setConfig({...config, maxServices: e.target.value})} className="w-full px-4 py-2 border border-slate-300 rounded-lg outline-none" /></div>
        </div>
        <button className="mt-4 px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 flex items-center gap-2"><Save size={16} /> Sauvegarder</button>
      </div>
      <div className="bg-white rounded-xl border border-slate-200 p-6">
        <div className="flex items-center gap-3 mb-4"><Bell size={20} className="text-purple-600" /><h3 className="text-lg font-semibold">Notification systeme</h3></div>
        <textarea placeholder="Message a envoyer..." className="w-full px-4 py-3 border border-slate-300 rounded-lg outline-none h-24 resize-none" />
        <button className="mt-3 px-6 py-2 bg-purple-600 text-white rounded-lg hover:bg-purple-700 flex items-center gap-2"><Bell size={16} /> Envoyer</button>
      </div>
      <div className="bg-white rounded-xl border border-slate-200 p-6">
        <div className="flex items-center gap-3 mb-4"><CreditCard size={20} className="text-green-600" /><h3 className="text-lg font-semibold">Abonnements</h3></div>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {[{n:'Gratuit',p:'0 MRU',f:['1 service','50 tickets/jour']},{n:'Standard',p:'5000 MRU/mois',f:['5 services','500 tickets/jour','Stats']},{n:'Premium',p:'15000 MRU/mois',f:['Illimite','Support priorite','Export PDF']}].map(plan => (
            <div key={plan.n} className="border border-slate-200 rounded-lg p-4">
              <h4 className="font-semibold">{plan.n}</h4>
              <p className="text-lg font-bold text-blue-600 mt-1">{plan.p}</p>
              <ul className="mt-3 space-y-1">{plan.f.map(f => <li key={f} className="text-sm text-slate-500">• {f}</li>)}</ul>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
