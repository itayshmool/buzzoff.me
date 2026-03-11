import { useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { getSubmissions } from '../api/developers';
import DataTable, { type Column } from '../components/common/DataTable';
import StatusBadge from '../components/common/StatusBadge';
import type { DeveloperSubmission } from '../types';

const STATUSES = ['pending', 'approved', 'rejected'];

export default function SubmissionsPage() {
  const [statusFilter, setStatusFilter] = useState('pending');
  const navigate = useNavigate();

  const { data: submissions = [], isLoading } = useQuery({
    queryKey: ['submissions', statusFilter],
    queryFn: () => getSubmissions(statusFilter || undefined),
    refetchInterval: 15_000,
  });

  const columns: Column<DeveloperSubmission>[] = [
    {
      key: 'developer_name',
      header: 'Developer',
      render: (s) => (
        <div>
          <div className="font-semibold text-text-primary">{s.developer_name}</div>
          <div className="text-xs text-text-muted">{s.developer_email}</div>
        </div>
      ),
    },
    { key: 'country_code', header: 'Country' },
    {
      key: 'camera_count',
      header: 'Cameras',
      render: (s) => s.camera_count.toLocaleString(),
    },
    {
      key: 'status',
      header: 'Status',
      render: (s) => <StatusBadge status={s.status} />,
    },
    {
      key: 'submitted_at',
      header: 'Submitted',
      render: (s) => new Date(s.submitted_at).toLocaleString(),
    },
    {
      key: 'reviewed_at',
      header: 'Reviewed',
      render: (s) => s.reviewed_at ? new Date(s.reviewed_at).toLocaleString() : '-',
    },
  ];

  if (isLoading) return <p className="text-sm text-text-muted font-mono">Loading...</p>;

  return (
    <div>
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 mb-6">
        <h1 className="font-heading text-xl md:text-2xl font-bold tracking-wider text-text-primary">
          SUBMISSION <span className="text-neon text-glow-neon">QUEUE</span>
        </h1>
        <select
          value={statusFilter}
          onChange={(e) => setStatusFilter(e.target.value)}
          className="bg-surface-raised border border-border px-3 py-2 text-sm text-text-primary font-heading tracking-wider focus:border-neon focus:outline-none"
        >
          {STATUSES.map((s) => (
            <option key={s} value={s}>
              {s.toUpperCase()}
            </option>
          ))}
        </select>
      </div>

      <div className="bg-surface-card border border-border overflow-x-auto">
        <DataTable
          data={submissions}
          columns={columns}
          onRowClick={(s) => navigate(`/developers/submissions/${s.id}`)}
          emptyMessage="No submissions"
        />
      </div>
    </div>
  );
}
