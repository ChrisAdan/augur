CREATE SCHEMA IF NOT EXISTS src;

CREATE TABLE IF NOT EXISTS src.trades (
    id              SERIAL PRIMARY KEY,
    trade_number    INTEGER,
    underlying      VARCHAR(16) NOT NULL,
    strategy_type   VARCHAR(64) NOT NULL,
    category        VARCHAR(64),
    opened_at       TIMESTAMPTZ NOT NULL,
    expiry_date     DATE NOT NULL,
    close_deadline  DATE,
    strikes         JSONB NOT NULL,
    credit_debit    NUMERIC(10, 2) NOT NULL,  -- negative = debit
    spread_width    NUMERIC(10, 2),
    ivp_at_entry    NUMERIC(5, 2),
    hv_at_entry     NUMERIC(5, 2),
    iv_hv_gap       NUMERIC(5, 2),
    short_put_delta NUMERIC(6, 4),
    short_call_delta NUMERIC(6, 4),
    thesis          TEXT,
    contracts       INTEGER NOT NULL DEFAULT 1,
    is_paper        BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS src.trade_closes (
    id              SERIAL PRIMARY KEY,
    trade_id        INTEGER NOT NULL REFERENCES src.trades(id),
    closed_at       TIMESTAMPTZ NOT NULL,
    close_price     NUMERIC(10, 2) NOT NULL,
    dte_at_close    INTEGER,
    days_held       INTEGER,
    exit_reason     TEXT,
    result          VARCHAR(16) CHECK (result IN ('WIN', 'LOSS', 'SCRATCH')),
    pl_dollars      NUMERIC(10, 2),
    pl_pct_of_max   NUMERIC(6, 4),
    notes           TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_trades_underlying ON src.trades(underlying);
CREATE INDEX idx_trades_strategy_type ON src.trades(strategy_type);
CREATE INDEX idx_trades_opened_at ON src.trades(opened_at);
CREATE INDEX idx_trades_is_paper ON src.trades(is_paper);
CREATE INDEX idx_trade_closes_trade_id ON src.trade_closes(trade_id);