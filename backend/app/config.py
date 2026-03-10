from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    database_url: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/buzzoff"
    database_url_sync: str = "postgresql://postgres:postgres@localhost:5432/buzzoff"

    pack_storage_path: str = "./packs"

    admin_username: str = "admin"
    admin_password: str = "changeme"
    jwt_secret: str = "dev-secret-change-in-production"

    nominatim_user_agent: str = "buzzoff-app"
    google_geocoding_api_key: str = ""

    model_config = {"env_file": ".env"}


settings = Settings()
