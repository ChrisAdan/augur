# Augur

A local-first trading OS for selling options premium. Tracks positions,
logs trades, runs paper simulations, and builds a queryable archive of
your own decisions.

Not a bot. Not an executor. An archivist.

---

## Architecture

Five services, all running in Docker, sharing a Postgres 16 database.

### collector

Polls external brokers and writes raw market data to Postgres.

- **Alpaca** — fetches orders, fills, and equity positions via `alpaca-trade-api`
- **Schwab** — fetches options positions and quotes via `schwab-py` _(in progress)_

Runs two poll loops (configurable intervals):

- Positions loop: `POLL_INTERVAL_POSITIONS` seconds (default 30)
- Quotes loop: `POLL_INTERVAL_QUOTES` seconds (default 60)

On first run, Schwab requires an OAuth browser flow. The token is saved to a
Docker volume (`token_data`) and reused on restart.

### positions

Maintains current state of open positions derived from collector data.
Fires rule triggers when position conditions are met (e.g. 50% profit, DTE threshold).

_Status: scaffold only — not yet implemented._

### paper

Synthetic trade engine. Accepts trade submissions and simulates fills using
configurable fill models (`mid`, `natural`, `worst`).

_Status: scaffold only — not yet implemented._

### analytics

Queryable history layer across real and paper trades. Provides aggregated
P&L, win rate, and per-strategy breakdowns.

_Status: scaffold only — not yet implemented._

### api

Read-only FastAPI service serving the React frontend on port 8000.

_Status: scaffold only — not yet implemented._

---

## Quickstart

```bash
cp .env.example .env
# fill in credentials (Schwab, Alpaca, Postgres password)

docker-compose up
```

Run database migrations manually (outside Docker, for development):

```bash
python src/scripts/run_migrations.py
```

Migrations also run automatically inside the `db` container on first start
via `docker-entrypoint-initdb.d`.

---

## Environment Variables

| Variable                  | Required | Description                                           |
| ------------------------- | -------- | ----------------------------------------------------- |
| `SCHWAB_API_KEY`          | Yes      | Schwab developer app key                              |
| `SCHWAB_APP_SECRET`       | Yes      | Schwab developer app secret                           |
| `SCHWAB_CALLBACK_URL`     | Yes      | OAuth callback URL registered with Schwab             |
| `APCA_API_KEY_ID`         | Yes      | Alpaca API key                                        |
| `APCA_API_SECRET_KEY`     | Yes      | Alpaca secret key                                     |
| `APCA_API_BASE_URL`       | Yes      | `https://paper-api.alpaca.markets` or live equivalent |
| `POSTGRES_HOST`           | Yes      | `db` inside Docker, `localhost` for local dev         |
| `POSTGRES_PORT`           | No       | Default: `5432`                                       |
| `POSTGRES_DB`             | No       | Default: `augur`                                      |
| `POSTGRES_USER`           | No       | Default: `postgres`                                   |
| `POSTGRES_PASSWORD`       | Yes      | Set a real password; do not leave blank in production |
| `DATABASE_URL`            | Yes      | Full DSN used by services                             |
| `POLL_INTERVAL_POSITIONS` | No       | Default: `30` (seconds)                               |
| `POLL_INTERVAL_QUOTES`    | No       | Default: `60` (seconds)                               |
| `DEFAULT_FILL_MODEL`      | No       | Default: `mid` — options: `mid`, `natural`, `worst`   |

---

## Database

Postgres 16. Schema managed via numbered SQL migrations in `db/migrations/`.

Applied migrations are tracked in the `applied_migrations` table so the
runner is idempotent — safe to re-run at any time.

### Migrations

| File                       | Description                                                  |
| -------------------------- | ------------------------------------------------------------ |
| `001_trades.sql`           | Core trade log: `trades` and `trade_closes` tables           |
| `002_rules.sql`            | Rule definitions for position triggers _(empty — pending)_   |
| `003_greek_snapshots.sql`  | Time-series greek snapshots per position _(empty — pending)_ |
| `004_rule_events.sql`      | Fired rule event log _(empty — pending)_                     |
| `005_alpaca_orders.sql`    | Alpaca order ingestion table                                 |
| `006_alpaca_fills.sql`     | Alpaca fill records                                          |
| `007_alpaca_positions.sql` | Current Alpaca equity positions                              |

---

## Project Structure

```
augur/
├── db/
│   └── migrations/          # SQL migration files (applied in order)
├── services/
│   ├── common/
│   │   └── config.py        # Pydantic settings loaded from environment
│   ├── db/
│   │   └── connection.py    # Threaded connection pool (psycopg2)
│   ├── collector/
│   │   ├── alpaca/          # Alpaca client, models, repository
│   │   └── schwab/          # Schwab client (in progress)
│   ├── positions/           # Position state service (scaffold)
│   ├── paper/               # Paper trade engine (scaffold)
│   ├── analytics/           # History and aggregation (scaffold)
│   └── api/                 # FastAPI read layer (scaffold)
├── src/
│   └── scripts/
│       ├── connect_schwab.py   # One-time OAuth token setup
│       └── run_migrations.py   # Manual migration runner
├── frontend/                # React frontend (not yet started)
├── docker-compose.yml
├── .env.example
└── README.md
```

---

## Option Chain Module

`services/collector/schwab/option_chain.py` contains typed Python wrappers
for parsing Schwab's option chain response, including greek extraction and
delta-based strike selection. Written to be portable back to `schwab-py` as
a contribution — no Augur-specific dependencies.

---

## Stack

- Python 3.12
- Postgres 16
- psycopg2 with `ThreadedConnectionPool`
- Pydantic v2 for config and data models
- `schwab-py` for Schwab API access
- `alpaca-trade-api` for Alpaca access
- FastAPI + uvicorn for the API layer
- React (frontend — not yet started)

---

## Known Gaps / In Progress

- **Schwab collector** — `services/collector/schwab/client.py` is empty; Schwab polling loop not yet wired
- **collector `main.py`** — no polling loop implemented; services do not run yet
- **Migrations 002–004** — rules, greek snapshots, rule_events are empty stubs
- **positions / paper / analytics / api** — all scaffold only; `main.py` files are empty
- **Frontend** — `frontend/package.json` is empty; React app not started
- **Trade log backfill** — existing positions from external tracker will be migrated via a one-time script once the tracker is current

---

## Status

Work in Progress ~
