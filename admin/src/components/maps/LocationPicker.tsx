import { MapContainer, TileLayer, Marker, useMapEvents } from 'react-leaflet';

interface LocationPickerProps {
  lat: number | null;
  lon: number | null;
  onChange: (lat: number, lon: number) => void;
}

function ClickHandler({ onChange }: { onChange: (lat: number, lon: number) => void }) {
  useMapEvents({
    click(e) {
      onChange(e.latlng.lat, e.latlng.lng);
    },
  });
  return null;
}

export default function LocationPicker({ lat, lon, onChange }: LocationPickerProps) {
  return (
    <MapContainer
      center={lat && lon ? [lat, lon] : [48, 15]}
      zoom={lat && lon ? 14 : 4}
      className="h-[200px] w-full leaflet-dark border border-border"
    >
      <TileLayer
        attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OSM</a>'
        url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
      />
      <ClickHandler onChange={onChange} />
      {lat !== null && lon !== null && <Marker position={[lat, lon]} />}
    </MapContainer>
  );
}
