import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getQueue, getFailed, resolve } from '../api/geocoding';
import LocationPicker from '../components/maps/LocationPicker';
import StatusBadge from '../components/common/StatusBadge';

type Tab = 'pending' | 'failed';

export default function GeocodingQueuePage() {
  const queryClient = useQueryClient();
  const [tab, setTab] = useState<Tab>('pending');
  const [resolving, setResolving] = useState<Record<string, { lat: number; lon: number }>>({});

  const { data: pending = [], isLoading: loadingPending } = useQuery({
    queryKey: ['geocoding', 'queue'],
    queryFn: () => getQueue(),
    enabled: tab === 'pending',
  });

  const { data: failed = [], isLoading: loadingFailed } = useQuery({
    queryKey: ['geocoding', 'failed'],
    queryFn: () => getFailed(),
    enabled: tab === 'failed',
  });

  const resolveMutation = useMutation({
    mutationFn: ({ id, lat, lon }: { id: string; lat: number; lon: number }) =>
      resolve(id, { lat, lon }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['geocoding'] });
    },
  });

  const records = tab === 'pending' ? pending : failed;
  const isLoading = tab === 'pending' ? loadingPending : loadingFailed;

  function setCoords(id: string, lat: number, lon: number) {
    setResolving((prev) => ({ ...prev, [id]: { lat, lon } }));
  }

  function handleResolve(id: string) {
    const coords = resolving[id];
    if (!coords) return;
    resolveMutation.mutate({ id, lat: coords.lat, lon: coords.lon });
    setResolving((prev) => {
      const next = { ...prev };
      delete next[id];
      return next;
    });
  }

  return (
    <div>
      <h1 className="font-heading text-2xl font-bold tracking-wider text-text-primary mb-6">
        GEO <span className="text-hot text-glow-hot">LOCATE</span>
      </h1>

      {/* Tabs */}
      <div className="flex gap-1 mb-6">
        {(['pending', 'failed'] as Tab[]).map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={`px-4 py-2 text-sm font-heading tracking-wider uppercase transition-colors ${
              tab === t
                ? 'bg-surface-card text-neon border border-border border-b-0'
                : 'bg-surface-raised text-text-muted hover:text-text-secondary'
            }`}
          >
            {t}
          </button>
        ))}
      </div>

      {isLoading && <p className="text-sm text-text-muted font-mono">Loading...</p>}

      {!isLoading && records.length === 0 && (
        <p className="text-sm text-text-muted font-mono">No {tab} records</p>
      )}

      <div className="space-y-4">
        {records.map((record) => {
          const coords = resolving[record.id];
          return (
            <div key={record.id} className="bg-surface-card border border-border p-4">
              <div className="flex items-start justify-between mb-3">
                <div>
                  <div className="font-semibold text-text-primary">
                    {record.address ?? 'No address'}
                  </div>
                  <div className="flex items-center gap-2 mt-1">
                    <span className="text-xs font-mono bg-surface-hover text-neon-dim px-2 py-0.5 border border-border">
                      {record.country_code}
                    </span>
                    <StatusBadge status={record.type} />
                  </div>
                </div>
              </div>

              <LocationPicker
                lat={coords?.lat ?? null}
                lon={coords?.lon ?? null}
                onChange={(lat, lon) => setCoords(record.id, lat, lon)}
              />

              <div className="mt-3 flex items-center gap-3">
                <input
                  type="number"
                  step="any"
                  placeholder="Lat"
                  value={coords?.lat ?? ''}
                  onChange={(e) =>
                    setCoords(record.id, parseFloat(e.target.value) || 0, coords?.lon ?? 0)
                  }
                  className="w-32 bg-surface-raised border border-border px-2 py-1 text-sm text-text-primary font-mono focus:border-neon focus:outline-none"
                />
                <input
                  type="number"
                  step="any"
                  placeholder="Lon"
                  value={coords?.lon ?? ''}
                  onChange={(e) =>
                    setCoords(record.id, coords?.lat ?? 0, parseFloat(e.target.value) || 0)
                  }
                  className="w-32 bg-surface-raised border border-border px-2 py-1 text-sm text-text-primary font-mono focus:border-neon focus:outline-none"
                />
                <button
                  onClick={() => handleResolve(record.id)}
                  disabled={!coords || resolveMutation.isPending}
                  className="px-4 py-1.5 text-sm font-heading tracking-wider bg-neon text-surface hover:bg-neon-dim disabled:opacity-50 transition-colors"
                >
                  RESOLVE
                </button>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
