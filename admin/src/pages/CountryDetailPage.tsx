import { useState } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getCountries, updateCountry, deleteCountry } from '../api/countries';
import { getSources, deleteSource } from '../api/sources';
import { getCameras, getCameraStats } from '../api/cameras';
import { getPacks } from '../api/packs';
import CameraMap from '../components/maps/CameraMap';
import StatusBadge from '../components/common/StatusBadge';
import StatCard from '../components/common/StatCard';
import SourceCard from '../components/sources/SourceCard';
import ConfirmDialog from '../components/common/ConfirmDialog';
import type { CountryUpdate } from '../types';

export default function CountryDetailPage() {
  const { code } = useParams<{ code: string }>();
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const [showEdit, setShowEdit] = useState(false);
  const [deleteSourceId, setDeleteSourceId] = useState<string | null>(null);
  const [showDeleteCountry, setShowDeleteCountry] = useState(false);

  const { data: countries = [] } = useQuery({
    queryKey: ['countries'],
    queryFn: getCountries,
  });
  const country = countries.find((c) => c.code === code);

  const { data: sources = [] } = useQuery({
    queryKey: ['sources', code],
    queryFn: () => getSources(code!),
    enabled: !!code,
  });

  const { data: cameraStats } = useQuery({
    queryKey: ['camera-stats', code],
    queryFn: () => getCameraStats(code!),
    enabled: !!code,
  });

  const { data: cameras } = useQuery({
    queryKey: ['cameras', code],
    queryFn: () => getCameras(code!, 500),
    enabled: !!code,
  });

  const { data: packs = [] } = useQuery({
    queryKey: ['packs', code],
    queryFn: () => getPacks(code!),
    enabled: !!code,
  });

  const [editForm, setEditForm] = useState<CountryUpdate>({});

  const updateMutation = useMutation({
    mutationFn: (data: CountryUpdate) => updateCountry(code!, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['countries'] });
      setShowEdit(false);
    },
  });

  const deleteCountryMutation = useMutation({
    mutationFn: () => deleteCountry(code!),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['countries'] });
      navigate('/countries');
    },
  });

  const deleteSourceMutation = useMutation({
    mutationFn: deleteSource,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['sources', code] });
      queryClient.invalidateQueries({ queryKey: ['camera-stats', code] });
      setDeleteSourceId(null);
    },
  });

  function openEdit() {
    if (!country) return;
    setEditForm({
      name: country.name,
      name_local: country.name_local,
      speed_unit: country.speed_unit,
      enabled: country.enabled,
    });
    setShowEdit(true);
  }

  if (!country) {
    return <p className="text-sm text-slate-500">Loading...</p>;
  }

  return (
    <div>
      {/* Header */}
      <div className="flex items-center justify-between mb-6">
        <div>
          <Link to="/countries" className="text-sm text-blue-600 hover:text-blue-800">
            &larr; Countries
          </Link>
          <h1 className="text-2xl font-bold text-slate-800 mt-1">
            {country.name} ({country.code})
          </h1>
          <div className="flex items-center gap-2 mt-1">
            <StatusBadge status={country.enabled ? 'enabled' : 'disabled'} />
            <span className="text-sm text-slate-500">Speed unit: {country.speed_unit}</span>
            {country.name_local && (
              <span className="text-sm text-slate-500">Local: {country.name_local}</span>
            )}
          </div>
        </div>
        <div className="flex gap-2">
          <button
            onClick={openEdit}
            className="px-4 py-2 text-sm rounded border border-slate-300 text-slate-700 hover:bg-slate-50"
          >
            Edit
          </button>
          <button
            onClick={() => setShowDeleteCountry(true)}
            className="px-4 py-2 text-sm rounded bg-red-600 text-white hover:bg-red-700"
          >
            Delete
          </button>
        </div>
      </div>

      {/* Stats Row */}
      <div className="grid grid-cols-3 gap-4 mb-8">
        <StatCard label="Sources" value={sources.length} />
        <StatCard label="Cameras" value={cameraStats?.total.toLocaleString() ?? '...'} />
        <StatCard label="Packs" value={packs.length} />
      </div>

      {/* Camera Stats by Type */}
      {cameraStats && Object.keys(cameraStats.by_type).length > 0 && (
        <div className="bg-white rounded-lg shadow p-6 mb-8">
          <h2 className="text-lg font-semibold text-slate-800 mb-3">Cameras by Type</h2>
          <div className="flex flex-wrap gap-4">
            {Object.entries(cameraStats.by_type).map(([type, count]) => (
              <div key={type} className="text-sm">
                <span className="font-medium text-slate-700">{type}:</span>{' '}
                <span className="text-slate-500">{count.toLocaleString()}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Sources */}
      <div className="mb-8">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-slate-800">Sources</h2>
          <Link
            to={`/countries/${code}/sources/new`}
            className="px-4 py-2 text-sm bg-blue-600 text-white rounded hover:bg-blue-700"
          >
            Add Source
          </Link>
        </div>
        {sources.length === 0 ? (
          <p className="text-sm text-slate-500">No sources configured</p>
        ) : (
          <div className="space-y-3">
            {sources.map((source) => (
              <SourceCard
                key={source.id}
                source={source}
                onEdit={() => navigate(`/countries/${code}/sources/${source.id}`)}
                onDelete={() => setDeleteSourceId(source.id)}
              />
            ))}
          </div>
        )}
      </div>

      {/* Camera Map */}
      {cameras && cameras.items.length > 0 && (
        <div className="bg-white rounded-lg shadow p-6 mb-8">
          <div className="flex items-center justify-between mb-3">
            <h2 className="text-lg font-semibold text-slate-800">Camera Map</h2>
            <Link
              to={`/countries/${code}/cameras`}
              className="px-4 py-2 text-sm bg-blue-600 text-white rounded hover:bg-blue-700"
            >
              Manage Cameras
            </Link>
          </div>
          <CameraMap cameras={cameras.items} />
        </div>
      )}

      {/* Packs */}
      <div className="bg-white rounded-lg shadow mb-8">
        <div className="p-6 pb-0">
          <h2 className="text-lg font-semibold text-slate-800 mb-4">Pack History</h2>
        </div>
        {packs.length === 0 ? (
          <p className="text-sm text-slate-500 p-6 pt-0">No packs generated yet</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-slate-200">
                  <th className="text-left py-3 px-6 font-medium text-slate-600">Version</th>
                  <th className="text-left py-3 px-4 font-medium text-slate-600">Cameras</th>
                  <th className="text-left py-3 px-4 font-medium text-slate-600">Size</th>
                  <th className="text-left py-3 px-4 font-medium text-slate-600">Published</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {packs.map((pack) => (
                  <tr key={pack.id}>
                    <td className="py-3 px-6 text-slate-700 font-medium">v{pack.version}</td>
                    <td className="py-3 px-4 text-slate-700">
                      {pack.camera_count.toLocaleString()}
                    </td>
                    <td className="py-3 px-4 text-slate-500">
                      {(pack.file_size_bytes / 1024).toFixed(1)} KB
                    </td>
                    <td className="py-3 px-4 text-slate-500">
                      {pack.published_at
                        ? new Date(pack.published_at).toLocaleDateString()
                        : 'Not published'}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Edit Country Modal */}
      {showEdit && (
        <div className="fixed inset-0 z-50 flex items-center justify-center">
          <div className="absolute inset-0 bg-black/40" onClick={() => setShowEdit(false)} />
          <form
            onSubmit={(e) => {
              e.preventDefault();
              updateMutation.mutate(editForm);
            }}
            className="relative bg-white rounded-lg shadow-lg p-6 max-w-sm w-full mx-4"
          >
            <h3 className="text-lg font-semibold text-slate-800 mb-4">Edit Country</h3>
            <label className="block mb-3">
              <span className="text-sm font-medium text-slate-700">Name</span>
              <input
                value={editForm.name ?? ''}
                onChange={(e) => setEditForm({ ...editForm, name: e.target.value })}
                required
                className="mt-1 block w-full rounded border border-slate-300 px-3 py-2 text-sm"
              />
            </label>
            <label className="block mb-3">
              <span className="text-sm font-medium text-slate-700">Local Name</span>
              <input
                value={editForm.name_local ?? ''}
                onChange={(e) =>
                  setEditForm({ ...editForm, name_local: e.target.value || null })
                }
                className="mt-1 block w-full rounded border border-slate-300 px-3 py-2 text-sm"
              />
            </label>
            <label className="block mb-3">
              <span className="text-sm font-medium text-slate-700">Speed Unit</span>
              <select
                value={editForm.speed_unit ?? 'kmh'}
                onChange={(e) => setEditForm({ ...editForm, speed_unit: e.target.value })}
                className="mt-1 block w-full rounded border border-slate-300 px-3 py-2 text-sm"
              >
                <option value="kmh">km/h</option>
                <option value="mph">mph</option>
              </select>
            </label>
            <label className="flex items-center gap-2 mb-4">
              <input
                type="checkbox"
                checked={editForm.enabled ?? false}
                onChange={(e) => setEditForm({ ...editForm, enabled: e.target.checked })}
              />
              <span className="text-sm text-slate-700">Enabled</span>
            </label>
            <div className="flex justify-end gap-3">
              <button
                type="button"
                onClick={() => setShowEdit(false)}
                className="px-4 py-2 text-sm rounded border border-slate-300 text-slate-700"
              >
                Cancel
              </button>
              <button
                type="submit"
                disabled={updateMutation.isPending}
                className="px-4 py-2 text-sm rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50"
              >
                Save
              </button>
            </div>
          </form>
        </div>
      )}

      {/* Delete Country Confirm */}
      <ConfirmDialog
        isOpen={showDeleteCountry}
        title="Delete Country"
        message={`Delete "${country.name}"? This will remove all associated sources, cameras, and packs.`}
        onConfirm={() => deleteCountryMutation.mutate()}
        onCancel={() => setShowDeleteCountry(false)}
      />

      {/* Delete Source Confirm */}
      <ConfirmDialog
        isOpen={deleteSourceId !== null}
        title="Delete Source"
        message="Delete this source? Associated cameras will be removed."
        onConfirm={() => deleteSourceId && deleteSourceMutation.mutate(deleteSourceId)}
        onCancel={() => setDeleteSourceId(null)}
      />
    </div>
  );
}
