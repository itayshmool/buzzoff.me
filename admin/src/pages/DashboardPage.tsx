import { useQuery } from '@tanstack/react-query';
import { getStats } from '../api/dashboard';
import { getJobs } from '../api/jobs';
import StatCard from '../components/common/StatCard';
import StatusBadge from '../components/common/StatusBadge';

export default function DashboardPage() {
  const { data: stats } = useQuery({ queryKey: ['dashboard-stats'], queryFn: getStats });
  const { data: jobs } = useQuery({
    queryKey: ['jobs', 'recent'],
    queryFn: () => getJobs(undefined, 10),
  });

  return (
    <div>
      <h1 className="font-heading text-2xl font-bold tracking-wider text-text-primary mb-6">
        HQ <span className="text-neon text-glow-neon">OVERVIEW</span>
      </h1>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8 stagger-children">
        <StatCard label="Zones" value={stats?.countries ?? '...'} />
        <StatCard label="Sources" value={stats?.sources ?? '...'} />
        <StatCard label="Cameras" value={stats?.cameras?.toLocaleString() ?? '...'} />
        <StatCard label="Packs" value={stats?.packs ?? '...'} />
      </div>

      <div className="bg-surface-card border border-border p-6 neon-top">
        <h2 className="font-heading text-sm font-semibold tracking-wider text-text-muted uppercase mb-4">
          Operations Log
        </h2>
        {jobs && jobs.length > 0 ? (
          <div className="space-y-3">
            {jobs.map((job) => (
              <div
                key={job.id}
                className="flex items-center gap-3 text-sm text-text-secondary"
              >
                <span className="font-mono text-xs text-text-muted w-16 shrink-0">
                  {job.started_at
                    ? new Date(job.started_at).toLocaleTimeString([], {
                        hour: '2-digit',
                        minute: '2-digit',
                      })
                    : ''}
                </span>
                <StatusBadge status={job.status} />
                <span className="font-semibold text-text-primary">{job.job_type}</span>
                {job.result_summary && (
                  <span className="text-text-muted font-mono text-xs">{job.result_summary}</span>
                )}
              </div>
            ))}
          </div>
        ) : (
          <p className="text-sm text-text-muted font-mono">No recent ops</p>
        )}
      </div>
    </div>
  );
}
