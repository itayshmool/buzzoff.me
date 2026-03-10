import { NavLink } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';

const links = [
  { to: '/', label: 'Dashboard' },
  { to: '/countries', label: 'Countries' },
  { to: '/geocoding', label: 'Geocoding' },
  { to: '/jobs', label: 'Jobs' },
];

export default function Sidebar() {
  const { logout } = useAuth();

  return (
    <aside className="w-60 bg-slate-900 text-white flex flex-col min-h-screen">
      <div className="p-5 text-lg font-bold border-b border-slate-700">BuzzOff Admin</div>
      <nav className="flex-1 py-4">
        {links.map((link) => (
          <NavLink
            key={link.to}
            to={link.to}
            end={link.to === '/'}
            className={({ isActive }) =>
              `block px-5 py-2.5 text-sm ${isActive ? 'bg-slate-800 text-white font-medium' : 'text-slate-300 hover:bg-slate-800 hover:text-white'}`
            }
          >
            {link.label}
          </NavLink>
        ))}
      </nav>
      <button
        onClick={logout}
        className="m-4 px-4 py-2 text-sm text-slate-400 hover:text-white border border-slate-700 rounded hover:border-slate-500"
      >
        Logout
      </button>
    </aside>
  );
}
