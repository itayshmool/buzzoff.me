// Auth
export interface LoginRequest {
  username: string;
  password: string;
}

export interface TokenResponse {
  access_token: string;
  token_type: string;
}

// Countries
export interface Country {
  code: string;
  name: string;
  name_local: string | null;
  speed_unit: string;
  enabled: boolean;
}

export interface CountryCreate {
  code: string;
  name: string;
  name_local?: string | null;
  speed_unit?: string;
  enabled?: boolean;
}

export interface CountryUpdate {
  name?: string;
  name_local?: string | null;
  speed_unit?: string;
  enabled?: boolean;
}

// Sources
export interface Source {
  id: string;
  country_code: string;
  name: string;
  adapter: string;
  config: Record<string, unknown>;
  schedule: string | null;
  confidence: number;
  enabled: boolean;
}

export interface SourceCreate {
  name: string;
  adapter: string;
  config: Record<string, unknown>;
  schedule?: string | null;
  confidence?: number;
  enabled?: boolean;
}

export interface SourceUpdate {
  name?: string;
  adapter?: string;
  config?: Record<string, unknown>;
  schedule?: string | null;
  confidence?: number;
  enabled?: boolean;
}

// Cameras
export interface Camera {
  id: string;
  lat: number;
  lon: number;
  type: string;
  speed_limit: number | null;
  heading: number | null;
  road_name: string | null;
  confidence: number;
}

export interface CameraListResponse {
  total: number;
  items: Camera[];
}

export interface CameraCreate {
  lat: number;
  lon: number;
  type: string;
  speed_limit?: number | null;
  heading?: number | null;
  road_name?: string | null;
}

export interface CameraStats {
  total: number;
  by_type: Record<string, number>;
}

// Geocoding
export interface GeocodingRecord {
  id: string;
  address: string | null;
  country_code: string;
  type: string;
}

export interface ResolveRequest {
  lat: number;
  lon: number;
}

// Packs
export interface Pack {
  id: string;
  country_code: string;
  version: number;
  camera_count: number;
  file_size_bytes: number;
  checksum_sha256: string;
  published_at: string | null;
}

export interface PackDetail extends Pack {
  file_path: string;
}

// Jobs
export interface JobRun {
  id: string;
  job_type: string;
  status: string;
  started_at: string | null;
  finished_at: string | null;
  result_summary: string | null;
  items_processed: number | null;
}

// Dashboard
export interface DashboardStats {
  countries: number;
  sources: number;
  cameras: number;
  packs: number;
}
