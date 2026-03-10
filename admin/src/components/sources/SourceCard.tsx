import type { Source } from '../../types';
import StatusBadge from '../common/StatusBadge';

interface SourceCardProps {
  source: Source;
  onEdit: () => void;
  onDelete: () => void;
}

export default function SourceCard({ source, onEdit, onDelete }: SourceCardProps) {
  return (
    <div className="border border-slate-200 rounded-lg p-4">
      <div className="flex items-start justify-between">
        <div>
          <div className="font-medium text-slate-800">{source.name}</div>
          <div className="flex items-center gap-2 mt-1">
            <span className="text-xs bg-slate-100 text-slate-600 px-2 py-0.5 rounded">
              {source.adapter}
            </span>
            <StatusBadge status={source.enabled ? 'enabled' : 'disabled'} />
          </div>
        </div>
        <div className="flex gap-2">
          <button
            onClick={onEdit}
            className="text-xs text-blue-600 hover:text-blue-800"
          >
            Edit
          </button>
          <button
            onClick={onDelete}
            className="text-xs text-red-600 hover:text-red-800"
          >
            Delete
          </button>
        </div>
      </div>
      <div className="mt-3 text-sm text-slate-500 flex gap-4">
        {source.schedule && <span>Schedule: {source.schedule}</span>}
        <span>Confidence: {source.confidence}</span>
      </div>
    </div>
  );
}
