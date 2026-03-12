"""
Example: Submit speed cameras to an existing country.

Requires an API key with scope: submit_cameras.
"""

from buzzoff import BuzzOffClient, Camera

API_KEY = "bzk_..."  # Replace with your key

client = BuzzOffClient(api_key=API_KEY)

# List available countries
countries = client.list_countries()
for c in countries:
    print(f"  {c.code} — {c.name}")

# Submit cameras using Camera model
cameras = [
    Camera(lat=52.5200, lon=13.4050, type="fixed_speed", speed_limit=60, road_name="Alexanderplatz"),
    Camera(lat=52.5075, lon=13.3903, type="red_light", road_name="Friedrichstraße"),
    Camera(lat=48.1351, lon=11.5820, type="average_speed", speed_limit=120),
]

submission = client.submit_cameras("DE", cameras=cameras)
print(f"\nSubmitted {submission.camera_count} cameras")
print(f"Submission ID: {submission.id}")
print(f"Status: {submission.status}")

# Check all your submissions
print("\nAll submissions:")
for sub in client.list_submissions():
    print(f"  [{sub.status}] {sub.country_code} — {sub.camera_count} cameras — {sub.submitted_at}")

client.close()
