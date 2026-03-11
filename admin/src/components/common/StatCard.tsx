interface StatCardProps {
  label: string;
  value: string | number;
}

export default function StatCard({ label, value }: StatCardProps) {
  return (
    <div className="bg-surface-card border border-border neon-top p-5 clip-angular animate-fade-up">
      <div className="font-heading text-2xl font-bold text-neon text-glow-neon tracking-wider">
        {value}
      </div>
      <div className="text-xs font-heading tracking-[0.2em] text-text-muted mt-2 uppercase">
        {label}
      </div>
    </div>
  );
}
