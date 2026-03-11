import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { getStats } from '../api/dashboard';
import { getJobs } from '../api/jobs';
import StatCard from '../components/common/StatCard';
import StatusBadge from '../components/common/StatusBadge';

const APK_PATH = '/buzzoff.apk';

export default function DashboardPage() {
  const { data: stats } = useQuery({ queryKey: ['dashboard-stats'], queryFn: getStats });
  const { data: jobs } = useQuery({
    queryKey: ['jobs', 'recent'],
    queryFn: () => getJobs(undefined, 10),
  });

  const [copied, setCopied] = useState(false);
  const downloadUrl = `${window.location.origin}${APK_PATH}`;

  function copyLink() {
    navigator.clipboard.writeText(downloadUrl).then(() => {
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    });
  }

  async function shareLink() {
    if (navigator.share) {
      try {
        await navigator.share({
          title: 'BuzzOff',
          text: 'Download BuzzOff — speed camera alerts for your drive.',
          url: downloadUrl,
        });
      } catch {
        // User cancelled share
      }
    } else {
      copyLink();
    }
  }

  return (
    <div>
      <h1 className="font-heading text-2xl font-bold tracking-wider text-text-primary mb-6">
        RACE <span className="text-neon text-glow-neon">HQ</span>
      </h1>

      <div className="grid grid-cols-2 lg:grid-cols-3 gap-4 mb-8 stagger-children">
        <StatCard label="Tracks" value={stats?.countries ?? '...'} />
        <StatCard label="Data Feeds" value={stats?.sources ?? '...'} />
        <StatCard label="Item Boxes" value={stats?.cameras?.toLocaleString() ?? '...'} />
        <StatCard label="Packs" value={stats?.packs ?? '...'} />
        <StatCard label="Driver Keys" value={stats?.developer_keys ?? '...'} />
        <StatCard label="Pending Subs" value={stats?.pending_submissions ?? '...'} />
      </div>

      {/* App Distribution */}
      <div className="bg-surface-card border border-border p-6 mb-8 hot-top">
        <h2 className="font-heading text-sm font-semibold tracking-wider text-text-muted uppercase mb-4">
          App Distribution
        </h2>
        <div className="flex items-center gap-4 flex-wrap">
          <div className="flex-1 min-w-0">
            <div className="text-sm text-text-secondary mb-1">Android APK download link</div>
            <div className="flex items-center gap-2">
              <code className="flex-1 min-w-0 truncate bg-surface-raised border border-border px-3 py-2 text-xs font-mono text-neon">
                {downloadUrl}
              </code>
            </div>
          </div>
          <div className="flex gap-2 shrink-0">
            <button
              onClick={copyLink}
              className="px-4 py-2 text-xs font-heading tracking-wider border border-border text-text-secondary hover:border-neon/40 hover:text-neon transition-colors"
            >
              {copied ? 'COPIED' : 'COPY LINK'}
            </button>
            <button
              onClick={shareLink}
              className="px-4 py-2 text-xs font-heading tracking-wider bg-hot text-white hover:bg-hot-dim transition-colors glow-hot"
            >
              SHARE
            </button>
            <a
              href={APK_PATH}
              download="buzzoff.apk"
              className="px-4 py-2 text-xs font-heading tracking-wider bg-neon text-surface hover:bg-neon-dim transition-colors glow-neon"
            >
              DOWNLOAD
            </a>
          </div>
        </div>
      </div>

      {/* Operations Log */}
      <div className="bg-surface-card border border-border p-6 neon-top">
        <h2 className="font-heading text-sm font-semibold tracking-wider text-text-muted uppercase mb-4">
          Lap Log
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
          <p className="text-sm text-text-muted font-mono">No recent laps</p>
        )}
      </div>
    </div>
  );
}
