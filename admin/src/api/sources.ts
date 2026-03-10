import client from './client';
import type { Source, SourceCreate, SourceUpdate } from '../types';

export async function getSources(countryCode: string): Promise<Source[]> {
  const response = await client.get<Source[]>(`/countries/${countryCode}/sources`);
  return response.data;
}

export async function createSource(countryCode: string, data: SourceCreate): Promise<Source> {
  const response = await client.post<Source>(`/countries/${countryCode}/sources`, data);
  return response.data;
}

export async function updateSource(sourceId: string, data: SourceUpdate): Promise<Source> {
  const response = await client.put<Source>(`/sources/${sourceId}`, data);
  return response.data;
}

export async function deleteSource(sourceId: string): Promise<void> {
  await client.delete(`/sources/${sourceId}`);
}
