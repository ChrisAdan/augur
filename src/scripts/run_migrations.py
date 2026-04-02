# scripts/run_migrations.py
import psycopg2
from psycopg2.extensions import connection as PGConnection
from pathlib import Path
from services.common.config import settings
from typing import Optional
import sys

MIGRATIONS_FOLDER = Path(__file__).parent.parent / "migrations"


def get_connection(db: Optional[str]) -> PGConnection:
    """Connect to Postgres (optionally specify database)"""
    return psycopg2.connect(
        host=settings.postgres_host,
        port=settings.postgres_port,
        dbname=db or settings.postgres_db,
        user=settings.postgres_user,
        password=settings.postgres_password
    )


def ensure_migration_table(conn: PGConnection) -> None:
    """Create table to track applied migrations"""
    with conn.cursor() as cur:
        cur.execute("""
            CREATE TABLE IF NOT EXISTS applied_migrations (
                id SERIAL PRIMARY KEY,
                filename TEXT UNIQUE NOT NULL,
                applied_at TIMESTAMP DEFAULT NOW()
            )
        """)
    conn.commit()


def get_applied_migrations(conn: PGConnection) -> set[str]:
    with conn.cursor() as cur:
        cur.execute("SELECT filename FROM applied_migrations")
        return set(row[0] for row in cur.fetchall())


def apply_migration(conn: PGConnection, migration_file: Path) -> None:
    sql = migration_file.read_text()
    with conn.cursor() as cur:
        cur.execute(sql)
        cur.execute(
            "INSERT INTO applied_migrations (filename) VALUES (%s)",
            (migration_file.name,)
        )
    conn.commit()
    print(f"Applied migration: {migration_file.name}")


def run_migrations() -> None:
    # Step 1: ensure database exists
    try:
        conn = get_connection(db = settings.postgres_db)
    except psycopg2.OperationalError:
        print(f"Database '{settings.postgres_db}' does not exist.")
        sys.exit(1)

    # Step 2: ensure migration tracking table exists
    ensure_migration_table(conn)

    # Step 3: get list of already applied migrations
    applied = get_applied_migrations(conn)

    # Step 4: apply new migrations in order
    migrations = sorted(MIGRATIONS_FOLDER.glob("*.sql"))
    for m in migrations:
        if m.name not in applied:
            apply_migration(conn, m)

    print("All migrations applied.")


if __name__ == "__main__":
    run_migrations()