import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getScheduler, updateScheduler, runPipelineNow, resetPipeline } from '../api/scheduler';
import { getJobs, runJob } from '../api/jobs';
import StatusBadge from '../components/common/StatusBadge';
import type { SchedulerState, JobRun } from '../types';

const INTERVALS = [1, 3, 6, 12, 24] as const;

function formatTime(iso: string | null): string {
  if (!iso) return '—';
  return new Date(iso).toLocaleString();
}

function timeAgo(iso: string | null): string {
  if (!iso) return '';
  const diff = Date.now() - new Date(iso).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  const days = Math.floor(hrs / 24);
  return `${days}d ago`;
}

function timeUntil(iso: string | null): string {
  if (!iso) return '';
  const diff = new Date(iso).getTime() - Date.now();
  if (diff < 0) return 'overdue';
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'any moment';
  if (mins < 60) return `in ${mins}m`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `in ${hrs}h ${mins % 60}m`;
  const days = Math.floor(hrs / 24);
  return `in ${days}d`;
}

function parsePipelineResults(summary: string | null): Record<string, string> | null {
  if (!summary) return null;
  try {
    return JSON.parse(summary);
  } catch {
    return null;
  }
}

const PIPELINE_STEPS = ['fetch_sources', 'merge_cameras', 'generate_packs'] as const;
const STEP_LABELS: Record<string, string> = {
  starting: 'Starting',
  fetch_sources: 'Fetching Sources',
  merge_cameras: 'Merging Cameras',
  generate_packs: 'Generating Packs',
};

