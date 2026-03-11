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
    return <p className="text-sm text-text-muted font-mono">Loading...</p>;
  }

  return (
    <div>
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between mb-6 gap-3">
        <div>
          <Link to="/countries" className="text-sm font-heading tracking-wider text-neon-dim hover:text-neon transition-colors">
            &larr; TRACKS
          </Link>
          <h1 className="font-heading text-xl md:text-2xl font-bold tracking-wider text-text-primary mt-1">
            {country.name} <span className="text-neon text-glow-neon">({country.code})</span>
          </h1>
          <div className="flex items-center gap-3 mt-2">
            <StatusBadge status={country.enabled ? 'enabled' : 'disabled'} />
            <span className="text-sm font-mono text-text-muted">{country.speed_unit}</span>
            {country.name_local && (
              <span className="text-sm text-text-muted">{country.name_local}</span>
            )}
          </div>
        </div>
        <div className="flex gap-2">
          <button
            onClick={openEdit}
            className="px-4 py-2 text-sm font-heading tracking-wider text-text-secondary border border-border hover:border-neon/40 hover:text-neon transition-colors"
          >
            EDIT
          </button>
          <button
            onClick={() => setShowDeleteCountry(true)}
            className="px-4 py-2 text-sm font-heading tracking-wider bg-danger text-white hover:bg-danger-dim transition-colors"
          >
            DELETE
          </button>
        </div>
      </div>

      {/* Stats Row */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-8 stagger-children">
        <StatCard label="Data Feeds" value={sources.length} />
        <StatCard label="Item Boxes" value={cameraStats?.total.toLocaleString() ?? '...'} />
        <StatCard label="Packs" value={packs.length} />
      </div>

      {/* Camera Stats by Type */}
      {cameraStats && Object.keys(cameraStats.by_type).length > 0 && (
        <div className="bg-surface-card border border-border p-6 mb-8 neon-top">
          <h2 className="font-heading text-sm font-semibold tracking-wider text-text-muted uppercase mb-3">
            Item Box Intel by Type
          </h2>
          <div className="flex flex-wrap gap-4">
            {Object.entries(cameraStats.by_type).map(([type, count]) => (
              <div key={type} className="text-sm">
                <span className="font-mono text-neon">{type}:</span>{' '}
                <span className="text-text-secondary font-heading">{count.toLocaleString()}</span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Sources */}
      <div className="mb-8">
        <div className="flex items-center justify-between mb-4">
          <h2 className="font-heading text-sm font-semibold tracking-wider text-text-muted uppercase">
            Data Feeds
          </h2>
          <Link
            to={`/countries/${code}/sources/new`}
            className="px-4 py-2 text-sm font-heading tracking-wider bg-neon text-surface hover:bg-neon-dim transition-colors glow-neon"
          >
            + ADD FEED
          </Link>
        </div>
        {sources.length === 0 ? (
          <p className="text-sm text-text-muted font-mono">No sources configured</p>
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
        <div className="bg-surface-card border border-border p-6 mb-8 neon-top">
          <div className="flex items-center justify-between mb-3">
            <h2 className="font-heading text-sm font-semibold tracking-wider text-text-muted uppercase">
              Track Map
            </h2>
            <Link
              to={`/countries/${code}/cameras`}
              className="px-4 py-2 text-sm font-heading tracking-wider bg-hot text-white hover:bg-hot-dim transition-colors glow-hot"
            >
              MANAGE ITEMS
            </Link>
          </div>
          <CameraMap cameras={cameras.items} />
        </div>
      )}

      {/* Packs */}
      <div className="bg-surface-card border border-border mb-8">
        <div className="p-6 pb-0">
          <h2 className="font-heading text-sm font-semibold tracking-wider text-text-muted uppercase mb-4">
            Pack Releases
          </h2>
        </div>
        {packs.length === 0 ? (
          <p className="text-sm text-text-muted font-mono p-6 pt-0">No packs generated</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border">
                  <th className="text-left py-3 px-6 font-heading text-xs font-medium tracking-wider text-text-muted uppercase">Version</th>
                  <th className="text-left py-3 px-4 font-heading text-xs font-medium tracking-wider text-text-muted uppercase">Cameras</th>
                  <th className="text-left py-3 px-4 font-heading text-xs font-medium tracking-wider text-text-muted uppercase">Size</th>
                  <th className="text-left py-3 px-4 font-heading text-xs font-medium tracking-wider text-text-muted uppercase">Published</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border/50">
                {packs.map((pack) => (
                  <tr key={pack.id}>
                    <td className="py-3 px-6 text-neon font-heading font-bold">v{pack.version}</td>
                    <td className="py-3 px-4 text-text-primary font-mono">
                      {pack.camera_count.toLocaleString()}
                    </td>
                    <td className="py-3 px-4 text-text-secondary font-mono">
                      {(pack.file_size_bytes / 1024).toFixed(1)} KB
                    </td>
                    <td className="py-3 px-4 text-text-muted font-mono text-xs">
                      {pack.published_at
                        ? new Date(pack.published_at).toLocaleDateString()
                        : 'Unreleased'}
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
          <div className="absolute inset-0 bg-black/70 backdrop-blur-sm" onClick={() => setShowEdit(false)} />
          <form
            onSubmit={(e) => {
              e.preventDefault();
              updateMutation.mutate(editForm);
            }}
            className="relative bg-surface-card border border-neon/30 p-6 max-w-sm w-full mx-4 clip-angular animate-fade-up"
          >
            <div className="absolute top-0 left-0 right-0 h-0.5 bg-gradient-to-r from-neon to-transparent" />
            <h3 className="font-heading text-base font-bold tracking-wider text-neon text-glow-neon uppercase mb-4">
              Edit Track
            </h3>
            <label className="block mb-3">
              <span className="text-xs font-heading tracking-wider text-text-muted uppercase">Name</span>
              <input
                value={editForm.name ?? ''}
                onChange={(e) => setEditForm({ ...editForm, name: e.target.value })}
                required
                className="mt-1 block w-full bg-surface-raised border border-border px-3 py-2 text-sm text-text-primary focus:border-neon focus:outline-none"
              />
            </label>
            <label className="block mb-3">
              <span className="text-xs font-heading tracking-wider text-text-muted uppercase">Local Name</span>
              <input
                value={editForm.name_local ?? ''}
                onChange={(e) =>
                  setEditForm({ ...editForm, name_local: e.target.value || null })
                }
                className="mt-1 block w-full bg-surface-raised border border-border px-3 py-2 text-sm text-text-primary focus:border-neon focus:outline-none"
              />
            </label>
            <label className="block mb-3">
              <span className="text-xs font-heading tracking-wider text-text-muted uppercase">Speed Unit</span>
              <select
                value={editForm.speed_unit ?? 'kmh'}
                onChange={(e) => setEditForm({ ...editForm, speed_unit: e.target.value })}
                className="mt-1 block w-full bg-surface-raised border border-border px-3 py-2 text-sm text-text-primary focus:border-neon focus:outline-none"
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
                className="accent-neon"
              />
              <span className="text-sm text-text-secondary">Enabled</span>
            </label>
            <div className="flex justify-end gap-3">
              <button
                type="button"
                onClick={() => setShowEdit(false)}
                className="px-4 py-2 text-sm font-heading tracking-wider text-text-muted border border-border hover:border-border-bright transition-colors"
              >
                ABORT
              </button>
              <button
                type="submit"
                disabled={updateMutation.isPending}
                className="px-4 py-2 text-sm font-heading tracking-wider bg-neon text-surface hover:bg-neon-dim disabled:opacity-50 transition-colors"
              >
                SAVE
              </button>
            </div>
          </form>
        </div>
      )}

      <ConfirmDialog
        isOpen={showDeleteCountry}
        title="Delete Track"
        message={`Delete "${country.name}"? This will remove all associated feeds, cameras, and packs.`}
        onConfirm={() => deleteCountryMutation.mutate()}
        onCancel={() => setShowDeleteCountry(false)}
      />

      <ConfirmDialog
        isOpen={deleteSourceId !== null}
        title="Delete Feed"
        message="Delete this feed? Associated cameras will be removed."
        onConfirm={() => deleteSourceId && deleteSourceMutation.mutate(deleteSourceId)}
        onCancel={() => setDeleteSourceId(null)}
      />
    </div>
  );
}
