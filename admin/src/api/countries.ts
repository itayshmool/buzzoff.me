import client from './client';
import type { Country, CountryCreate, CountryUpdate } from '../types';

export async function getCountries(): Promise<Country[]> {
  const response = await client.get<Country[]>('/countries');
  return response.data;
}

export async function createCountry(data: CountryCreate): Promise<Country> {
  const response = await client.post<Country>('/countries', data);
  return response.data;
}

export async function updateCountry(code: string, data: CountryUpdate): Promise<Country> {
  const response = await client.put<Country>(`/countries/${code}`, data);
  return response.data;
}

export async function deleteCountry(code: string): Promise<void> {
  await client.delete(`/countries/${code}`);
}
