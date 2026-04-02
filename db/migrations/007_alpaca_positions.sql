-- db/migrations/007_alpaca_positions.sql

CREATE TABLE IF NOT EXISTS alpaca_positions (
    symbol TEXT PRIMARY KEY,
    qty NUMERIC,
    avg_entry_price NUMERIC,
    market_value NUMERIC,
    unrealized_pl NUMERIC,
    last_updated TIMESTAMP
);