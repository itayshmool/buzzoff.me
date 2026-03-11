import client from './client';
import type { Camera, CameraCreate, CameraListResponse, CameraStats } from '../types';

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

export async function createCamera(countryCode: string, data: CameraCreate): Promise<Camera> {
  const response = await client.post<Camera>(`/countries/${countryCode}/cameras`, data);
  return response.data;
}

export async function deleteCamera(cameraId: string): Promise<void> {
  await client.delete(`/cameras/${cameraId}`);
}
