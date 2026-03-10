import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { getJobs } from '../api/jobs';
import DataTable, { type Column } from '../components/common/DataTable';
import StatusBadge from '../components/common/StatusBadge';
import type { JobRun } from '../types';

const JOB_TYPES = ['', 'ingest', 'geocode', 'pack', 'cleanup'];

export default function JobsPage() {
  const [jobType, setJobType] = useState('');

  const { data: jobs = [], isLoading } = useQuery({
    queryKey: ['jobs', jobType],
    queryFn: () => getJobs(jobType || undefined),
    refetchInterval: 30_000,
  });

  const columns: Column<JobRun>[] = [
    { key: 'job_type', header: 'Type' },
    {
      key: 'status',
      header: 'Status',
      render: (j) => <StatusBadge status={j.status} />,
    },
    {
      key: 'started_at',
      header: 'Started',
      render: (j) =>
        j.started_at ? new Date(j.started_at).toLocaleString() : '-',
    },
    {
      key: 'duration',
      header: 'Duration',
      render: (j) => {
        if (!j.started_at || !j.finished_at) return '-';
        const ms =
          new Date(j.finished_at).getTime() - new Date(j.started_at).getTime();
        const secs = Math.round(ms / 1000);
        return secs < 60 ? `${secs}s` : `${Math.floor(secs / 60)}m ${secs % 60}s`;
      },
    },
    {
      key: 'items_processed',
      header: 'Items',
      render: (j) => (j.items_processed != null ? j.items_processed.toLocaleString() : '-'),
    },
    {
      key: 'result_summary',
      header: 'Summary',
      render: (j) => j.result_summary ?? '-',
    },
  ];

  if (isLoading) return <p className="text-sm text-slate-500">Loading...</p>;

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-slate-800">Jobs</h1>
        <select
          value={jobType}
          onChange={(e) => setJobType(e.target.value)}
          className="rounded border border-slate-300 px-3 py-2 text-sm"
        >
          <option value="">All types</option>
          {JOB_TYPES.filter(Boolean).map((t) => (
            <option key={t} value={t}>
              {t}
            </option>
          ))}
        </select>
      </div>

      <div className="bg-white rounded-lg shadow">
        <DataTable data={jobs} columns={columns} emptyMessage="No job runs found" />
      </div>
    </div>
  );
}
