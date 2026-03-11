import { useEffect, useMemo } from 'react';
import { MapContainer, TileLayer, CircleMarker, Popup, useMap, useMapEvents } from 'react-leaflet';
import type { LatLngBoundsExpression } from 'leaflet';
import type { Camera } from '../../types';

const typeColors: Record<string, string> = {
  fixed_speed: '#ef4444',
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

function MapClickHandler({ onClick }: { onClick: (lat: number, lon: number) => void }) {
  useMapEvents({
    click(e) {
      onClick(e.latlng.lat, e.latlng.lng);
    },
  });
  return null;
}

interface CameraMapProps {
  cameras: Camera[];
  onMapClick?: (lat: number, lon: number) => void;
  selectedId?: string;
  onCameraClick?: (camera: Camera) => void;
  className?: string;
}

export default function CameraMap({ cameras, onMapClick, selectedId, onCameraClick, className }: CameraMapProps) {
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
      className={className ?? 'h-[400px] w-full rounded-lg'}
    >
      <TileLayer
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OSM</a>'
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
      />
      <FitBounds bounds={bounds} />
      {onMapClick && <MapClickHandler onClick={onMapClick} />}
      {cameras.map((cam) => {
        const isSelected = cam.id === selectedId;
        return (
          <CircleMarker
            key={cam.id}
            center={[cam.lat, cam.lon]}
            radius={isSelected ? 8 : 5}
            pathOptions={{
              color: isSelected ? '#1d4ed8' : (typeColors[cam.type] ?? '#6b7280'),
              fillColor: isSelected ? '#3b82f6' : (typeColors[cam.type] ?? '#6b7280'),
              fillOpacity: isSelected ? 1 : 0.7,
              weight: isSelected ? 3 : 1,
            }}
            eventHandlers={{
              click: () => onCameraClick?.(cam),
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
        );
      })}
    </MapContainer>
  );
}
