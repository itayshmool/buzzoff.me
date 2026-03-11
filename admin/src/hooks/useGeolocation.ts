import { useState, useEffect } from 'react';

interface GeoPosition {
  lat: number;
  lon: number;
}

const DEFAULT_CENTER: GeoPosition = { lat: 48, lon: 15 };
let cachedPosition: GeoPosition | null = null;

export default function useGeolocation(): GeoPosition {
  const [position, setPosition] = useState<GeoPosition>(cachedPosition ?? DEFAULT_CENTER);

  useEffect(() => {
    if (cachedPosition) return;
    if (!navigator.geolocation) return;

    navigator.geolocation.getCurrentPosition(
      (pos) => {
        const geo = { lat: pos.coords.latitude, lon: pos.coords.longitude };
        cachedPosition = geo;
        setPosition(geo);
      },
      () => {
        // Permission denied or error — keep default
      },
      { enableHighAccuracy: false, timeout: 10000, maximumAge: 600000 },
    );
  }, []);

  return position;
}
