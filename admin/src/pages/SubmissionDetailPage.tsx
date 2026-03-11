import { useState } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getSubmission, approveSubmission, rejectSubmission } from '../api/developers';
import StatusBadge from '../components/common/StatusBadge';

export default function SubmissionDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [rejectNote, setRejectNote] = useState('');
  const [showReject, setShowReject] = useState(false);

  const { data: submission, isLoading } = useQuery({
    queryKey: ['submission', id],
    queryFn: () => getSubmission(id!),
    enabled: !!id,
  });

  const approveMutation = useMutation({
    mutationFn: () => approveSubmission(id!),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['submission', id] });
      queryClient.invalidateQueries({ queryKey: ['submissions'] });
    },
  });

  const rejectMutation = useMutation({
    mutationFn: () => rejectSubmission(id!, rejectNote),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['submission', id] });
      queryClient.invalidateQueries({ queryKey: ['submissions'] });
      setShowReject(false);
    },
  });

  if (isLoading || !submission) {
    return <p className="text-sm text-text-muted font-mono">Loading...</p>;
  }

  const isPending = submission.status === 'pending';

  return (
    <div>
      <button
        onClick={() => navigate('/developers/submissions')}
        className="text-xs font-heading tracking-wider text-text-muted hover:text-neon transition-colors mb-4 inline-block"
      >
        &larr; BACK TO GRID
      </button>

      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 mb-6">
        <h1 className="font-heading text-xl md:text-2xl font-bold tracking-wider text-text-primary">
          SUBMISSION <span className="text-neon text-glow-neon">DETAIL</span>
        </h1>
        <StatusBadge status={submission.status} />
      </div>

      {/* Info grid */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
        <div className="bg-surface-card border border-border p-4">
          <div className="text-xs font-heading tracking-wider text-text-muted uppercase mb-1">Developer</div>
          <div className="text-sm font-semibold text-text-primary">{submission.developer_name}</div>
          <div className="text-xs text-text-muted">{submission.developer_email}</div>
        </div>
        <div className="bg-surface-card border border-border p-4">
          <div className="text-xs font-heading tracking-wider text-text-muted uppercase mb-1">Country</div>
          <div className="text-sm font-semibold text-text-primary">{submission.country_code}</div>
        </div>
        <div className="bg-surface-card border border-border p-4">
          <div className="text-xs font-heading tracking-wider text-text-muted uppercase mb-1">Cameras</div>
          <div className="text-sm font-semibold text-neon">{submission.camera_count}</div>
        </div>
      </div>

      {submission.review_note && (
        <div className="bg-danger/5 border border-danger/30 p-4 mb-6">
          <div className="text-xs font-heading tracking-wider text-danger uppercase mb-1">Review Note</div>
          <div className="text-sm text-text-primary">{submission.review_note}</div>
        </div>
      )}

      {/* Action buttons */}
      {isPending && (
        <div className="flex flex-wrap gap-3 mb-6">
          <button
            onClick={() => approveMutation.mutate()}
            disabled={approveMutation.isPending}
            className="px-6 py-2 text-xs font-heading tracking-wider bg-success text-white hover:bg-success/80 transition-colors disabled:opacity-50"
          >
            {approveMutation.isPending ? 'APPROVING...' : 'APPROVE'}
          </button>
          <button
            onClick={() => setShowReject(!showReject)}
            className="px-6 py-2 text-xs font-heading tracking-wider bg-danger text-white hover:bg-danger/80 transition-colors"
          >
            REJECT
          </button>
        </div>
      )}

      {approveMutation.isSuccess && (
        <div className="bg-success/10 border border-success/30 p-4 mb-6">
          <div className="text-sm text-success font-heading tracking-wider">
            Approved — {approveMutation.data?.cameras_inserted} cameras inserted into pipeline
          </div>
        </div>
      )}

      {showReject && isPending && (
        <div className="bg-surface-card border border-border p-4 mb-6">
          <textarea
            value={rejectNote}
            onChange={(e) => setRejectNote(e.target.value)}
            placeholder="Rejection reason..."
            rows={3}
            className="w-full bg-surface-raised border border-border px-3 py-2 text-sm text-text-primary placeholder-text-muted focus:border-danger focus:outline-none mb-3"
          />
          <button
            onClick={() => rejectMutation.mutate()}
            disabled={!rejectNote.trim() || rejectMutation.isPending}
            className="px-6 py-2 text-xs font-heading tracking-wider bg-danger text-white hover:bg-danger/80 transition-colors disabled:opacity-50"
          >
            {rejectMutation.isPending ? 'REJECTING...' : 'CONFIRM REJECT'}
          </button>
        </div>
      )}

      {/* Camera data table */}
      <div className="bg-surface-card border border-border neon-top">
        <div className="px-4 py-3 border-b border-border">
          <h2 className="font-heading text-sm font-semibold tracking-wider text-text-muted uppercase">
            Camera Data ({submission.cameras_json.length})
          </h2>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-border">
                <th className="text-left py-3 px-4 font-heading text-xs font-medium tracking-wider text-text-muted uppercase">#</th>
                <th className="text-left py-3 px-4 font-heading text-xs font-medium tracking-wider text-text-muted uppercase">Lat</th>
                <th className="text-left py-3 px-4 font-heading text-xs font-medium tracking-wider text-text-muted uppercase">Lon</th>
                <th className="text-left py-3 px-4 font-heading text-xs font-medium tracking-wider text-text-muted uppercase">Type</th>
                <th className="text-left py-3 px-4 font-heading text-xs font-medium tracking-wider text-text-muted uppercase">Speed</th>
                <th className="text-left py-3 px-4 font-heading text-xs font-medium tracking-wider text-text-muted uppercase">Road</th>
                <th className="text-left py-3 px-4 font-heading text-xs font-medium tracking-wider text-text-muted uppercase">Address</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-border/50">
              {submission.cameras_json.map((cam, i) => (
                <tr key={i}>
                  <td className="py-3 px-4 text-text-muted font-mono text-xs">{i + 1}</td>
                  <td className="py-3 px-4 text-text-primary font-mono text-xs">{String(cam.lat ?? '-')}</td>
                  <td className="py-3 px-4 text-text-primary font-mono text-xs">{String(cam.lon ?? '-')}</td>
                  <td className="py-3 px-4 text-text-primary">{String(cam.type ?? 'fixed_speed')}</td>
                  <td className="py-3 px-4 text-text-primary">{String(cam.speed_limit ?? '-')}</td>
                  <td className="py-3 px-4 text-text-primary">{String(cam.road_name ?? '-')}</td>
                  <td className="py-3 px-4 text-text-primary">{String(cam.address ?? '-')}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
