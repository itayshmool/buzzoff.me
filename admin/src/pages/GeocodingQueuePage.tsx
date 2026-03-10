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
      <h1 className="text-2xl font-bold text-slate-800 mb-6">Geocoding Queue</h1>

      {/* Tabs */}
      <div className="flex gap-1 mb-6">
        {(['pending', 'failed'] as Tab[]).map((t) => (
          <button
            key={t}
            onClick={() => setTab(t)}
            className={`px-4 py-2 text-sm rounded-t font-medium ${
              tab === t
                ? 'bg-white text-slate-800 border border-b-0 border-slate-200'
                : 'bg-slate-100 text-slate-500 hover:text-slate-700'
            }`}
          >
            {t === 'pending' ? 'Pending' : 'Failed'}
          </button>
        ))}
      </div>

      {isLoading && <p className="text-sm text-slate-500">Loading...</p>}

      {!isLoading && records.length === 0 && (
        <p className="text-sm text-slate-500">No {tab} records</p>
      )}

      <div className="space-y-4">
        {records.map((record) => {
          const coords = resolving[record.id];
          return (
            <div key={record.id} className="bg-white rounded-lg shadow p-4">
              <div className="flex items-start justify-between mb-3">
                <div>
                  <div className="font-medium text-slate-800">
                    {record.address ?? 'No address'}
                  </div>
                  <div className="flex items-center gap-2 mt-1">
                    <span className="text-xs bg-slate-100 text-slate-600 px-2 py-0.5 rounded">
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
                  className="w-32 rounded border border-slate-300 px-2 py-1 text-sm"
                />
                <input
                  type="number"
                  step="any"
                  placeholder="Lon"
                  value={coords?.lon ?? ''}
                  onChange={(e) =>
                    setCoords(record.id, coords?.lat ?? 0, parseFloat(e.target.value) || 0)
                  }
                  className="w-32 rounded border border-slate-300 px-2 py-1 text-sm"
                />
                <button
                  onClick={() => handleResolve(record.id)}
                  disabled={!coords || resolveMutation.isPending}
                  className="px-4 py-1.5 text-sm rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50"
                >
                  Resolve
                </button>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}
