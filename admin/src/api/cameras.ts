import client from './client';
import type { CameraListResponse, CameraStats } from '../types';

export async function getCameras(
  countryCode: string,
  limit = 50,
  offset = 0,
): Promise<CameraListResponse> {
  const response = await client.get<CameraListResponse>(
    `/countries/${countryCode}/cameras`,
    { params: { limit, offset } },
  );
  return response.data;
}

export async function getCameraStats(countryCode: string): Promise<CameraStats> {
  const response = await client.get<CameraStats>(`/countries/${countryCode}/cameras/stats`);
  return response.data;
}
