-- db/migrations/005_alpaca_orders.sql

CREATE TABLE IF NOT EXISTS alpaca_orders (
    id TEXT PRIMARY KEY,
    client_order_id TEXT,
    symbol TEXT NOT NULL,
    side TEXT NOT NULL,
    type TEXT NOT NULL,
    time_in_force TEXT,
    qty NUMERIC,
    notional NUMERIC,
    status TEXT,
    submitted_at TIMESTAMP,
    filled_at TIMESTAMP,
    filled_avg_price NUMERIC,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_alpaca_orders_symbol ON alpaca_orders(symbol);
CREATE INDEX idx_alpaca_orders_status ON alpaca_orders(status);