export default function SchedulerPage() {
  const queryClient = useQueryClient();

  const { data: scheduler, isLoading } = useQuery<SchedulerState>({
    queryKey: ['scheduler'],
    queryFn: getScheduler,
    refetchInterval: (query) => {
      const data = query.state.data;
      return data?.status === 'running' ? 3_000 : 10_000;
    },
  });

  const isPipelineActive = scheduler?.status === 'running';

  const { data: pipelineRuns = [] } = useQuery<JobRun[]>({
    queryKey: ['jobs', 'auto_pipeline'],
    queryFn: () => getJobs('auto_pipeline', 10),
    refetchInterval: isPipelineActive ? 5_000 : 15_000,
  });

  const toggleMutation = useMutation({
    mutationFn: (enabled: boolean) => updateScheduler({ enabled }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['scheduler'] }),
  });

  const intervalMutation = useMutation({
    mutationFn: (interval_hours: number) => updateScheduler({ interval_hours }),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ['scheduler'] }),
  });

  const runNowMutation = useMutation({
    mutationFn: runPipelineNow,
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ['scheduler'] });
      queryClient.invalidateQueries({ queryKey: ['jobs'] });
    },
  });

  const resetMutation = useMutation({
    mutationFn: resetPipeline,
    onSettled: () => {
      queryClient.invalidateQueries({ queryKey: ['scheduler'] });
    },
  });

  const [runningStep, setRunningStep] = useState<string | null>(null);
  const [stepResult, setStepResult] = useState<{ status: string; step: string } | null>(null);
  const stepMutation = useMutation({
    mutationFn: runJob,
    onMutate: (jobType) => {
      setRunningStep(jobType);
      setStepResult(null);
    },
    onSuccess: (_data, jobType) => {
      setStepResult({ status: 'completed', step: jobType });
      setTimeout(() => setStepResult(null), 5000);
    },
    onError: (_err, jobType) => {
      setStepResult({ status: 'failed', step: jobType });
      setTimeout(() => setStepResult(null), 8000);
    },
    onSettled: () => {
      setRunningStep(null);
      queryClient.invalidateQueries({ queryKey: ['scheduler'] });
      queryClient.invalidateQueries({ queryKey: ['jobs'] });
    },
  });

  if (isLoading || !scheduler) {
    return <p className="text-sm text-text-muted font-mono">Loading...</p>;
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <h1 className="font-heading text-xl md:text-2xl font-bold tracking-wider text-text-primary">
        AUTO <span className="text-warning text-glow-warning">⚡</span>{' '}
        <span className="text-neon text-glow-neon">PILOT</span>
      </h1>

      {/* Main Control Card */}
      <div className="bg-surface-card border border-border p-6 space-y-6">
        {/* Toggle Row */}
        <div className="flex items-center justify-between">
          <div>
            <h2 className="font-heading text-sm tracking-wider text-text-primary">
              PIPELINE SCHEDULER
            </h2>
            <p className="text-xs text-text-muted mt-1 font-mono">
              fetch → merge → generate packs
            </p>
          </div>
          <button
            onClick={() => toggleMutation.mutate(!scheduler.enabled)}
            disabled={toggleMutation.isPending}
            className={`
              relative w-14 h-7 rounded-full transition-colors duration-200 focus:outline-none
              ${scheduler.enabled
                ? 'bg-success/30 border border-success/50'
                : 'bg-border/30 border border-border'
              }
            `}
          >
            <span
              className={`
                absolute top-0.5 left-0.5 w-6 h-6 rounded-full transition-all duration-200
                ${scheduler.enabled
                  ? 'translate-x-7 bg-success shadow-[0_0_8px_rgba(67,176,71,0.5)]'
                  : 'translate-x-0 bg-text-muted'
                }
              `}
            />
          </button>
        </div>

        {/* Interval Selector */}
        <div>
          <p className="text-xs text-text-muted font-heading tracking-wider mb-2">INTERVAL</p>
          <div className="flex gap-2">
            {INTERVALS.map((h) => (
              <button
                key={h}
                onClick={() => intervalMutation.mutate(h)}
                disabled={intervalMutation.isPending || !scheduler.enabled}
                className={`
                  px-4 py-2 text-xs font-heading tracking-wider border transition-all duration-150
                  ${scheduler.interval_hours === h
                    ? 'bg-neon/15 text-neon border-neon/50 shadow-[0_0_8px_rgba(4,156,216,0.2)]'
                    : scheduler.enabled
                      ? 'bg-surface-raised text-text-secondary border-border hover:border-neon/30 hover:text-text-primary'
                      : 'bg-surface-raised text-text-muted border-border opacity-50 cursor-not-allowed'
                  }
                `}
              >
                {h}H
              </button>
            ))}
          </div>
        </div>

        {/* Status Info */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          <div className="bg-surface-raised border border-border p-3">
            <p className="text-[10px] text-text-muted font-heading tracking-wider mb-1">STATUS</p>
            <div className="flex items-center gap-2">
              <span
                className={`w-2 h-2 rounded-full ${
                  isPipelineActive
                    ? 'bg-warning animate-pulse shadow-[0_0_6px_rgba(251,208,0,0.6)]'
                    : scheduler.enabled
                      ? 'bg-success shadow-[0_0_6px_rgba(67,176,71,0.4)]'
                      : 'bg-danger'
                }`}
              />
              <span className="text-sm font-mono text-text-primary">
                {isPipelineActive ? 'Running' : scheduler.enabled ? 'Idle' : 'Disabled'}
              </span>
            </div>
          </div>
          <div className="bg-surface-raised border border-border p-3">
            <p className="text-[10px] text-text-muted font-heading tracking-wider mb-1">LAST RUN</p>
            <p className="text-sm font-mono text-text-primary">{formatTime(scheduler.last_run_at)}</p>
            {scheduler.last_run_at && (
              <p className="text-[10px] text-text-muted font-mono">{timeAgo(scheduler.last_run_at)}</p>
            )}
          </div>
          <div className="bg-surface-raised border border-border p-3">
            <p className="text-[10px] text-text-muted font-heading tracking-wider mb-1">NEXT RUN</p>
            <p className="text-sm font-mono text-text-primary">
              {scheduler.enabled ? formatTime(scheduler.next_run_at) : '—'}
            </p>
            {scheduler.enabled && scheduler.next_run_at && (
              <p className="text-[10px] text-text-muted font-mono">{timeUntil(scheduler.next_run_at)}</p>
            )}
          </div>
        </div>

        {/* Pipeline Stepper (visible when running) */}
        {isPipelineActive && (
          <div className="bg-surface-raised border border-warning/30 p-4 space-y-3">
            <p className="text-[10px] text-text-muted font-heading tracking-wider">PIPELINE PROGRESS</p>
            <div className="flex items-center gap-2">
              {PIPELINE_STEPS.map((step, i) => {
                const currentStep = scheduler.current_step;
                const currentIdx = currentStep ? PIPELINE_STEPS.indexOf(currentStep as typeof PIPELINE_STEPS[number]) : -1;
                const isDone = currentIdx > i;
                const isActive = currentStep === step;

                return (
                  <div key={step} className="flex items-center gap-2 flex-1">
                    {/* Step indicator */}
                    <div className="flex flex-col items-center gap-1 flex-1">
                      <div
                        className={`
                          w-8 h-8 rounded-full flex items-center justify-center text-xs font-heading border-2 transition-all duration-300
                          ${isDone
                            ? 'bg-success/20 border-success text-success shadow-[0_0_8px_rgba(67,176,71,0.4)]'
                            : isActive
                              ? 'bg-warning/20 border-warning text-warning animate-pulse shadow-[0_0_8px_rgba(251,208,0,0.4)]'
                              : 'bg-surface-card border-border text-text-muted'
                          }
                        `}
                      >
                        {isDone ? '✓' : i + 1}
                      </div>
                      <span className={`text-[10px] font-heading tracking-wider text-center ${isActive ? 'text-warning' : isDone ? 'text-success' : 'text-text-muted'}`}>
                        {STEP_LABELS[step]}
                      </span>
                    </div>
                    {/* Connector line */}
                    {i < PIPELINE_STEPS.length - 1 && (
                      <div className={`h-0.5 flex-1 -mt-4 transition-colors duration-300 ${isDone ? 'bg-success/50' : 'bg-border'}`} />
                    )}
                  </div>
                );
              })}
            </div>
            {scheduler.current_step && (
              <div className="flex items-center gap-2 pt-1">
                <div className="w-3 h-3 border-2 border-warning border-t-transparent rounded-full animate-spin" />
                <span className="text-xs font-mono text-warning">
                  {STEP_LABELS[scheduler.current_step] || scheduler.current_step}...
                </span>
              </div>
            )}
          </div>
        )}

        {/* Run Now Button */}
        <button
          onClick={() => runNowMutation.mutate()}
          disabled={isPipelineActive || runNowMutation.isPending}
          className={`
            w-full py-3 font-heading text-sm tracking-widest border transition-all duration-200
            ${isPipelineActive
              ? 'bg-warning/10 text-warning border-warning/30 cursor-not-allowed'
              : 'bg-success/10 text-success border-success/40 hover:bg-success/20 hover:border-success/60 hover:shadow-[0_0_12px_rgba(67,176,71,0.2)]'
            }
          `}
        >
          {isPipelineActive ? 'PIPELINE RUNNING...' : '🏁 RUN NOW'}
        </button>

        {/* Manual Step Triggers */}
        <div>
          <p className="text-xs text-text-muted font-heading tracking-wider mb-2">RUN INDIVIDUAL STEP</p>
          <div className="flex gap-2">
            {PIPELINE_STEPS.map((step) => (
              <button
                key={step}
                onClick={() => stepMutation.mutate(step)}
                disabled={!!runningStep || isPipelineActive}
                className={`
                  flex-1 py-2 text-xs font-heading tracking-wider border transition-all duration-150
                  ${runningStep === step
                    ? 'bg-warning/10 text-warning border-warning/30 animate-pulse'
                    : 'bg-surface-raised text-text-secondary border-border hover:border-neon/30 hover:text-text-primary'
                  }
                  disabled:opacity-50 disabled:cursor-not-allowed
                `}
              >
                {runningStep === step ? 'RUNNING...' : STEP_LABELS[step].toUpperCase()}
              </button>
            ))}
          </div>
          {stepResult && (
            <div className={`
              mt-2 px-4 py-2 text-xs font-heading tracking-wider border transition-all
              ${stepResult.status === 'completed'
                ? 'bg-success/10 text-success border-success/30'
                : 'bg-danger/10 text-danger border-danger/30'
              }
            `}>
              {stepResult.status === 'completed' ? '✓' : '✗'}{' '}
              {STEP_LABELS[stepResult.step]} — {stepResult.status.toUpperCase()}
            </div>
          )}
        </div>

        {/* Reset stuck pipeline */}
        {isPipelineActive && (
          <button
            onClick={() => resetMutation.mutate()}
            disabled={resetMutation.isPending}
            className="w-full py-2 text-xs font-heading tracking-widest border border-danger/30 text-danger hover:bg-danger/10 transition-all duration-200"
          >
            FORCE RESET (UNSTICK PIPELINE)
          </button>
        )}
      </div>

      {/* Recent Runs */}
      <div className="bg-surface-card border border-border">
        <div className="px-6 py-4 border-b border-border">
          <h2 className="font-heading text-sm tracking-wider text-text-primary">
            RECENT <span className="text-neon">RUNS</span>
          </h2>
        </div>
        {pipelineRuns.length === 0 ? (
          <p className="px-6 py-8 text-sm text-text-muted font-mono text-center">
            No pipeline runs yet
          </p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-border text-left">
                  <th className="px-4 py-3 font-heading text-[10px] tracking-wider text-text-muted">TIME</th>
                  <th className="px-4 py-3 font-heading text-[10px] tracking-wider text-text-muted">STATUS</th>
                  <th className="px-4 py-3 font-heading text-[10px] tracking-wider text-text-muted">FETCH</th>
                  <th className="px-4 py-3 font-heading text-[10px] tracking-wider text-text-muted">MERGE</th>
                  <th className="px-4 py-3 font-heading text-[10px] tracking-wider text-text-muted">PACKS</th>
                  <th className="px-4 py-3 font-heading text-[10px] tracking-wider text-text-muted">DURATION</th>
                </tr>
              </thead>
              <tbody>
                {pipelineRuns.map((run) => {
                  const results = parsePipelineResults(run.result_summary);
                  const duration = run.started_at && run.finished_at
                    ? Math.round((new Date(run.finished_at).getTime() - new Date(run.started_at).getTime()) / 1000)
                    : null;

                  return (
                    <tr key={run.id} className="border-b border-border/50 hover:bg-surface-hover transition-colors">
                      <td className="px-4 py-3 font-mono text-xs text-text-secondary">
                        {run.started_at ? new Date(run.started_at).toLocaleString() : '—'}
                      </td>
                      <td className="px-4 py-3">
                        <StatusBadge status={run.status} />
                      </td>
                      <td className="px-4 py-3 text-center">
                        <StepIcon status={results?.fetch_sources} />
                      </td>
                      <td className="px-4 py-3 text-center">
                        <StepIcon status={results?.merge_cameras} />
                      </td>
                      <td className="px-4 py-3 text-center">
                        <StepIcon status={results?.generate_packs} />
                      </td>
                      <td className="px-4 py-3 font-mono text-xs text-text-muted">
                        {duration !== null
                          ? duration < 60 ? `${duration}s` : `${Math.floor(duration / 60)}m ${duration % 60}s`
                          : '—'
                        }
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}

function StepIcon({ status }: { status?: string }) {
  if (!status) return <span className="text-text-muted">—</span>;
  if (status === 'completed') {
    return <span className="text-success text-base" title="Completed">✓</span>;
  }
  return <span className="text-danger text-base" title={status}>✗</span>;
}
