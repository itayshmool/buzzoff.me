import { NavLink } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { useTheme } from '../../contexts/ThemeContext';

const links = [
  { to: '/', label: 'HQ' },
  { to: '/countries', label: 'ZONES' },
  { to: '/geocoding', label: 'LOCATE' },
  { to: '/jobs', label: 'OPS' },
  { to: '/developers', label: 'DEVS' },
  { to: '/developers/submissions', label: 'QUEUE' },
];

interface SidebarProps {
  isOpen: boolean;
  onClose: () => void;
}

export default function Sidebar({ isOpen, onClose }: SidebarProps) {
  const { logout } = useAuth();
  const { theme, toggle } = useTheme();

  return (
    <>
      {/* Backdrop (mobile only) */}
      {isOpen && (
        <div
          className="fixed inset-0 z-40 bg-black/60 backdrop-blur-sm md:hidden"
          onClick={onClose}
        />
      )}

      <aside
        className={`
          fixed inset-y-0 left-0 z-50 w-56 bg-surface-raised border-r border-border flex flex-col
          transform transition-transform duration-200 ease-in-out
          ${isOpen ? 'translate-x-0' : '-translate-x-full'}
          md:translate-x-0 md:sticky md:top-0 md:h-screen
        `}
      >
        {/* Logo */}
        <div className="px-5 py-5 border-b border-border flex items-center justify-between">
          <div>
            <div className="font-heading text-xl font-black tracking-wider text-neon text-glow-neon">
              BUZZ<span className="text-hot">OFF</span>
            </div>
            <div className="font-mono text-[10px] text-text-muted tracking-[0.3em] mt-0.5">
              COMMAND CENTER
            </div>
          </div>
          {/* Close button (mobile only) */}
          <button
            onClick={onClose}
            className="p-1 text-text-muted hover:text-text-primary md:hidden transition-colors"
            aria-label="Close menu"
          >
            <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Nav */}
        <nav className="flex-1 py-4 px-3 space-y-1">
          {links.map(({ to, label }) => (
            <NavLink
              key={to}
              to={to}
              end={to === '/'}
              onClick={onClose}
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
        <div className="px-5 py-4 space-y-2">
          <button
            onClick={toggle}
            className="w-full px-3 py-2 text-xs font-heading tracking-wider text-text-muted hover:text-neon transition-colors border border-border hover:border-neon/40 flex items-center justify-center gap-2"
          >
            {theme === 'dark' ? (
              <>
                <svg xmlns="http://www.w3.org/2000/svg" className="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
                </svg>
                DAY MODE
              </>
            ) : (
              <>
                <svg xmlns="http://www.w3.org/2000/svg" className="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
                </svg>
                NIGHT MODE
              </>
            )}
          </button>
          <button
            onClick={logout}
            className="w-full px-3 py-2 text-xs font-heading tracking-wider text-text-muted hover:text-danger transition-colors border border-border hover:border-danger/40"
          >
            EJECT
          </button>
        </div>
      </aside>
    </>
  );
}
