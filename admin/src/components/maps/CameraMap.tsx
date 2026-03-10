import { useEffect, useMemo } from 'react';
import { MapContainer, TileLayer, CircleMarker, Popup, useMap } from 'react-leaflet';
import type { LatLngBoundsExpression } from 'leaflet';
import type { Camera } from '../../types';

const typeColors: Record<string, string> = {
  speed: '#ef4444',
  red_light: '#f59e0b',
  average_speed: '#8b5cf6',
  mobile: '#3b82f6',
};

function FitBounds({ bounds }: { bounds: LatLngBoundsExpression | null }) {
  const map = useMap();
  useEffect(() => {
    if (bounds) {
      map.fitBounds(bounds, { padding: [30, 30] });
    }
  }, [map, bounds]);
  return null;
}

interface CameraMapProps {
  cameras: Camera[];
}

export default function CameraMap({ cameras }: CameraMapProps) {
  const bounds = useMemo(() => {
    if (cameras.length === 0) return null;
    const lats = cameras.map((c) => c.lat);
    const lons = cameras.map((c) => c.lon);
    return [
      [Math.min(...lats), Math.min(...lons)],
      [Math.max(...lats), Math.max(...lons)],
    ] as LatLngBoundsExpression;
  }, [cameras]);

  return (
    <MapContainer
      center={[48, 15]}
      zoom={4}
      className="h-[400px] w-full rounded-lg"
    >
      <TileLayer
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OSM</a>'
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
      />
      <FitBounds bounds={bounds} />
      {cameras.map((cam) => (
        <CircleMarker
          key={cam.id}
          center={[cam.lat, cam.lon]}
          radius={5}
          pathOptions={{
            color: typeColors[cam.type] ?? '#6b7280',
            fillColor: typeColors[cam.type] ?? '#6b7280',
            fillOpacity: 0.7,
          }}
        >
          <Popup>
            <div className="text-xs">
              <div className="font-medium">{cam.type}</div>
              {cam.road_name && <div>{cam.road_name}</div>}
              {cam.speed_limit && <div>Limit: {cam.speed_limit}</div>}
              <div className="text-slate-400">
                {cam.lat.toFixed(5)}, {cam.lon.toFixed(5)}
              </div>
            </div>
          </Popup>
        </CircleMarker>
      ))}
    </MapContainer>
  );
}
