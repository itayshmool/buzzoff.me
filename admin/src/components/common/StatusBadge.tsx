const colors: Record<string, string> = {
  true: 'bg-green-100 text-green-800',
  enabled: 'bg-green-100 text-green-800',
  completed: 'bg-green-100 text-green-800',
  false: 'bg-red-100 text-red-800',
  disabled: 'bg-red-100 text-red-800',
  failed: 'bg-red-100 text-red-800',
  running: 'bg-yellow-100 text-yellow-800',
  pending: 'bg-yellow-100 text-yellow-800',
};

interface StatusBadgeProps {
  status: string | boolean;
}

export default function StatusBadge({ status }: StatusBadgeProps) {
  const key = String(status).toLowerCase();
  const colorClass = colors[key] ?? 'bg-slate-100 text-slate-800';
  return (
    <span className={`inline-block px-2 py-0.5 rounded text-xs font-medium ${colorClass}`}>
      {String(status)}
    </span>
  );
}
