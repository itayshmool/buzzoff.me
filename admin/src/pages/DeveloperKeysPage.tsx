import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getDeveloperKeys, createDeveloperKey, revokeDeveloperKey } from '../api/developers';
import DataTable, { type Column } from '../components/common/DataTable';
import StatusBadge from '../components/common/StatusBadge';
import type { DeveloperKey } from '../types';

export default function DeveloperKeysPage() {
  const queryClient = useQueryClient();
  const [showCreate, setShowCreate] = useState(false);
  const [createdKey, setCreatedKey] = useState<string | null>(null);
  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [scopes, setScopes] = useState<string[]>(['read_cameras', 'submit_cameras']);

  const { data: keys = [], isLoading } = useQuery({
    queryKey: ['developer-keys'],
    queryFn: getDeveloperKeys,
  });

  const createMutation = useMutation({
    mutationFn: createDeveloperKey,
    onSuccess: (data) => {
      setCreatedKey(data.raw_api_key);
      setName('');
      setEmail('');
      setScopes(['read_cameras', 'submit_cameras']);
      queryClient.invalidateQueries({ queryKey: ['developer-keys'] });
    },
  });

  const revokeMutation = useMutation({
    mutationFn: revokeDeveloperKey,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['developer-keys'] });
    },
  });

  function handleCreate(e: React.FormEvent) {
    e.preventDefault();
    createMutation.mutate({ name, email, scopes });
  }

  const columns: Column<DeveloperKey>[] = [
    { key: 'name', header: 'Name' },
    { key: 'email', header: 'Email' },
    {
      key: 'key_prefix',
      header: 'Key',
      render: (k) => <code className="text-xs font-mono text-neon">{k.key_prefix}...</code>,
    },
    {
      key: 'scopes',
      header: 'Scopes',
      render: (k) => (
        <span className="text-xs text-text-muted">{k.scopes.join(', ')}</span>
      ),
    },
    {
      key: 'enabled',
      header: 'Status',
      render: (k) => <StatusBadge status={k.enabled ? 'enabled' : 'disabled'} />,
    },
    {
      key: 'last_used_at',
      header: 'Last Used',
      render: (k) => k.last_used_at ? new Date(k.last_used_at).toLocaleString() : 'Never',
    },
    {
      key: 'created_at',
      header: 'Created',
      render: (k) => new Date(k.created_at).toLocaleDateString(),
    },
    {
      key: 'actions',
      header: '',
      render: (k) =>
        k.enabled ? (
          <button
            onClick={() => revokeMutation.mutate(k.id)}
            className="text-xs font-heading tracking-wider text-danger hover:text-danger/80 transition-colors"
          >
            REVOKE
          </button>
        ) : null,
    },
  ];

  if (isLoading) return <p className="text-sm text-text-muted font-mono">Loading...</p>;

  return (
    <div>
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 mb-6">
        <h1 className="font-heading text-xl md:text-2xl font-bold tracking-wider text-text-primary">
          DRIVER <span className="text-neon text-glow-neon">KEYS</span>
        </h1>
        <button
          onClick={() => { setShowCreate(!showCreate); setCreatedKey(null); }}
          className="px-4 py-2 text-xs font-heading tracking-wider bg-neon text-surface hover:bg-neon-dim transition-colors glow-neon"
        >
          {showCreate ? 'CANCEL' : 'NEW KEY'}
        </button>
      </div>

      {/* Create form */}
      {showCreate && (
        <div className="bg-surface-card border border-border p-6 mb-6 neon-top">
          {createdKey ? (
            <div>
              <h3 className="font-heading text-sm font-semibold tracking-wider text-success mb-3">
                KEY CREATED
              </h3>
              <p className="text-xs text-text-muted mb-2">
                Copy this key now. It will not be shown again.
              </p>
              <code className="block bg-surface-raised border border-neon/30 px-4 py-3 text-sm font-mono text-neon break-all">
                {createdKey}
              </code>
              <button
                onClick={() => { navigator.clipboard.writeText(createdKey); }}
                className="mt-3 px-4 py-2 text-xs font-heading tracking-wider border border-border text-text-secondary hover:border-neon/40 hover:text-neon transition-colors"
              >
                COPY
              </button>
            </div>
          ) : (
            <form onSubmit={handleCreate} className="flex flex-col gap-3">
              <div className="flex flex-col sm:flex-row gap-3">
                <input
                  type="text"
                  placeholder="Developer name"
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  required
                  className="flex-1 bg-surface-raised border border-border px-3 py-2 text-sm text-text-primary placeholder-text-muted focus:border-neon focus:outline-none"
                />
                <input
                  type="email"
                  placeholder="Email address"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  required
                  className="flex-1 bg-surface-raised border border-border px-3 py-2 text-sm text-text-primary placeholder-text-muted focus:border-neon focus:outline-none"
                />
              </div>
              <div className="flex flex-wrap items-center gap-4">
                <span className="text-xs font-heading tracking-wider text-text-muted">SCOPES:</span>
                {['read_cameras', 'submit_cameras', 'manage_countries'].map((scope) => (
                  <label key={scope} className="flex items-center gap-2 cursor-pointer group">
                    <input
                      type="checkbox"
                      checked={scopes.includes(scope)}
                      onChange={(e) => {
                        if (e.target.checked) {
                          setScopes([...scopes, scope]);
                        } else {
                          setScopes(scopes.filter((s) => s !== scope));
                        }
                      }}
                      className="accent-neon w-3.5 h-3.5"
                    />
                    <span className={`text-xs font-mono ${scopes.includes(scope) ? 'text-neon' : 'text-text-muted'} group-hover:text-neon/80 transition-colors`}>
                      {scope}
                    </span>
                  </label>
                ))}
              </div>
              <div>
                <button
                  type="submit"
                  disabled={createMutation.isPending || scopes.length === 0}
                  className="px-6 py-2 text-xs font-heading tracking-wider bg-hot text-white hover:bg-hot-dim transition-colors glow-hot disabled:opacity-50"
                >
                  {createMutation.isPending ? 'CREATING...' : 'CREATE'}
                </button>
              </div>
            </form>
          )}
        </div>
      )}

      <div className="bg-surface-card border border-border overflow-x-auto">
        <DataTable data={keys} columns={columns} emptyMessage="No developer keys" />
      </div>
    </div>
  );
}
