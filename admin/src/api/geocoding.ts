import client from './client';
import type { GeocodingRecord, ResolveRequest } from '../types';

export async function getQueue(limit = 100): Promise<GeocodingRecord[]> {
  const response = await client.get<GeocodingRecord[]>('/geocoding/queue', { params: { limit } });
  return response.data;
}

export async function getFailed(limit = 100): Promise<GeocodingRecord[]> {
  const response = await client.get<GeocodingRecord[]>('/geocoding/failed', { params: { limit } });
  return response.data;
}

export async function resolve(
  id: string,
  data: ResolveRequest,
): Promise<{ id: string; lat: number; lon: number; status: string }> {
  const response = await client.put(`/geocoding/${id}/resolve`, data);
  return response.data;
}
