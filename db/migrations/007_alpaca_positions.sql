CREATE SCHEMA IF NOT EXISTS src;

CREATE TABLE IF NOT EXISTS src.alpaca_positions (
    symbol           TEXT PRIMARY KEY,
    qty              NUMERIC,
    avg_entry_price  NUMERIC,
    market_value     NUMERIC,
    unrealized_pl    NUMERIC,
    last_updated     TIMESTAMPTZ
);