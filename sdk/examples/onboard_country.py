"""
Example: Onboard a new country end-to-end.

Creates the country, adds a data source, and submits sample cameras.
Requires an API key with scopes: manage_countries, submit_cameras.
"""

from buzzoff import BuzzOffClient

API_KEY = "bzk_..."  # Replace with your key

client = BuzzOffClient(api_key=API_KEY)

# 1. Create the country
country = client.create_country(
    code="AT",
    name="Austria",
    name_local="Österreich",
    speed_unit="kmh",
)
print(f"Created: {country.name} ({country.code})")

# 2. Add a data source
source = client.create_source(
    country_code="AT",
    name="OSM Speed Cameras (AT)",
    adapter="developer_api",
    confidence=0.6,
)
print(f"Source: {source.name} (id={source.id})")

# 3. Submit cameras
submission = client.submit_cameras("AT", cameras=[
    {"lat": 48.2082, "lon": 16.3738, "type": "fixed_speed", "speed_limit": 50, "road_name": "Ringstraße"},
    {"lat": 47.2692, "lon": 11.4041, "type": "fixed_speed", "speed_limit": 80},
    {"lat": 47.0707, "lon": 15.4395, "type": "red_light"},
])
print(f"Submitted {submission.camera_count} cameras (id={submission.id}, status={submission.status})")

# 4. Check submission status
detail = client.get_submission(str(submission.id))
print(f"Submission status: {detail.status}")

client.close()
