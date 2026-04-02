-- db/migrations/006_alpaca_fills.sql

CREATE TABLE IF NOT EXISTS alpaca_fills (
    id TEXT PRIMARY KEY,
    order_id TEXT REFERENCES alpaca_orders(id),
    symbol TEXT,
    side TEXT,
    qty NUMERIC,
    price NUMERIC,
    executed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_fills_order_id ON alpaca_fills(order_id);
CREATE INDEX idx_fills_symbol ON alpaca_fills(symbol);