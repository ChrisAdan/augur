# services/db/connection.py
import psycopg2
from psycopg2.extensions import connection as PGConnection
from services.common.config import settings


def get_connection() -> PGConnection:
    """
    Returns a new PostgreSQL connection using settings from config.py.
    """
    conn: PGConnection = psycopg2.connect(
        host=settings.postgres_host,
        port=settings.postgres_port,
        dbname=settings.postgres_db,
        user=settings.postgres_user,
        password=settings.postgres_password
    )
    return conn