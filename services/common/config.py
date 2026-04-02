from pydantic import BaseModel
from alpaca_trade_api.common import URL  # type: ignore[import-untyped]
from dotenv import load_dotenv
import os

load_dotenv()

class Settings(BaseModel):
    # Alpaca
    alpaca_api_key: str
    alpaca_secret_key: str
    alpaca_base_url: URL

    # Postgres
    postgres_host: str
    postgres_port: int
    postgres_db: str
    postgres_user: str
    postgres_password: str

    model_config = {
        "arbitrary_types_allowed": True
    }

    @classmethod
    def from_env(cls) -> "Settings":
        return cls(
            alpaca_api_key=os.getenv("APCA_API_KEY_ID", ""),
            alpaca_secret_key=os.getenv("APCA_API_SECRET_KEY", ""),
            alpaca_base_url=URL(str(os.getenv("APCA_API_BASE_URL", ""))),
            postgres_host=os.getenv("POSTGRES_HOST", "localhost"),
            postgres_port=int(os.getenv("POSTGRES_PORT", "5432")),
            postgres_db=os.getenv("POSTGRES_DB", "augur"),
            postgres_user=os.getenv("POSTGRES_USER", "postgres"),
            postgres_password=os.getenv("POSTGRES_PASSWORD", "postgres"),  # remove before commit
        )
    
settings = Settings.from_env()