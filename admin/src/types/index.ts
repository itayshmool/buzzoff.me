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

// Scheduler
export interface SchedulerState {
  enabled: boolean;
  interval_hours: number;
  last_run_at: string | null;
  next_run_at: string | null;
  status: 'idle' | 'running' | 'disabled';
}

export interface SchedulerUpdate {
  enabled?: boolean;
  interval_hours?: number;
}

// Dashboard
export interface DashboardStats {
  countries: number;
  sources: number;
  cameras: number;
  packs: number;
  developer_keys: number;
  pending_submissions: number;
}

// Developer Keys
export interface DeveloperKey {
  id: string;
  name: string;
  email: string;
  key_prefix: string;
  scopes: string[];
  enabled: boolean;
  last_used_at: string | null;
  created_at: string;
}

export interface DeveloperKeyCreateRequest {
  name: string;
  email: string;
  scopes?: string[];
}

export interface DeveloperKeyCreateResponse extends DeveloperKey {
  raw_api_key: string;
}

// Developer Submissions
export interface DeveloperSubmission {
  id: string;
  country_code: string;
  status: string;
  camera_count: number;
  submitted_at: string;
  reviewed_at: string | null;
  review_note: string | null;
  developer_name: string;
  developer_email: string;
}

export interface DeveloperSubmissionDetail extends DeveloperSubmission {
  cameras_json: Record<string, unknown>[];
}
