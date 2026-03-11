import { useState, useEffect } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getSources, createSource, updateSource, uploadSourceFile } from '../api/sources';
import type { SourceCreate, SourceUpdate } from '../types';

export default function SourceEditorPage() {
  const { code, id } = useParams<{ code: string; id: string }>();
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const isNew = !id;

  const { data: sources = [] } = useQuery({
    queryKey: ['sources', code],
    queryFn: () => getSources(code!),
    enabled: !!code && !isNew,
  });
  const existing = sources.find((s) => s.id === id);

  const [form, setForm] = useState({
    name: '',
    adapter: 'csv',
    config: '{}',
    schedule: '',
    confidence: 0.5,
    enabled: true,
  });
  const [configError, setConfigError] = useState('');
  const [file, setFile] = useState<File | null>(null);
  const [uploadStatus, setUploadStatus] = useState('');

  useEffect(() => {
    if (existing) {
      setForm({
        name: existing.name,
        adapter: existing.adapter,
        config: JSON.stringify(existing.config, null, 2),
        schedule: existing.schedule ?? '',
        confidence: existing.confidence,
        enabled: existing.enabled,
      });
    }
  }, [existing]);

  const createMutation = useMutation({
    mutationFn: (data: SourceCreate) => createSource(code!, data),
    onSuccess: async (source) => {
      if (file) {
        setUploadStatus('Uploading file...');
        await uploadSourceFile(source.id, file);
        setUploadStatus('');
      }
      queryClient.invalidateQueries({ queryKey: ['sources', code] });
      navigate(`/countries/${code}`);
    },
  });

  const updateMutation = useMutation({
    mutationFn: (data: SourceUpdate) => updateSource(id!, data),
    onSuccess: async () => {
      if (file) {
        setUploadStatus('Uploading file...');
        await uploadSourceFile(id!, file);
        setUploadStatus('');
      }
      queryClient.invalidateQueries({ queryKey: ['sources', code] });
      navigate(`/countries/${code}`);
    },
  });

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    let parsedConfig: Record<string, unknown>;
    try {
      parsedConfig = JSON.parse(form.config);
      setConfigError('');
    } catch {
      setConfigError('Invalid JSON');
      return;
    }

    const payload = {
      name: form.name,
      adapter: form.adapter,
      config: parsedConfig,
      schedule: form.schedule || null,
      confidence: form.confidence,
      enabled: form.enabled,
    };

    if (isNew) {
      createMutation.mutate(payload);
    } else {
      updateMutation.mutate(payload);
    }
  }

  const isPending = createMutation.isPending || updateMutation.isPending;

  if (!isNew && !existing) {
    return <p className="text-sm text-text-muted font-mono">Loading...</p>;
  }

  return (
    <div className="max-w-lg">
      <Link
        to={`/countries/${code}`}
        className="text-sm font-heading tracking-wider text-neon-dim hover:text-neon transition-colors"
      >
        &larr; BACK TO TRACK
      </Link>
      <h1 className="font-heading text-2xl font-bold tracking-wider text-text-primary mt-2 mb-6">
        {isNew ? 'NEW' : 'EDIT'} <span className="text-neon text-glow-neon">FEED</span>
      </h1>

      <form onSubmit={handleSubmit} className="space-y-4">
        <label className="block">
          <span className="text-xs font-heading tracking-wider text-text-muted uppercase">Name</span>
          <input
            value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })}
            required
            className="mt-1 block w-full bg-surface-raised border border-border px-3 py-2 text-sm text-text-primary focus:border-neon focus:outline-none"
          />
        </label>

        <label className="block">
          <span className="text-xs font-heading tracking-wider text-text-muted uppercase">Adapter</span>
          <select
            value={form.adapter}
            onChange={(e) => setForm({ ...form, adapter: e.target.value })}
            className="mt-1 block w-full bg-surface-raised border border-border px-3 py-2 text-sm text-text-primary focus:border-neon focus:outline-none"
          >
            <option value="csv">CSV</option>
            <option value="excel">Excel</option>
            <option value="osm_overpass">OSM Overpass</option>
          </select>
        </label>

        <label className="block">
          <span className="text-xs font-heading tracking-wider text-text-muted uppercase">Config (JSON)</span>
          <textarea
            value={form.config}
            onChange={(e) => {
              setForm({ ...form, config: e.target.value });
              setConfigError('');
            }}
            rows={6}
            className={`mt-1 block w-full bg-surface-raised border px-3 py-2 text-sm font-mono text-text-primary focus:border-neon focus:outline-none ${
              configError ? 'border-danger' : 'border-border'
            }`}
          />
          {configError && (
            <span className="text-xs text-danger mt-1">{configError}</span>
          )}
        </label>

        {(form.adapter === 'excel' || form.adapter === 'csv') && (
          <label className="block">
            <span className="text-xs font-heading tracking-wider text-text-muted uppercase">Data File</span>
            <input
              type="file"
              accept={form.adapter === 'excel' ? '.xlsx,.xls' : '.csv,.tsv'}
              onChange={(e) => setFile(e.target.files?.[0] ?? null)}
              className="mt-1 block w-full text-sm text-text-muted file:mr-4 file:py-2 file:px-4 file:border file:border-neon/30 file:text-sm file:font-heading file:tracking-wider file:bg-surface-raised file:text-neon hover:file:bg-surface-hover file:transition-colors"
            />
            {file && <span className="text-xs text-success mt-1 font-mono">{file.name}</span>}
            {uploadStatus && <span className="text-xs text-neon mt-1 font-mono">{uploadStatus}</span>}
            {!!existing?.config?.file_path && !file && (
              <span className="text-xs text-text-muted mt-1 font-mono">
                Current: {String(existing.config.file_path).split('/').pop() ?? ''}
              </span>
            )}
          </label>
        )}

        <label className="block">
          <span className="text-xs font-heading tracking-wider text-text-muted uppercase">Schedule (cron)</span>
          <input
            value={form.schedule}
            onChange={(e) => setForm({ ...form, schedule: e.target.value })}
            placeholder="e.g. 0 3 * * 1"
            className="mt-1 block w-full bg-surface-raised border border-border px-3 py-2 text-sm text-text-primary font-mono focus:border-neon focus:outline-none"
          />
        </label>

        <label className="block">
          <span className="text-xs font-heading tracking-wider text-text-muted uppercase">
            Confidence ({form.confidence})
          </span>
          <input
            type="range"
            min={0}
            max={1}
            step={0.05}
            value={form.confidence}
            onChange={(e) => setForm({ ...form, confidence: parseFloat(e.target.value) })}
            className="mt-1 block w-full accent-neon"
          />
        </label>

        <label className="flex items-center gap-2">
          <input
            type="checkbox"
            checked={form.enabled}
            onChange={(e) => setForm({ ...form, enabled: e.target.checked })}
            className="accent-neon"
          />
          <span className="text-sm text-text-secondary">Enabled</span>
        </label>

        <div className="flex gap-3 pt-2">
          <button
            type="button"
            onClick={() => navigate(`/countries/${code}`)}
            className="px-4 py-2 text-sm font-heading tracking-wider text-text-muted border border-border hover:border-border-bright transition-colors"
          >
            ABORT
          </button>
          <button
            type="submit"
            disabled={isPending}
            className="px-4 py-2 text-sm font-heading tracking-wider bg-neon text-surface hover:bg-neon-dim disabled:opacity-50 transition-colors"
          >
            {isNew ? 'CREATE' : 'SAVE'}
          </button>
        </div>
      </form>
    </div>
  );
}
