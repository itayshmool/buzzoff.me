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
      <h1 className="text-2xl font-bold text-slate-800 mb-6">Dashboard</h1>

      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
        <StatCard label="Countries" value={stats?.countries ?? '...'} />
        <StatCard label="Sources" value={stats?.sources ?? '...'} />
        <StatCard label="Cameras" value={stats?.cameras?.toLocaleString() ?? '...'} />
        <StatCard label="Packs" value={stats?.packs ?? '...'} />
      </div>

      <div className="bg-white rounded-lg shadow p-6">
        <h2 className="text-lg font-semibold text-slate-800 mb-4">Recent Activity</h2>
        {jobs && jobs.length > 0 ? (
          <div className="space-y-3">
            {jobs.map((job) => (
              <div
                key={job.id}
                className="flex items-center gap-3 text-sm text-slate-600"
              >
                <span className="text-xs text-slate-400 w-16 shrink-0">
                  {job.started_at
                    ? new Date(job.started_at).toLocaleTimeString([], {
                        hour: '2-digit',
                        minute: '2-digit',
                      })
                    : ''}
                </span>
                <StatusBadge status={job.status} />
                <span className="font-medium text-slate-700">{job.job_type}</span>
                {job.result_summary && (
                  <span className="text-slate-500">{job.result_summary}</span>
                )}
              </div>
            ))}
          </div>
        ) : (
          <p className="text-sm text-slate-500">No recent activity</p>
        )}
      </div>
    </div>
  );
}
