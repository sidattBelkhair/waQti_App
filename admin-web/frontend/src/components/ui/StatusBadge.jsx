const styles = { actif: 'bg-green-100 text-green-700', en_attente: 'bg-yellow-100 text-yellow-700', suspendu: 'bg-red-100 text-red-700', termine: 'bg-blue-100 text-blue-700', en_cours: 'bg-purple-100 text-purple-700', annule: 'bg-red-100 text-red-700' };
const labels = { actif: 'Actif', en_attente: 'En attente', suspendu: 'Suspendu', termine: 'Termine', en_cours: 'En cours', annule: 'Annule' };
export default function StatusBadge({ status }) {
  return <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${styles[status] || 'bg-slate-100 text-slate-600'}`}>{labels[status] || status}</span>;
}
