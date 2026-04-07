CREATE SCHEMA IF NOT EXISTS src;

CREATE TABLE IF NOT EXISTS src.alpaca_fills (
    id           TEXT PRIMARY KEY,
    order_id     TEXT REFERENCES src.alpaca_orders(id),
    symbol       TEXT,
    side         TEXT,
    qty          NUMERIC,
    price        NUMERIC,
    executed_at  TIMESTAMPTZ,
    created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_fills_order_id ON src.alpaca_fills(order_id);
CREATE INDEX idx_fills_symbol ON src.alpaca_fills(symbol);