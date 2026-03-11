import { useState, useRef, useCallback } from 'react';
import { useParams, Link } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getCameras, getCameraStats, createCamera, deleteCamera } from '../api/cameras';
import CameraMap from '../components/maps/CameraMap';
import ConfirmDialog from '../components/common/ConfirmDialog';
import type { Camera, CameraCreate } from '../types';

const CAMERA_TYPES = ['fixed_speed', 'red_light', 'average_speed', 'mobile'];

const typeLabels: Record<string, string> = {
  fixed_speed: 'Speed',
  red_light: 'Red Light',
  average_speed: 'Avg Speed',
  mobile: 'Mobile',
};

const typeColors: Record<string, string> = {
  fixed_speed: 'bg-danger/20 text-danger border-danger/30',
  speed: 'bg-danger/20 text-danger border-danger/30',
  red_light: 'bg-hot/20 text-hot border-hot/30',
  average_speed: 'bg-neon/20 text-neon border-neon/30',
  mobile: 'bg-neon/10 text-neon-dim border-neon/20',
};

export default function CamerasPage() {
  const { code } = useParams<{ code: string }>();
  const queryClient = useQueryClient();
  const listRef = useRef<HTMLDivElement>(null);

  const [selectedId, setSelectedId] = useState<string | undefined>();
  const [filter, setFilter] = useState('');
  const [showAddForm, setShowAddForm] = useState(false);
  const [addForm, setAddForm] = useState<CameraCreate>({
    lat: 0,
    lon: 0,
    type: 'fixed_speed',
    speed_limit: null,
    road_name: null,
  });
  const [deleteTarget, setDeleteTarget] = useState<Camera | null>(null);

  const { data: cameraData } = useQuery({
    queryKey: ['cameras', code],
    queryFn: () => getCameras(code!, 5000, 0),
    enabled: !!code,
  });

  const { data: stats } = useQuery({
    queryKey: ['camera-stats', code],
    queryFn: () => getCameraStats(code!),
    enabled: !!code,
  });

  const cameras = cameraData?.items ?? [];

  const filteredCameras = filter
    ? cameras.filter(
        (c) =>
          c.type.toLowerCase().includes(filter.toLowerCase()) ||
          c.road_name?.toLowerCase().includes(filter.toLowerCase()) ||
          `${c.lat}, ${c.lon}`.includes(filter),
      )
    : cameras;

  const createMutation = useMutation({
    mutationFn: (data: CameraCreate) => createCamera(code!, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['cameras', code] });
      queryClient.invalidateQueries({ queryKey: ['camera-stats', code] });
      setShowAddForm(false);
      setAddForm({ lat: 0, lon: 0, type: 'fixed_speed', speed_limit: null, road_name: null });
    },
  });

  const deleteMutation = useMutation({
    mutationFn: (id: string) => deleteCamera(id),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['cameras', code] });
      queryClient.invalidateQueries({ queryKey: ['camera-stats', code] });
      setDeleteTarget(null);
      setSelectedId(undefined);
    },
  });

  const handleMapClick = useCallback(
    (lat: number, lon: number) => {
      setAddForm((prev) => ({ ...prev, lat: parseFloat(lat.toFixed(6)), lon: parseFloat(lon.toFixed(6)) }));
      setShowAddForm(true);
    },
    [],
  );

  const handleCameraClick = useCallback((cam: Camera) => {
    setSelectedId(cam.id);
    const el = document.getElementById(`cam-${cam.id}`);
    el?.scrollIntoView({ behavior: 'smooth', block: 'nearest' });
  }, []);

  const handleListClick = (cam: Camera) => {
    setSelectedId(cam.id);
  };

  const handleAddSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    createMutation.mutate(addForm);
  };

  return (
    <div className="h-full flex flex-col">
      {/* Header */}
      <div className="flex items-center justify-between mb-4">
        <div>
          <Link
            to={`/countries/${code}`}
            className="text-sm font-heading tracking-wider text-neon-dim hover:text-neon transition-colors"
          >
            &larr; BACK TO ZONE
          </Link>
          <h1 className="font-heading text-2xl font-bold tracking-wider text-text-primary mt-1">
            SURVEILLANCE <span className="text-hot text-glow-hot">GRID</span>
            <span className="text-neon text-glow-neon ml-2">({code})</span>
          </h1>
        </div>
        {stats && (
          <div className="flex items-center gap-3 text-sm">
            <span className="font-heading font-bold tracking-wider text-text-primary">{stats.total} units</span>
            {Object.entries(stats.by_type).map(([type, count]) => (
              <span
                key={type}
                className={`px-2 py-0.5 text-[10px] font-heading tracking-wider border ${typeColors[type] ?? 'bg-surface-hover text-text-muted border-border'}`}
              >
                {(typeLabels[type] ?? type).toUpperCase()}: {count}
              </span>
            ))}
          </div>
        )}
      </div>

      {/* Split view */}
      <div className="flex-1 flex gap-4 min-h-0">
        {/* Map panel */}
        <div className="w-3/5 flex flex-col">
          <div className="text-xs text-text-muted font-mono mb-1">Click on the map to deploy a new unit</div>
          <div className="flex-1">
            <CameraMap
              cameras={cameras}
              onMapClick={handleMapClick}
              selectedId={selectedId}
              onCameraClick={handleCameraClick}
              className="h-full w-full border border-border"
            />
          </div>
        </div>

        {/* Right panel */}
        <div className="w-2/5 flex flex-col min-h-0">
          {/* Add form */}
          {showAddForm && (
            <div className="bg-surface-card border border-neon/30 p-4 mb-3 clip-angular">
              <div className="absolute top-0 left-0 right-0 h-0.5 bg-gradient-to-r from-neon to-transparent" />
              <div className="flex items-center justify-between mb-3">
                <h3 className="text-sm font-heading font-bold tracking-wider text-neon text-glow-neon uppercase">Deploy Unit</h3>
                <button
                  onClick={() => setShowAddForm(false)}
                  className="text-text-muted hover:text-danger text-lg leading-none transition-colors"
                >
                  &times;
                </button>
              </div>
              <form onSubmit={handleAddSubmit} className="space-y-2">
                <div className="grid grid-cols-2 gap-2">
                  <label className="block">
                    <span className="text-[10px] font-heading tracking-wider text-text-muted uppercase">Latitude</span>
                    <input
                      type="number"
                      step="any"
                      required
                      value={addForm.lat}
                      onChange={(e) => setAddForm({ ...addForm, lat: parseFloat(e.target.value) })}
                      className="mt-0.5 block w-full bg-surface-raised border border-border px-2 py-1 text-sm text-text-primary font-mono focus:border-neon focus:outline-none"
                    />
                  </label>
                  <label className="block">
                    <span className="text-[10px] font-heading tracking-wider text-text-muted uppercase">Longitude</span>
                    <input
                      type="number"
                      step="any"
                      required
                      value={addForm.lon}
                      onChange={(e) => setAddForm({ ...addForm, lon: parseFloat(e.target.value) })}
                      className="mt-0.5 block w-full bg-surface-raised border border-border px-2 py-1 text-sm text-text-primary font-mono focus:border-neon focus:outline-none"
                    />
                  </label>
                </div>
                <div className="grid grid-cols-2 gap-2">
                  <label className="block">
                    <span className="text-[10px] font-heading tracking-wider text-text-muted uppercase">Type</span>
                    <select
                      value={addForm.type}
                      onChange={(e) => setAddForm({ ...addForm, type: e.target.value })}
                      className="mt-0.5 block w-full bg-surface-raised border border-border px-2 py-1 text-sm text-text-primary focus:border-neon focus:outline-none"
                    >
                      {CAMERA_TYPES.map((t) => (
                        <option key={t} value={t}>
                          {typeLabels[t] ?? t}
                        </option>
                      ))}
                    </select>
                  </label>
                  <label className="block">
                    <span className="text-[10px] font-heading tracking-wider text-text-muted uppercase">Speed Limit</span>
                    <input
                      type="number"
                      value={addForm.speed_limit ?? ''}
                      onChange={(e) =>
                        setAddForm({ ...addForm, speed_limit: e.target.value ? parseInt(e.target.value) : null })
                      }
                      className="mt-0.5 block w-full bg-surface-raised border border-border px-2 py-1 text-sm text-text-primary font-mono focus:border-neon focus:outline-none"
                    />
                  </label>
                </div>
                <label className="block">
                  <span className="text-[10px] font-heading tracking-wider text-text-muted uppercase">Road Name</span>
                  <input
                    value={addForm.road_name ?? ''}
                    onChange={(e) => setAddForm({ ...addForm, road_name: e.target.value || null })}
                    className="mt-0.5 block w-full bg-surface-raised border border-border px-2 py-1 text-sm text-text-primary focus:border-neon focus:outline-none"
                  />
                </label>
                <div className="flex gap-2 pt-1">
                  <button
                    type="button"
                    onClick={() => setShowAddForm(false)}
                    className="px-3 py-1 text-xs font-heading tracking-wider text-text-muted border border-border hover:border-border-bright transition-colors"
                  >
                    ABORT
                  </button>
                  <button
                    type="submit"
                    disabled={createMutation.isPending}
                    className="px-3 py-1 text-xs font-heading tracking-wider bg-neon text-surface hover:bg-neon-dim disabled:opacity-50 transition-colors"
                  >
                    {createMutation.isPending ? 'DEPLOYING...' : 'DEPLOY'}
                  </button>
                </div>
              </form>
            </div>
          )}

          {/* Controls */}
          <div className="flex gap-2 mb-2">
            <input
              placeholder="Filter by type, road, coords..."
              value={filter}
              onChange={(e) => setFilter(e.target.value)}
              className="flex-1 bg-surface-raised border border-border px-3 py-1.5 text-sm text-text-primary font-mono focus:border-neon focus:outline-none"
            />
            {!showAddForm && (
              <button
                onClick={() => setShowAddForm(true)}
                className="px-3 py-1.5 text-sm font-heading tracking-wider bg-neon text-surface hover:bg-neon-dim whitespace-nowrap transition-colors"
              >
                + DEPLOY
              </button>
            )}
          </div>

          {/* Camera list */}
          <div ref={listRef} className="flex-1 overflow-y-auto border border-border bg-surface-card">
            {filteredCameras.length === 0 ? (
              <p className="p-4 text-sm text-text-muted font-mono text-center">
                {cameras.length === 0 ? 'No units deployed' : 'No units match filter'}
              </p>
            ) : (
              <div className="divide-y divide-border/50">
                {filteredCameras.map((cam) => (
                  <div
                    key={cam.id}
                    id={`cam-${cam.id}`}
                    onClick={() => handleListClick(cam)}
                    className={`flex items-center justify-between px-3 py-2 cursor-pointer hover:bg-surface-hover transition-colors ${
                      cam.id === selectedId ? 'bg-neon/5 border-l-2 border-neon' : ''
                    }`}
                  >
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-2">
                        <span
                          className={`inline-block px-1.5 py-0.5 text-[10px] font-heading tracking-wider border ${
                            typeColors[cam.type] ?? 'bg-surface-hover text-text-muted border-border'
                          }`}
                        >
                          {(typeLabels[cam.type] ?? cam.type).toUpperCase()}
                        </span>
                        {cam.speed_limit && (
                          <span className="text-xs text-text-muted font-mono">{cam.speed_limit} km/h</span>
                        )}
                      </div>
                      <div className="text-xs text-text-muted mt-0.5 truncate font-mono">
                        {cam.road_name ?? `${cam.lat.toFixed(5)}, ${cam.lon.toFixed(5)}`}
                      </div>
                    </div>
                    <button
                      onClick={(e) => {
                        e.stopPropagation();
                        setDeleteTarget(cam);
                      }}
                      className="ml-2 p-1 text-text-muted hover:text-danger flex-shrink-0 transition-colors"
                      title="Delete camera"
                    >
                      <svg
                        xmlns="http://www.w3.org/2000/svg"
                        className="h-4 w-4"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                        strokeWidth={2}
                      >
                        <path
                          strokeLinecap="round"
                          strokeLinejoin="round"
                          d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                        />
                      </svg>
                    </button>
                  </div>
                ))}
              </div>
            )}
          </div>
          <div className="text-xs text-text-muted font-mono mt-1 text-right">
            Showing {filteredCameras.length} of {cameras.length}
          </div>
        </div>
      </div>

      <ConfirmDialog
        isOpen={deleteTarget !== null}
        title="Delete Unit"
        message={
          deleteTarget
            ? `Remove ${deleteTarget.type} unit at ${deleteTarget.lat.toFixed(5)}, ${deleteTarget.lon.toFixed(5)}?`
            : ''
        }
        onConfirm={() => deleteTarget && deleteMutation.mutate(deleteTarget.id)}
        onCancel={() => setDeleteTarget(null)}
      />
    </div>
  );
}
