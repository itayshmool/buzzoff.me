import client from './client';
import type {
  DeveloperKey,
  DeveloperKeyCreateRequest,
  DeveloperKeyCreateResponse,
  DeveloperSubmission,
  DeveloperSubmissionDetail,
} from '../types';

// --- Developer Keys ---

export async function getDeveloperKeys(): Promise<DeveloperKey[]> {
  const response = await client.get<DeveloperKey[]>('/developer-keys');
  return response.data;
}

export async function createDeveloperKey(
  body: DeveloperKeyCreateRequest,
): Promise<DeveloperKeyCreateResponse> {
  const response = await client.post<DeveloperKeyCreateResponse>('/developer-keys', body);
  return response.data;
}

export async function revokeDeveloperKey(keyId: string): Promise<void> {
  await client.delete(`/developer-keys/${keyId}`);
}

// --- Submissions ---

export async function getSubmissions(status?: string): Promise<DeveloperSubmission[]> {
  const params: Record<string, string> = {};
  if (status) params.status = status;
  const response = await client.get<DeveloperSubmission[]>('/submissions', { params });
  return response.data;
}

export async function getSubmission(id: string): Promise<DeveloperSubmissionDetail> {
  const response = await client.get<DeveloperSubmissionDetail>(`/submissions/${id}`);
  return response.data;
}

export async function approveSubmission(id: string): Promise<{ cameras_inserted: number }> {
  const response = await client.post<{ cameras_inserted: number }>(
    `/submissions/${id}/approve`,
  );
  return response.data;
}

export async function rejectSubmission(id: string, note: string): Promise<void> {
  await client.post(`/submissions/${id}/reject`, { note });
}
