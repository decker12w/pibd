from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    postgres_user: str = "admin"
    postgres_password: str = "root"
    postgres_db: str = "banco_pibd"
    postgres_host: str = "localhost"
    postgres_port: int = 5432

    db_pool_min_size: int = 1
    db_pool_max_size: int = 10


settings = Settings()
