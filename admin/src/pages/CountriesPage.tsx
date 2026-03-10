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
          className="text-xs text-red-600 hover:text-red-800"
        >
          Delete
        </button>
      ),
    },
  ];

  if (isLoading) return <p className="text-sm text-slate-500">Loading...</p>;

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-slate-800">Countries</h1>
        <button
          onClick={() => setShowCreate(true)}
          className="px-4 py-2 text-sm bg-blue-600 text-white rounded hover:bg-blue-700"
        >
          Add Country
        </button>
      </div>

      <div className="bg-white rounded-lg shadow">
        <DataTable
          data={countries}
          columns={columns}
          onRowClick={(c) => navigate(`/countries/${c.code}`)}
        />
      </div>

      {showCreate && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowCreate(false)} />
          <form
            onSubmit={(e) => {
              e.preventDefault();
              createMutation.mutate(form);
            }}
            className="relative bg-white rounded-lg shadow-lg p-6 max-w-sm w-full mx-4"
          >
            <h3 className="text-lg font-semibold text-slate-800 mb-4">Add Country</h3>
            <label className="block mb-3">
              <span className="text-sm font-medium text-slate-700">Code (2 letters)</span>
              <input
                value={form.code}
                onChange={(e) => setForm({ ...form, code: e.target.value.toUpperCase() })}
                maxLength={2}
                required
                className="mt-1 block w-full rounded border border-slate-300 px-3 py-2 text-sm"
              />
            </label>
            <label className="block mb-3">
              <span className="text-sm font-medium text-slate-700">Name</span>
              <input
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
                required
                className="mt-1 block w-full rounded border border-slate-300 px-3 py-2 text-sm"
              />
            </label>
            <label className="block mb-3">
              <span className="text-sm font-medium text-slate-700">Speed Unit</span>
              <select
                value={form.speed_unit}
                onChange={(e) => setForm({ ...form, speed_unit: e.target.value })}
                className="mt-1 block w-full rounded border border-slate-300 px-3 py-2 text-sm"
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
              />
              <span className="text-sm text-slate-700">Enabled</span>
            </label>
            <div className="flex justify-end gap-3">
              <button
                type="button"
                onClick={() => setShowCreate(false)}
                className="px-4 py-2 text-sm rounded border border-slate-300 text-slate-700"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={createMutation.isPending}
                className="px-4 py-2 text-sm rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50"
              >
                Create
              </button>
            </div>
          </form>
        </div>
      )}

      <ConfirmDialog
        isOpen={deleteTarget !== null}
        title="Delete Country"
        message={`Delete country "${deleteTarget}"? This will remove all associated sources, cameras, and packs.`}
        onConfirm={() => deleteTarget && deleteMutation.mutate(deleteTarget)}
        onCancel={() => setDeleteTarget(null)}
      />
    </div>
  );
}
