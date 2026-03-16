import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getCountries, createCountry, deleteCountry } from '../api/countries';
import DataTable, { type Column } from '../components/common/DataTable';
import StatusBadge from '../components/common/StatusBadge';
import ConfirmDialog from '../components/common/ConfirmDialog';
import type { Country, CountryCreate } from '../types';

export default function CountriesPage() {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const { data: countries = [], isLoading } = useQuery({
    queryKey: ['countries'],
    queryFn: getCountries,
  });

  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState<'all' | 'enabled' | 'disabled'>('all');
  const [showCreate, setShowCreate] = useState(false);
  const [deleteTarget, setDeleteTarget] = useState<string | null>(null);
  const [form, setForm] = useState<CountryCreate>({
    code: '',
    name: '',
    speed_unit: 'kmh',
    enabled: false,
  });

  const createMutation = useMutation({
    mutationFn: createCountry,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['countries'] });
      setShowCreate(false);
      setForm({ code: '', name: '', speed_unit: 'kmh', enabled: false });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: deleteCountry,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['countries'] });
      setDeleteTarget(null);
    },
  });

  const columns: Column<Country>[] = [
    { key: 'code', header: 'Code' },
    { key: 'name', header: 'Name' },
    { key: 'name_local', header: 'Local Name', render: (c) => c.name_local ?? '-' },
    { key: 'speed_unit', header: 'Speed Unit' },
    {
      key: 'enabled',
      header: 'Status',
      render: (c) => <StatusBadge status={c.enabled ? 'enabled' : 'disabled'} />,
    },
    {
      key: 'actions',
      header: '',
      render: (c) => (
        <button
          onClick={(e) => {
            e.stopPropagation();
            setDeleteTarget(c.code);
          }}
          className="text-xs font-heading tracking-wider text-text-muted hover:text-danger transition-colors"
        >
          DEL
        </button>
      ),
    },
  ];

  if (isLoading) return <p className="text-sm text-text-muted font-mono">Loading...</p>;

  const q = search.toLowerCase().trim();
  const filtered = countries.filter((c) => {
    if (statusFilter === 'enabled' && !c.enabled) return false;
    if (statusFilter === 'disabled' && c.enabled) return false;
    if (q && !c.code.toLowerCase().includes(q) && !c.name.toLowerCase().includes(q) && !(c.name_local ?? '').toLowerCase().includes(q)) return false;
    return true;
  });

  const enabledCount = countries.filter((c) => c.enabled).length;
  const disabledCount = countries.length - enabledCount;

  return (
    <div>
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 mb-6">
        <h1 className="font-heading text-xl md:text-2xl font-bold tracking-wider text-text-primary">
          RACE <span className="text-neon text-glow-neon">TRACKS</span>
        </h1>
        <button
          onClick={() => setShowCreate(true)}
          className="px-4 py-2 text-sm font-heading tracking-wider bg-neon text-surface hover:bg-neon-dim transition-colors glow-neon"
        >
          + ADD TRACK
        </button>
      </div>

      {/* Search & Filters */}
      <div className="flex flex-col sm:flex-row gap-3 mb-4">
        <div className="relative flex-1">
          <svg xmlns="http://www.w3.org/2000/svg" className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-text-muted" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
          <input
            type="text"
            placeholder="Search by code or name..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            className="w-full pl-10 pr-3 py-2 bg-surface-raised border border-border text-sm text-text-primary font-mono placeholder:text-text-muted focus:border-neon focus:outline-none transition-colors"
          />
          {search && (
            <button
              onClick={() => setSearch('')}
              className="absolute right-3 top-1/2 -translate-y-1/2 text-text-muted hover:text-text-primary transition-colors"
            >
              <svg xmlns="http://www.w3.org/2000/svg" className="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
              </svg>
            </button>
          )}
        </div>
        <div className="flex gap-2">
          {(['all', 'enabled', 'disabled'] as const).map((f) => (
            <button
              key={f}
              onClick={() => setStatusFilter(f)}
              className={`
                px-3 py-2 text-xs font-heading tracking-wider border transition-all duration-150
                ${statusFilter === f
                  ? 'bg-neon/15 text-neon border-neon/50'
                  : 'bg-surface-raised text-text-secondary border-border hover:border-neon/30 hover:text-text-primary'
                }
              `}
            >
              {f === 'all' ? `ALL (${countries.length})` : f === 'enabled' ? `ON (${enabledCount})` : `OFF (${disabledCount})`}
            </button>
          ))}
        </div>
      </div>

      <div className="bg-surface-card border border-border overflow-x-auto">
        <DataTable
          data={filtered}
          columns={columns}
          onRowClick={(c) => navigate(`/countries/${c.code}`)}
          emptyMessage={search || statusFilter !== 'all' ? 'No tracks match your filters' : 'No tracks yet'}
        />
      </div>

      {showCreate && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          <div className="absolute inset-0 bg-black/70 backdrop-blur-sm" onClick={() => setShowCreate(false)} />
          <form
            onSubmit={(e) => {
              e.preventDefault();
              createMutation.mutate(form);
            }}
            className="relative bg-surface-card border border-neon/30 p-6 max-w-sm w-full mx-4 clip-angular animate-fade-up"
          >
            <div className="absolute top-0 left-0 right-0 h-0.5 bg-gradient-to-r from-neon to-transparent" />
            <h3 className="font-heading text-base font-bold tracking-wider text-neon text-glow-neon uppercase mb-4">
              New Track
            </h3>
            <label className="block mb-3">
              <span className="text-xs font-heading tracking-wider text-text-muted uppercase">Code (2 letters)</span>
              <input
                value={form.code}
                onChange={(e) => setForm({ ...form, code: e.target.value.toUpperCase() })}
                maxLength={2}
                required
                className="mt-1 block w-full bg-surface-raised border border-border px-3 py-2 text-sm text-text-primary font-mono focus:border-neon focus:outline-none"
              />
            </label>
            <label className="block mb-3">
              <span className="text-xs font-heading tracking-wider text-text-muted uppercase">Name</span>
              <input
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
                required
                className="mt-1 block w-full bg-surface-raised border border-border px-3 py-2 text-sm text-text-primary focus:border-neon focus:outline-none"
              />
            </label>
            <label className="block mb-3">
              <span className="text-xs font-heading tracking-wider text-text-muted uppercase">Speed Unit</span>
              <select
                value={form.speed_unit}
                onChange={(e) => setForm({ ...form, speed_unit: e.target.value })}
                className="mt-1 block w-full bg-surface-raised border border-border px-3 py-2 text-sm text-text-primary focus:border-neon focus:outline-none"
              >
                <option value="kmh">km/h</option>
                <option value="mph">mph</option>
              </select>
            </label>
            <label className="flex items-center gap-2 mb-4">
              <input
                type="checkbox"
                checked={form.enabled}
                onChange={(e) => setForm({ ...form, enabled: e.target.checked })}
                className="accent-neon"
              />
              <span className="text-sm text-text-secondary">Enabled</span>
            </label>
            <div className="flex justify-end gap-3">
              <button
                type="button"
                onClick={() => setShowCreate(false)}
                className="px-4 py-2 text-sm font-heading tracking-wider text-text-muted border border-border hover:border-border-bright transition-colors"
              >
                ABORT
              </button>
              <button
                type="submit"
                disabled={createMutation.isPending}
                className="px-4 py-2 text-sm font-heading tracking-wider bg-neon text-surface hover:bg-neon-dim disabled:opacity-50 transition-colors"
              >
                CREATE
              </button>
            </div>
          </form>
        </div>
      )}

      <ConfirmDialog
        isOpen={deleteTarget !== null}
        title="Delete Track"
        message={`Delete track "${deleteTarget}"? This will remove all associated feeds, cameras, and packs.`}
        onConfirm={() => deleteTarget && deleteMutation.mutate(deleteTarget)}
        onCancel={() => setDeleteTarget(null)}
      />
    </div>
  );
}
