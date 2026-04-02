# Augur

A local-first trading OS for selling options premium. Tracks positions,
logs trades, runs paper simulations, and builds a queryable archive of
your own decisions.

Not a bot. Not an executor. An archivist.

## Architecture

Five services, all running in Docker:

- **collector** — polls the Schwab API, writes positions and greeks to Postgres
- **positions** — maintains current state of open positions, fires rule triggers
- **paper** — synthetic trade engine with configurable fill simulation
- **analytics** — queryable history layer across real and paper trades
- **api** — read-only REST API serving the React frontend

## Quickstart

```bash
cp .env.example .env
# fill in your Schwab API credentials

docker-compose up
```

On first run, the collector will prompt you to complete the Schwab OAuth flow
in your browser. The token is saved to a Docker volume and reused on restart.

## Database

Postgres 16. Migrations run automatically on first start from `db/migrations/`.

## Option Chain Module

`services/collector/schwab/option_chain.py` contains typed Python wrappers
for parsing Schwab's option chain response, including greek extraction and
delta-based strike selection. This module is written to be portable back to
schwab-py as a contribution — it has no Augur-specific dependencies.

## Stack

- Python 3.12
- Postgres 16
- React (frontend, coming soon)
- schwab-py for Schwab API access

## Status

Milestone 1 in progress: collector scaffold, database schema, Docker setup.
