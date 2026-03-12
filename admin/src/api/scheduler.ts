import client from './client';
import type { SchedulerState, SchedulerUpdate } from '../types';

export async function getScheduler(): Promise<SchedulerState> {
  const response = await client.get<SchedulerState>('/scheduler');
  return response.data;
}

export async function updateScheduler(data: SchedulerUpdate): Promise<SchedulerState> {
  const response = await client.put<SchedulerState>('/scheduler', data);
  return response.data;
}

export async function runPipelineNow(): Promise<{ status: string; results: Record<string, string> }> {
  const response = await client.post('/scheduler/run');
  return response.data;
}
