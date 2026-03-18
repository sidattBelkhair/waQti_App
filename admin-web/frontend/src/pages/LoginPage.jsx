import { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { Clock } from 'lucide-react';

export default function LoginPage() {
  const { login, verifyOTP } = useAuth();
  const [step, setStep] = useState('login');
  const [identifier, setIdentifier] = useState('');
  const [motDePasse, setMotDePasse] = useState('');
  const [userId, setUserId] = useState('');
  const [otp, setOtp] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleLogin = async (e) => {
    e.preventDefault();
    setError(''); setLoading(true);
    try {
      const data = await login(identifier, motDePasse);
      setUserId(data.userId);
      setStep('otp');
    } catch (err) { setError(err.response?.data?.error || 'Erreur de connexion'); }
    setLoading(false);
  };

  const handleOTP = async (e) => {
    e.preventDefault();
    setError(''); setLoading(true);
    try { await verifyOTP(userId, otp); }
    catch (err) { setError(err.response?.data?.error || 'Code incorrect'); }
    setLoading(false);
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-blue-900 to-slate-900 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-md p-8">
        <div className="text-center mb-8">
          <div className="w-16 h-16 bg-blue-600 rounded-2xl flex items-center justify-center mx-auto mb-4">
            <Clock className="text-white" size={32} />
          </div>
          <h1 className="text-2xl font-bold text-slate-800">WaQti Admin</h1>
          <p className="text-slate-500 mt-1">{step === 'login' ? 'Connectez-vous' : 'Entrez le code OTP'}</p>
        </div>
        {error && <div className="bg-red-50 text-red-600 px-4 py-3 rounded-lg mb-4 text-sm">{error}</div>}
        {step === 'login' ? (
          <form onSubmit={handleLogin} className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Email ou Telephone</label>
              <input type="text" value={identifier} onChange={(e) => setIdentifier(e.target.value)}
                className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none" placeholder="admin@waqti.mr" required />
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-700 mb-1">Mot de passe</label>
              <input type="password" value={motDePasse} onChange={(e) => setMotDePasse(e.target.value)}
                className="w-full px-4 py-3 border border-slate-300 rounded-lg focus:ring-2 focus:ring-blue-500 outline-none" placeholder="********" required />
            </div>
            <button type="submit" disabled={loading} className="w-full bg-blue-600 text-white py-3 rounded-lg font-medium hover:bg-blue-700 disabled:opacity-50">
              {loading ? 'Connexion...' : 'Se connecter'}
            </button>
          </form>
        ) : (
          <form onSubmit={handleOTP} className="space-y-4">
            <p className="text-sm text-slate-500 text-center">Code a 6 chiffres envoye par SMS</p>
            <input type="text" value={otp} onChange={(e) => setOtp(e.target.value)} maxLength={6}
              className="w-full px-4 py-4 border border-slate-300 rounded-lg text-center text-2xl tracking-widest font-mono focus:ring-2 focus:ring-blue-500 outline-none" placeholder="000000" required />
            <button type="submit" disabled={loading} className="w-full bg-blue-600 text-white py-3 rounded-lg font-medium hover:bg-blue-700 disabled:opacity-50">
              {loading ? 'Verification...' : 'Verifier'}
            </button>
            <button type="button" onClick={() => { setStep('login'); setOtp(''); setError(''); }} className="w-full text-slate-500 text-sm hover:text-slate-700">
              Retour
            </button>
          </form>
        )}
      </div>
    </div>
  );
}
