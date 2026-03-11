import type { Source } from '../../types';
import StatusBadge from '../common/StatusBadge';

interface SourceCardProps {
  source: Source;
  onEdit: () => void;
  onDelete: () => void;
}

export default function SourceCard({ source, onEdit, onDelete }: SourceCardProps) {
  return (
    <div className="border border-border bg-surface-card p-4 hover:border-neon/30 transition-colors">
      <div className="flex items-start justify-between">
        <div>
          <div className="font-semibold text-text-primary">{source.name}</div>
          <div className="flex items-center gap-2 mt-1">
            <span className="text-xs font-mono bg-surface-hover text-neon-dim px-2 py-0.5 border border-border">
              {source.adapter}
            </span>
            <StatusBadge status={source.enabled ? 'enabled' : 'disabled'} />
          </div>
        </div>
        <div className="flex gap-3">
          <button
            onClick={onEdit}
            className="text-xs font-heading tracking-wider text-neon-dim hover:text-neon transition-colors"
          >
            EDIT
          </button>
          <button
            onClick={onDelete}
            className="text-xs font-heading tracking-wider text-text-muted hover:text-danger transition-colors"
          >
            DEL
          </button>
        </div>
      </div>
      <div className="mt-3 text-sm text-text-muted flex gap-4 font-mono text-xs">
        {source.schedule && <span>sched: {source.schedule}</span>}
        <span>conf: {source.confidence}</span>
      </div>
    </div>
  );
}
