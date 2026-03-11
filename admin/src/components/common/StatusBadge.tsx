const colors: Record<string, string> = {
  true: 'bg-success/10 text-success border-success/30',
  enabled: 'bg-success/10 text-success border-success/30',
  completed: 'bg-success/10 text-success border-success/30',
  approved: 'bg-success/10 text-success border-success/30',
  false: 'bg-danger/10 text-danger border-danger/30',
  disabled: 'bg-danger/10 text-danger border-danger/30',
  failed: 'bg-danger/10 text-danger border-danger/30',
  rejected: 'bg-danger/10 text-danger border-danger/30',
  running: 'bg-warning/10 text-warning border-warning/30',
  pending: 'bg-warning/10 text-warning border-warning/30',
};

interface StatusBadgeProps {
  status: string | boolean;
}

export default function StatusBadge({ status }: StatusBadgeProps) {
  const key = String(status).toLowerCase();
  const colorClass = colors[key] ?? 'bg-border/20 text-text-secondary border-border';
  return (
    <span
      className={`inline-block px-2 py-0.5 text-xs font-heading font-medium tracking-wider border uppercase ${colorClass}`}
    >
      {String(status)}
    </span>
  );
}
