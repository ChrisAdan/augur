CREATE SCHEMA IF NOT EXISTS src;

CREATE TABLE IF NOT EXISTS src.alpaca_orders (
    id               TEXT PRIMARY KEY,
    client_order_id  TEXT,
    symbol           TEXT NOT NULL,
    side             TEXT NOT NULL,
    type             TEXT NOT NULL,
    time_in_force    TEXT,
    qty              NUMERIC,
    notional         NUMERIC,
    status           TEXT,
    submitted_at     TIMESTAMPTZ,
    filled_at        TIMESTAMPTZ,
    filled_avg_price NUMERIC,
    created_at       TIMESTAMPTZ DEFAULT NOW(),
    updated_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_alpaca_orders_symbol ON src.alpaca_orders(symbol);
CREATE INDEX idx_alpaca_orders_status ON src.alpaca_orders(status);