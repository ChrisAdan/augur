# services/db/connection.py
from contextlib import contextmanager
from typing import Any, Generator

from psycopg2 import pool
from psycopg2.extensions import connection as PGConnection

from services.common.config import settings


class _ConnectionPool:
    """
    Thin typed wrapper around psycopg2.pool.ThreadedConnectionPool.
    Exists solely to give Pylance a concrete return type for getconn/putconn,
    whose stubs are typed as Any in psycopg2-stubs.
    """

    def __init__(self, minconn: int, maxconn: int, **kwargs: Any) -> None:
        # Typed as Any to avoid Pylance reportUnknownMemberType on psycopg2-stubs,
        # which leaves ThreadedConnectionPool.getconn() -> Unknown.
        self._pool: Any = pool.ThreadedConnectionPool(minconn, maxconn, **kwargs)

    def getconn(self) -> PGConnection:
        return self._pool.getconn()  # type: ignore[no-any-return]

    def putconn(self, conn: PGConnection) -> None:
        self._pool.putconn(conn)


_pool: _ConnectionPool | None = None


def _get_pool() -> _ConnectionPool:
    global _pool
    if _pool is None:
        _pool = _ConnectionPool(
            minconn=1,
            maxconn=10,
            host=settings.postgres_host,
            port=settings.postgres_port,
            dbname=settings.postgres_db,
            user=settings.postgres_user,
            password=settings.postgres_password,
            options="-c search_path=src,public",
        )
    return _pool


@contextmanager
def get_connection() -> Generator[PGConnection, None, None]:
    """
    Context manager that checks out a connection from the pool and returns it
    when the block exits, even on error.

    Usage:
        with get_connection() as conn:
            with conn.cursor() as cur:
                cur.execute(...)
            conn.commit()
    """
    p = _get_pool()
    conn: PGConnection = p.getconn()
    try:
        yield conn
    except Exception:
        conn.rollback()
        raise
    finally:
        p.putconn(conn)