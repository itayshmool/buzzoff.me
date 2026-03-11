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

      <div className="bg-surface-card border border-border overflow-x-auto">
        <DataTable
          data={countries}
          columns={columns}
          onRowClick={(c) => navigate(`/countries/${c.code}`)}
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
