import client from './client';
import type { JobRun } from '../types';

export async function getJobs(jobType?: string, limit = 50): Promise<JobRun[]> {
  const params: Record<string, string | number> = { limit };
  if (jobType) params.job_type = jobType;
  const response = await client.get<JobRun[]>('/jobs', { params });
  return response.data;
}

export async function runJob(jobType: string): Promise<{ status: string; job_type: string }> {
  const response = await client.post(`/jobs/run/${jobType}`);
  return response.data;
}
