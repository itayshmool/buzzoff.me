import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AuthProvider } from './contexts/AuthContext';
import ProtectedRoute from './components/ProtectedRoute';
import AppLayout from './components/layout/AppLayout';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import CountriesPage from './pages/CountriesPage';
import CountryDetailPage from './pages/CountryDetailPage';
import SourceEditorPage from './pages/SourceEditorPage';
import CamerasPage from './pages/CamerasPage';
import GeocodingQueuePage from './pages/GeocodingQueuePage';
import JobsPage from './pages/JobsPage';

const queryClient = new QueryClient({
  defaultOptions: { queries: { staleTime: 30_000, retry: 1 } },
});

export default function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <BrowserRouter>
          <Routes>
            <Route path="/login" element={<LoginPage />} />
            <Route element={<ProtectedRoute />}>
              <Route element={<AppLayout />}>
                <Route index element={<DashboardPage />} />
                <Route path="countries" element={<CountriesPage />} />
                <Route path="countries/:code" element={<CountryDetailPage />} />
                <Route path="countries/:code/cameras" element={<CamerasPage />} />
                <Route path="countries/:code/sources/new" element={<SourceEditorPage />} />
                <Route path="countries/:code/sources/:id" element={<SourceEditorPage />} />
                <Route path="geocoding" element={<GeocodingQueuePage />} />
                <Route path="jobs" element={<JobsPage />} />
              </Route>
            </Route>
          </Routes>
        </BrowserRouter>
      </AuthProvider>
    </QueryClientProvider>
  );
}
