import { useState, type FormEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

export default function LoginPage() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await login(username.trim(), password.trim());
      navigate('/');
    } catch {
      setError('Invalid credentials');
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-carbon relative overflow-hidden">
      {/* Animated background lines */}
      <div className="absolute inset-0 pointer-events-none">
        <div className="absolute top-1/4 left-0 right-0 h-px bg-gradient-to-r from-transparent via-neon/20 to-transparent" />
        <div className="absolute top-2/4 left-0 right-0 h-px bg-gradient-to-r from-transparent via-hot/10 to-transparent" />
        <div className="absolute top-3/4 left-0 right-0 h-px bg-gradient-to-r from-transparent via-neon/10 to-transparent" />
      </div>

      <form
        onSubmit={handleSubmit}
        className="relative bg-surface-card border border-border p-8 w-full max-w-sm clip-angular animate-fade-up"
      >
        {/* Neon top accent */}
        <div className="absolute top-0 left-0 right-0 h-0.5 bg-gradient-to-r from-neon via-hot to-neon" />

        <div className="text-center mb-8">
          <h1 className="font-heading text-2xl font-black tracking-wider text-neon text-glow-neon">
            BUZZ<span className="text-hot">OFF</span>
          </h1>
          <div className="font-mono text-[10px] text-text-muted tracking-[0.4em] mt-1">
            COMMAND CENTER ACCESS
          </div>
        </div>

        {error && (
          <div className="mb-4 p-3 bg-danger/10 text-danger border border-danger/20 text-sm font-mono">
            {error}
          </div>
        )}

        <label className="block mb-4">
          <span className="text-xs font-heading tracking-wider text-text-muted uppercase">
            Callsign
          </span>
          <input
            type="text"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            className="mt-1 block w-full bg-surface-raised border border-border px-3 py-2.5 text-sm text-text-primary font-mono focus:border-neon focus:outline-none transition-colors"
            required
          />
        </label>

        <label className="block mb-6">
          <span className="text-xs font-heading tracking-wider text-text-muted uppercase">
            Access Key
          </span>
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            className="mt-1 block w-full bg-surface-raised border border-border px-3 py-2.5 text-sm text-text-primary font-mono focus:border-neon focus:outline-none transition-colors"
            required
          />
        </label>

        <button
          type="submit"
          disabled={loading}
          className="w-full bg-neon text-surface font-heading font-bold tracking-wider py-2.5 text-sm hover:bg-neon-dim disabled:opacity-50 transition-colors glow-neon"
        >
          {loading ? 'AUTHENTICATING...' : 'ENGAGE'}
        </button>
      </form>
    </div>
  );
}
