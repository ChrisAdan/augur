# src/scripts/health_check.py
"""
Connectivity health check — runs outside Docker, no trades required.

Verifies in order:
  1. Environment variables are present
  2. Config loads without error
  3. Postgres is reachable and migrations table exists
  4. Alpaca API is reachable and credentials are valid
  5. Alpaca can fetch orders and positions (may be empty — that's fine)

Usage:
    python -m src.scripts.health_check
"""

import sys
from typing import Any


# ── ANSI helpers ─────────────────────────────────────────────────────────────

def ok(label: str, detail: str = "") -> None:
    suffix = f"  {detail}" if detail else ""
    print(f"  \033[32m✓\033[0m  {label}{suffix}")


def fail(label: str, detail: str = "") -> None:
    suffix = f"\n       {detail}" if detail else ""
    print(f"  \033[31m✗\033[0m  {label}{suffix}")


def section(title: str) -> None:
    print(f"\n\033[1m{title}\033[0m")


# ── 1. Environment ────────────────────────────────────────────────────────────

def check_env() -> bool:
    import os
    from dotenv import load_dotenv
    load_dotenv()

    section("1. Environment variables")

    required = [
        "APCA_API_KEY_ID",
        "APCA_API_SECRET_KEY",
        "APCA_API_BASE_URL",
        "POSTGRES_HOST",
        "POSTGRES_DB",
        "POSTGRES_USER",
        "POSTGRES_PASSWORD",
    ]

    all_present = True
    for var in required:
        val = os.getenv(var)
        if val:
            # Mask secrets — show first 4 chars only
            masked = val[:4] + "****" if len(val) > 4 else "****"
            ok(var, masked)
        else:
            fail(var, "not set")
            all_present = False

    return all_present


# ── 2. Config ─────────────────────────────────────────────────────────────────

def check_config() -> bool:
    section("2. Config")
    try:
        from services.common.config import settings
        ok("Settings loaded")
        ok("Alpaca base URL", str(settings.alpaca_base_url))
        ok("Postgres", f"{settings.postgres_host}:{settings.postgres_port}/{settings.postgres_db}")
        return True
    except Exception as e:
        fail("Settings failed to load", str(e))
        return False


# ── 3. Postgres ───────────────────────────────────────────────────────────────

def check_postgres() -> bool:
    section("3. Postgres")
    try:
        from services.db.connection import get_connection
        with get_connection() as conn:
            with conn.cursor() as cur:
                # Server version
                cur.execute("SELECT version()")
                row: Any = cur.fetchone()
                version: str = row[0].split(",")[0] if row else "unknown"
                ok("Connected", version)

                # Check our tables exist
                cur.execute("""
                    SELECT table_name
                    FROM information_schema.tables
                    WHERE table_schema = 'public'
                    ORDER BY table_name
                """)
                tables = [r[0] for r in cur.fetchall()]

        expected = [
            "alpaca_fills",
            "alpaca_orders",
            "alpaca_positions",
            "trade_closes",
            "trades",
        ]
        for t in expected:
            if t in tables:
                ok(f"Table: {t}")
            else:
                fail(f"Table: {t}", "missing — have you run migrations?")

        return True

    except Exception as e:
        fail("Could not connect to Postgres", str(e))
        return False


# ── 4. Alpaca credentials ─────────────────────────────────────────────────────

def check_alpaca_auth() -> bool:
    section("4. Alpaca API — credentials")
    try:
        from services.collector.alpaca.client import AlpacaClient
        client = AlpacaClient()

        # get_account() is the lightest call — no market data permissions needed
        account: Any = client.api.get_account()  # type: ignore[attr-defined]
        ok("Authenticated")
        ok("Account status", str(account.status))
        ok("Account ID",     str(account.id)[:8] + "****")
        ok("Buying power",   f"${float(account.buying_power):,.2f}")
        ok("Portfolio value",f"${float(account.portfolio_value):,.2f}")
        ok("Pattern day trader", str(account.pattern_day_trader))
        return True

    except Exception as e:
        fail("Alpaca auth failed", str(e))
        return False


# ── 5. Alpaca data ────────────────────────────────────────────────────────────

def check_alpaca_data() -> bool:
    section("5. Alpaca API — orders and positions")
    try:
        from services.collector.alpaca.client import AlpacaClient
        client = AlpacaClient()

        orders = client.fetch_orders()
        ok(f"Orders fetched", f"{len(orders)} total")
        if orders:
            latest = orders[0]
            ok("Latest order", f"{latest.symbol} {latest.side} {latest.status} @ {latest.submitted_at.date()}")

        positions = client.fetch_positions()
        ok(f"Positions fetched", f"{len(positions)} open")
        for p in positions:
            ok(f"  {p.symbol}", f"qty={p.qty}  market_value=${p.market_value:,.2f}  unrealized_pl=${p.unrealized_pl:,.2f}")

        return True

    except Exception as e:
        fail("Alpaca data fetch failed", str(e))
        return False


# ── Main ──────────────────────────────────────────────────────────────────────

def main() -> None:
    print("\n\033[1mAugur — health check\033[0m")

    checks = [
        check_env,
        check_config,
        check_postgres,
        check_alpaca_auth,
        check_alpaca_data,
    ]

    passed = 0
    for check in checks:
        result = check()
        if result:
            passed += 1
        else:
            # Config and env failures make later checks meaningless
            if check in (check_env, check_config):
                print(f"\n\033[31mAborting — fix the above before continuing.\033[0m\n")
                sys.exit(1)

    total = len(checks)
    print(f"\n{'─' * 40}")
    if passed == total:
        print(f"\033[32m  All {total} checks passed.\033[0m\n")
    else:
        print(f"\033[33m  {passed}/{total} checks passed.\033[0m\n")
        sys.exit(1)


if __name__ == "__main__":
    main()