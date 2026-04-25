import { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { authAPI } from '../services/api';
import { Clock, ShieldCheck, Eye, EyeOff } from 'lucide-react';

export default function LoginPage() {
  const { login } = useAuth();
  const [tab, setTab] = useState('login');

  // Login state
  const [identifier, setIdentifier] = useState('');
  const [motDePasse, setMotDePasse] = useState('');
  const [showMdp, setShowMdp] = useState(false);

  // Create admin state
  const [nom, setNom] = useState('');
  const [tel, setTel] = useState('');
  const [mdp, setMdp] = useState('');
  const [showMdp2, setShowMdp2] = useState(false);
  const [secret, setSecret] = useState('');
  const [showSecret, setShowSecret] = useState(false);
  const [createMsg, setCreateMsg] = useState('');

  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const switchTab = (t) => { setTab(t); setError(''); setCreateMsg(''); };

  const handleLogin = async (e) => {
    e.preventDefault();
    setError(''); setLoading(true);
    try {
      const data = await login(identifier.trim(), motDePasse);
      if (data.user?.role !== 'admin') {
        setError('Accès réservé aux administrateurs.');
        localStorage.clear();
      }
    } catch (err) {
      setError(err.response?.data?.error || 'Identifiants incorrects');
    }
    setLoading(false);
  };

  const handleCreate = async (e) => {
    e.preventDefault();
    setError(''); setCreateMsg(''); setLoading(true);
    try {
      await authAPI.createAdmin({
        nom: nom.trim(),
        telephone: tel.trim(),
        motDePasse: mdp,
        secret: secret.trim(),
      });
      setCreateMsg('✓ Compte admin créé ! Connectez-vous maintenant.');
      setNom(''); setTel(''); setMdp(''); setSecret('');
      setTimeout(() => switchTab('login'), 1500);
    } catch (err) {
      setError(err.response?.data?.error || 'Erreur lors de la création');
    }
    setLoading(false);
  };

  const inputClass = 'w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none text-slate-800';

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md p-8">

        <div className="text-center mb-6">
          <div className="w-16 h-16 bg-blue-600 rounded-2xl flex items-center justify-center mx-auto mb-3">
            <Clock className="text-white" size={32} />
          </div>
          <h1 className="text-2xl font-bold text-slate-800">WaQti Admin</h1>
        </div>

        {/* Tabs */}
        <div className="flex rounded-xl overflow-hidden border border-slate-200 mb-6">
          <button onClick={() => switchTab('login')}
            className={`flex-1 py-2.5 text-sm font-medium transition-colors ${tab === 'login' ? 'bg-blue-600 text-white' : 'text-slate-500 hover:bg-slate-50'}`}>
            Connexion
          </button>
          <button onClick={() => switchTab('create')}
            className={`flex-1 py-2.5 text-sm font-medium transition-colors flex items-center justify-center gap-1.5 ${tab === 'create' ? 'bg-blue-600 text-white' : 'text-slate-500 hover:bg-slate-50'}`}>
            <ShieldCheck size={14} /> Créer admin
          </button>
        </div>

        {createMsg && <div className="bg-green-50 text-green-700 px-4 py-3 rounded-lg mb-4 text-sm font-medium">{createMsg}</div>}
        {error && <div className="bg-red-50 text-red-600 px-4 py-3 rounded-lg mb-4 text-sm">{error}</div>}

        {tab === 'login' ? (
          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Numéro de téléphone</label>
              <input type="tel" value={identifier} onChange={(e) => setIdentifier(e.target.value)}
                className={inputClass} placeholder="Ex: 25XXXXXXX" required />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Mot de passe</label>
              <div className="relative">
                <input type={showMdp ? 'text' : 'password'} value={motDePasse} onChange={(e) => setMotDePasse(e.target.value)}
                  className={inputClass + ' pr-12'} placeholder="••••••••" required />
                <button type="button" onClick={() => setShowMdp(!showMdp)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600">
                  {showMdp ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
            </div>
            <button type="submit" disabled={loading}
              className="w-full bg-blue-600 text-white py-3 rounded-lg font-semibold hover:bg-blue-700 disabled:opacity-50 transition-colors">
              {loading ? 'Connexion...' : 'Se connecter'}
            </button>
          </form>
        ) : (
          <form onSubmit={handleCreate} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Nom complet</label>
              <input type="text" value={nom} onChange={(e) => setNom(e.target.value)}
                className={inputClass} placeholder="Ex: Sidatt Admin" required />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Téléphone</label>
              <input type="tel" value={tel} onChange={(e) => setTel(e.target.value)}
                className={inputClass} placeholder="Ex: 25XXXXXXX" required />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Mot de passe <span className="text-slate-400 font-normal">(min 8 car.)</span></label>
              <div className="relative">
                <input type={showMdp2 ? 'text' : 'password'} value={mdp} onChange={(e) => setMdp(e.target.value)}
                  className={inputClass + ' pr-12'} placeholder="••••••••" required />
                <button type="button" onClick={() => setShowMdp2(!showMdp2)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600">
                  {showMdp2 ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Clé secrète admin</label>
              <div className="relative">
                <input type={showSecret ? 'text' : 'password'} value={secret}
                  onChange={(e) => setSecret(e.target.value)}
                  className={inputClass + ' pr-12 font-mono tracking-wider'}
                  placeholder="Clé secrète" required />
                <button type="button" onClick={() => setShowSecret(!showSecret)}
                  className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600">
                  {showSecret ? <EyeOff size={18} /> : <Eye size={18} />}
                </button>
              </div>
              {showSecret && secret && (
                <p className="mt-1 text-xs text-slate-400">
                  {secret.length} caractère(s) — vérifiez les majuscules et underscores
                </p>
              )}
            </div>
            <button type="submit" disabled={loading}
              className="w-full bg-blue-600 text-white py-3 rounded-lg font-semibold hover:bg-blue-700 disabled:opacity-50 transition-colors">
              {loading ? 'Création...' : 'Créer le compte admin'}
            </button>
          </form>
        )}
      </div>
    </div>
  );
}
