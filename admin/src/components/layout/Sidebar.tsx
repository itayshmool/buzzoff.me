import { NavLink } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';

const links = [
  { to: '/', label: 'HQ' },
  { to: '/countries', label: 'ZONES' },
  { to: '/geocoding', label: 'LOCATE' },
  { to: '/jobs', label: 'OPS' },
];

export default function Sidebar() {
  const { logout } = useAuth();

  return (
    <aside className="w-56 bg-surface-raised border-r border-border flex flex-col h-screen sticky top-0">
      {/* Logo */}
      <div className="px-5 py-5 border-b border-border">
        <div className="font-heading text-xl font-black tracking-wider text-neon text-glow-neon">
          BUZZ<span className="text-hot">OFF</span>
        </div>
        <div className="font-mono text-[10px] text-text-muted tracking-[0.3em] mt-0.5">
          COMMAND CENTER
        </div>
      </div>

      {/* Nav */}
      <nav className="flex-1 py-4 px-3 space-y-1">
        {links.map(({ to, label }) => (
          <NavLink
            key={to}
            to={to}
            end={to === '/'}
            className={({ isActive }) =>
              `flex items-center gap-3 px-3 py-2.5 text-sm font-semibold tracking-wider transition-all duration-150 ${
                isActive
                  ? 'bg-neon-subtle text-neon border-l-2 border-neon'
                  : 'text-text-secondary hover:text-text-primary hover:bg-surface-hover border-l-2 border-transparent'
              }`
            }
          >
            <span className="font-heading text-xs">{label}</span>
          </NavLink>
        ))}
      </nav>

      {/* Speed line decoration */}
      <div className="px-5 py-1">
        <div className="h-px bg-gradient-to-r from-transparent via-neon/30 to-transparent" />
      </div>

      {/* Footer */}
      <div className="px-5 py-4">
        <button
          onClick={logout}
          className="w-full px-3 py-2 text-xs font-heading tracking-wider text-text-muted hover:text-danger transition-colors border border-border hover:border-danger/40"
        >
          EJECT
        </button>
      </div>
    </aside>
  );
}
