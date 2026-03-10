import client from './client';
import type { Pack, PackDetail } from '../types';

export async function getPacks(countryCode: string): Promise<Pack[]> {
  const response = await client.get<Pack[]>(`/countries/${countryCode}/packs`);
  return response.data;
}

export async function getPackDetail(countryCode: string, version: number): Promise<PackDetail> {
  const response = await client.get<PackDetail>(`/countries/${countryCode}/packs/${version}`);
  return response.data;
}
