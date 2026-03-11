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
    return <p className="text-sm text-slate-500">Loading...</p>;
  }

  return (
    <div className="max-w-lg">
      <Link
        to={`/countries/${code}`}
        className="text-sm text-blue-600 hover:text-blue-800"
      >
        &larr; Back to country
      </Link>
      <h1 className="text-2xl font-bold text-slate-800 mt-2 mb-6">
        {isNew ? 'New Source' : 'Edit Source'}
      </h1>

      <form onSubmit={handleSubmit} className="space-y-4">
        <label className="block">
          <span className="text-sm font-medium text-slate-700">Name</span>
          <input
            value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })}
            required
            className="mt-1 block w-full rounded border border-slate-300 px-3 py-2 text-sm"
          />
        </label>

        <label className="block">
          <span className="text-sm font-medium text-slate-700">Adapter</span>
          <select
            value={form.adapter}
            onChange={(e) => setForm({ ...form, adapter: e.target.value })}
            className="mt-1 block w-full rounded border border-slate-300 px-3 py-2 text-sm"
          >
            <option value="csv">CSV</option>
            <option value="excel">Excel</option>
            <option value="osm_overpass">OSM Overpass</option>
          </select>
        </label>

        <label className="block">
          <span className="text-sm font-medium text-slate-700">Config (JSON)</span>
          <textarea
            value={form.config}
            onChange={(e) => {
              setForm({ ...form, config: e.target.value });
              setConfigError('');
            }}
            rows={6}
            className={`mt-1 block w-full rounded border px-3 py-2 text-sm font-mono ${
              configError ? 'border-red-400' : 'border-slate-300'
            }`}
          />
          {configError && (
            <span className="text-xs text-red-600 mt-1">{configError}</span>
          )}
        </label>

        {(form.adapter === 'excel' || form.adapter === 'csv') && (
          <label className="block">
            <span className="text-sm font-medium text-slate-700">Data File</span>
            <input
              type="file"
              accept={form.adapter === 'excel' ? '.xlsx,.xls' : '.csv,.tsv'}
              onChange={(e) => setFile(e.target.files?.[0] ?? null)}
              className="mt-1 block w-full text-sm text-slate-500 file:mr-4 file:py-2 file:px-4 file:rounded file:border-0 file:text-sm file:font-medium file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100"
            />
            {file && <span className="text-xs text-green-600 mt-1">{file.name}</span>}
            {uploadStatus && <span className="text-xs text-blue-600 mt-1">{uploadStatus}</span>}
            {!!existing?.config?.file_path && !file && (
              <span className="text-xs text-slate-500 mt-1">
                Current: {String(existing.config.file_path).split('/').pop() ?? ''}
              </span>
            )}
          </label>
        )}

        <label className="block">
          <span className="text-sm font-medium text-slate-700">Schedule (cron)</span>
          <input
            value={form.schedule}
            onChange={(e) => setForm({ ...form, schedule: e.target.value })}
            placeholder="e.g. 0 3 * * 1"
            className="mt-1 block w-full rounded border border-slate-300 px-3 py-2 text-sm"
          />
        </label>

        <label className="block">
          <span className="text-sm font-medium text-slate-700">
            Confidence ({form.confidence})
          </span>
          <input
            type="range"
            min={0}
            max={1}
            step={0.05}
            value={form.confidence}
            onChange={(e) => setForm({ ...form, confidence: parseFloat(e.target.value) })}
            className="mt-1 block w-full"
          />
        </label>

        <label className="flex items-center gap-2">
          <input
            type="checkbox"
            checked={form.enabled}
            onChange={(e) => setForm({ ...form, enabled: e.target.checked })}
          />
          <span className="text-sm text-slate-700">Enabled</span>
        </label>

        <div className="flex gap-3 pt-2">
          <button
            type="button"
            onClick={() => navigate(`/countries/${code}`)}
            className="px-4 py-2 text-sm rounded border border-slate-300 text-slate-700"
          >
            Cancel
          </button>
          <button
            type="submit"
            disabled={isPending}
            className="px-4 py-2 text-sm rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50"
          >
            {isNew ? 'Create' : 'Save'}
          </button>
        </div>
      </form>
    </div>
  );
}
