# src/scripts/run_migrations.py
import psycopg2
from psycopg2.extensions import connection as PGConnection
from pathlib import Path
from services.common.config import settings
from typing import Optional
import sys

MIGRATIONS_FOLDER = Path(__file__).parent.parent.parent / "db" / "migrations"


def get_connection(db: Optional[str] = None) -> PGConnection:
    return psycopg2.connect(
        host=settings.postgres_host,
        port=settings.postgres_port,
        dbname=db or settings.postgres_db,
        user=settings.postgres_user,
        password=settings.postgres_password,
        options="-c search_path=src,public",
    )


def ensure_migration_table(conn: PGConnection) -> None:
    with conn.cursor() as cur:
        cur.execute("CREATE SCHEMA IF NOT EXISTS src")
        cur.execute("""
            CREATE TABLE IF NOT EXISTS src.applied_migrations (
                id          SERIAL PRIMARY KEY,
                filename    TEXT UNIQUE NOT NULL,
                applied_at  TIMESTAMPTZ DEFAULT NOW()
            )
        """)
    conn.commit()


def get_applied_migrations(conn: PGConnection) -> set[str]:
    with conn.cursor() as cur:
        cur.execute("SELECT filename FROM src.applied_migrations")
        return {row[0] for row in cur.fetchall()}


def apply_migration(conn: PGConnection, migration_file: Path) -> None:
    sql = migration_file.read_text()
    with conn.cursor() as cur:
        cur.execute(sql)
        cur.execute(
            "INSERT INTO src.applied_migrations (filename) VALUES (%s)",
            (migration_file.name,),
        )
    conn.commit()
    print(f"  applied: {migration_file.name}")


def run_migrations() -> None:
    if not MIGRATIONS_FOLDER.exists():
        print(f"Migrations folder not found: {MIGRATIONS_FOLDER}")
        sys.exit(1)

    try:
        conn = get_connection()
    except psycopg2.OperationalError as e:
        print(f"Could not connect to database '{settings.postgres_db}': {e}")
        sys.exit(1)

    ensure_migration_table(conn)
    applied = get_applied_migrations(conn)

    migrations = sorted(MIGRATIONS_FOLDER.glob("*.sql"))
    pending = [m for m in migrations if m.name not in applied]

    if not pending:
        print("All migrations already applied.")
        return

    print(f"Applying {len(pending)} migration(s)...")
    for m in pending:
        apply_migration(conn, m)

    print("Done.")


if __name__ == "__main__":
    run_migrations()