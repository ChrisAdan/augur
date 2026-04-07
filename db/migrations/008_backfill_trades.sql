-- db/migrations/008_backfill_trades.sql
-- Backfill from options_tracker_v2 as of 2026-04-07.
-- All trades are real (is_paper = FALSE).
-- Strikes stored as JSONB with legs labeled by role.
-- credit_debit: positive = net credit received, negative = net debit paid.

CREATE SCHEMA IF NOT EXISTS src;

-- ─── CLOSED TRADES ────────────────────────────────────────────────────────────

-- Trade 1: SPY Iron Condor — WIN
WITH t AS (
    INSERT INTO src.trades (
        trade_number, underlying, strategy_type, category,
        opened_at, expiry_date,
        strikes, credit_debit, spread_width,
        short_put_delta, short_call_delta,
        thesis, contracts, is_paper
    ) VALUES (
        1, 'SPY', 'Iron Condor', '45 DTE Premium',
        '2026-02-27 09:31:00-05', '2026-04-17',
        '{"short_put": 635, "long_put": 640, "short_call": 722, "long_call": 727}', 1.25, 5.00,
        -0.16, 0.16,
        'Neutral — sell premium, SPY well inside tent', 10, FALSE
    ) RETURNING id
)
INSERT INTO src.trade_closes (trade_id, closed_at, close_price, exit_reason, result, notes)
SELECT id, '2026-03-18 00:00:00-05', 0.15, '50% Profit Target', 'WIN',
    'First condor. OCO set. Healthy throughout. Closed at profit target.'
FROM t;

-- Trade 2: QQQ Iron Condor — WIN
WITH t AS (
    INSERT INTO src.trades (
        trade_number, underlying, strategy_type, category,
        opened_at, expiry_date,
        strikes, credit_debit, spread_width,
        short_put_delta, short_call_delta,
        thesis, contracts, is_paper
    ) VALUES (
        2, 'QQQ', 'Iron Condor', '45 DTE Premium',
        '2026-03-03 09:31:00-05', '2026-04-17',
        '{"short_put": 545, "long_put": 550, "short_call": 640, "long_call": 645}', 1.88, 5.00,
        -0.17, 0.19,
        'Neutral — QQQ below 50MA, high IVP environment', 10, FALSE
    ) RETURNING id
)
INSERT INTO src.trade_closes (trade_id, closed_at, close_price, exit_reason, result, notes)
SELECT id, '2026-03-16 00:00:00-05', 0.93, '50% Profit Target', 'WIN',
    'Second condor. War environment. QQQ put side tested but held. Closed at profit target.'
FROM t;

-- Trade 3: UNH Iron Condor — LOSS (accidental close)
WITH t AS (
    INSERT INTO src.trades (
        trade_number, underlying, strategy_type, category,
        opened_at, expiry_date,
        strikes, credit_debit, spread_width,
        ivp_at_entry, hv_at_entry, iv_hv_gap,
        short_put_delta, short_call_delta,
        thesis, contracts, is_paper
    ) VALUES (
        3, 'UNH', 'Iron Condor', '45 DTE Premium',
        '2026-03-10 09:31:00-05', '2026-04-24',
        '{"short_put": 245, "long_put": 255, "short_call": 325, "long_call": 335}', 3.63, 10.00,
        0.29, 0.11, 0.18,
        -0.16, 0.16,
        'Neutral — UNH downtrend but IV/HV gap 18pts, IVP 29%', 10, FALSE
    ) RETURNING id
)
INSERT INTO src.trade_closes (trade_id, closed_at, close_price, exit_reason, result, notes)
SELECT id, '2026-03-11 00:00:00-05', 3.31, 'Manual Close — Accidental (closed instead of ORCL)', 'LOSS',
    'Accidentally closed UNH instead of ORCL. Small loss $320. Key lesson: verify symbol before closing.'
FROM t;

-- Trade 4: ORCL Iron Condor — WIN (earnings)
WITH t AS (
    INSERT INTO src.trades (
        trade_number, underlying, strategy_type, category,
        opened_at, expiry_date,
        strikes, credit_debit, spread_width,
        ivp_at_entry, hv_at_entry, iv_hv_gap,
        short_put_delta, short_call_delta,
        thesis, contracts, is_paper
    ) VALUES (
        4, 'ORCL', 'Iron Condor', 'Earnings Play',
        '2026-03-09 09:31:00-05', '2026-03-13',
        '{"short_put": 127, "long_put": 132, "short_call": 167.5, "long_call": 172.5}', 1.77, 5.00,
        0.97, 0.31, 0.66,
        -0.17, 0.19,
        'Earnings IV crush — ORCL IVP 97%, gap 66pts. Close morning after earnings.', 10, FALSE
    ) RETURNING id
)
INSERT INTO src.trade_closes (trade_id, closed_at, close_price, exit_reason, result, notes)
SELECT id, '2026-03-11 00:00:00-05', 0.85, '50% Profit Target (OCO)', 'WIN',
    'First earnings play. ORCL gapped up toward short call after earnings. IV crush worked. Panic close at 1.36 didn''t fill. Original 0.85 target hit. Key lesson: trust the system.'
FROM t;

-- Trade 5: MU Iron Condor — WIN (earnings)
WITH t AS (
    INSERT INTO src.trades (
        trade_number, underlying, strategy_type, category,
        opened_at, expiry_date,
        strikes, credit_debit, spread_width,
        ivp_at_entry, hv_at_entry, iv_hv_gap,
        short_put_delta, short_call_delta,
        thesis, contracts, is_paper
    ) VALUES (
        5, 'MU', 'Iron Condor', 'Earnings Play',
        '2026-03-11 09:31:00-05', '2026-03-20',
        '{"short_put": 345, "long_put": 360, "short_call": 490, "long_call": 500}', 3.35, 10.00,
        0.74, 0.44, 0.30,
        -0.16, 0.16,
        'Earnings IV crush — MU IVP 74%, gap 30pts. RSI 81, overbought.', 10, FALSE
    ) RETURNING id
)
INSERT INTO src.trade_closes (trade_id, closed_at, close_price, exit_reason, result, notes)
SELECT id, '2026-03-19 09:45:00-05', 0.16, '50% Profit Target — morning after earnings', 'WIN',
    'MU reports 3/18 after close. Close 3/19 morning. Strikes at 16 delta outside expected move ±$53.'
FROM t;

-- Trade 6: ADBE Iron Condor — LOSS (earnings, moved through strikes)
WITH t AS (
    INSERT INTO src.trades (
        trade_number, underlying, strategy_type, category,
        opened_at, expiry_date,
        strikes, credit_debit, spread_width,
        ivp_at_entry, hv_at_entry, iv_hv_gap,
        short_put_delta, short_call_delta,
        thesis, contracts, is_paper
    ) VALUES (
        6, 'ADBE', 'Iron Condor', 'Earnings Play',
        '2026-03-11 09:31:00-05', '2026-03-13',
        '{"short_put": 250, "long_put": 252.5, "short_call": 307.5, "long_call": 310}', 0.83, 2.50,
        0.84, 0.33, 0.51,
        -0.16, 0.16,
        'Earnings IV crush — ADBE IVP 84%, gap 51pts. Reports 3/12.', 10, FALSE
    ) RETURNING id
)
INSERT INTO src.trade_closes (trade_id, closed_at, close_price, exit_reason, result, notes)
SELECT id, '2026-03-13 09:45:00-05', 2.23, 'Close morning after earnings', 'LOSS',
    'ADBE reports 3/12. Put side at 250 slightly inside expected move ±$22. Call side clean at 307.5.'
FROM t;

-- Trade 8: USO Calendar — WIN (closed 3/20, sold back at 5.50 vs 4.90 paid)
WITH t AS (
    INSERT INTO src.trades (
        trade_number, underlying, strategy_type, category,
        opened_at, expiry_date,
        strikes, credit_debit, spread_width,
        ivp_at_entry, hv_at_entry, iv_hv_gap,
        thesis, contracts, is_paper
    ) VALUES (
        8, 'USO', 'Calendar Spread', 'Vol/Term Structure',
        '2026-03-18 09:46:00-05', '2026-04-17',
        '{"short_put_front": 118, "long_put_back": 118, "front_expiry": "2026-03-27", "back_expiry": "2026-04-17"}', -4.90, NULL,
        0.70, 0.98, -0.28,
        'Term structure play — sell March 27 hump at 108% IV, buy April 17 at 95% IV. 13pt gap.', 5, FALSE
    ) RETURNING id
)
INSERT INTO src.trade_closes (trade_id, closed_at, close_price, exit_reason, result, notes)
SELECT id, '2026-03-20 00:00:00-05', -5.50, 'Manual Close — USO moved too fast', 'WIN',
    'Close before March 26. USO moving 3-4%/day — big moves kill calendar. Sold back at 5.50 vs 4.90 paid.'
FROM t;

-- Trade 9: SPY EOM Iron Condor — WIN (closed 3/31)
WITH t AS (
    INSERT INTO src.trades (
        trade_number, underlying, strategy_type, category,
        opened_at, expiry_date,
        strikes, credit_debit, spread_width,
        thesis, contracts, is_paper
    ) VALUES (
        9, 'SPY', 'Iron Condor', 'Vol/Term Structure',
        '2026-03-19 09:51:00-05', '2026-04-30',
        '{"short_put": 600, "long_put": 580, "short_call": 696, "long_call": 716}', 4.44, 20.00,
        NULL, 5, FALSE
    ) RETURNING id
)
INSERT INTO src.trade_closes (trade_id, closed_at, close_price, exit_reason, result, notes)
SELECT id, '2026-03-31 00:00:00-05', 2.15, 'Profit Target', 'WIN',
    'SPY EOM condor. Closed at 2.15 vs 4.44 credit.'
FROM t;

-- Trade 12: GDX Bull Put Spread — WIN
WITH t AS (
    INSERT INTO src.trades (
        trade_number, underlying, strategy_type, category,
        opened_at, expiry_date,
        strikes, credit_debit,
        thesis, contracts, is_paper
    ) VALUES (
        12, 'GDX', 'Bull Put Spread', 'Directional Credit',
        '2026-03-23 09:31:00-05', '2026-04-17',
        '{"short_put": 78, "long_put": 73}', 1.22,
        NULL, 5, FALSE
    ) RETURNING id
)
INSERT INTO src.trade_closes (trade_id, closed_at, close_price, exit_reason, result, notes)
SELECT id, '2026-03-31 00:00:00-05', 0.54, 'Profit Target', 'WIN',
    'Sold 3/23 at 1.22, bought back 3/31 at 0.54.'
FROM t;

-- ─── OPEN TRADES ──────────────────────────────────────────────────────────────

-- Trade 7: TSM Bull Call Spread — OPEN (partial closes not loggable yet)
INSERT INTO src.trades (
    trade_number, underlying, strategy_type, category,
    opened_at, expiry_date,
    strikes, credit_debit, spread_width,
    ivp_at_entry, hv_at_entry, iv_hv_gap,
    thesis, contracts, is_paper
) VALUES (
    7, 'TSM', 'Bull Call Spread', 'Directional Debit',
    '2026-03-17 09:31:00-05', '2026-04-17',
    '{"long_call": 340, "short_call": 360}', -8.70, 20.00,
    0.38, 0.35, 0.03,
    'Bullish — institutional P/C ratio 0.164 extreme call buying, price above MAs, RSI recovering from correction.', 4, FALSE
);

-- Trade 10: GOOG Diagonal — OPEN (rolled 3/26, no clean close structure yet)
INSERT INTO src.trades (
    trade_number, underlying, strategy_type, category,
    opened_at,
    strikes, credit_debit, spread_width,
    thesis, contracts, is_paper
) VALUES (
    10, 'GOOG', 'Diagonal Spread', 'Directional Debit',
    '2026-03-19 09:31:00-05',
    '{"long_call": 315, "short_call": 325, "note": "rolled short to 300C May15 on 3/26 at 7.60 credit"}', 31.50, 10.00,
    'Rolled 3/26: sold 300/325 diagonal at 7.60. No clean expiry date — tracking roll in notes.', 1, FALSE
);

-- Trade 11: TLT Diagonal — OPEN
INSERT INTO src.trades (
    trade_number, underlying, strategy_type, category,
    opened_at, expiry_date,
    strikes, credit_debit, spread_width,
    thesis, contracts, is_paper
) VALUES (
    11, 'TLT', 'Diagonal Spread', 'Directional Debit',
    '2026-03-19 09:31:00-05', '2027-04-01',
    '{"long_call": 87, "short_call": 91, "long_expiry": "2027-01-15", "short_expiry": "2026-05-01"}', -3.88, 4.00,
    NULL, 1, FALSE
);

-- Trade 13: NVDA Iron Condor — OPEN
INSERT INTO src.trades (
    trade_number, underlying, strategy_type, category,
    opened_at, expiry_date,
    strikes, credit_debit,
    thesis, contracts, is_paper
) VALUES (
    13, 'NVDA', 'Iron Condor', 'Vol/Term Structure',
    '2026-03-24 09:31:00-05', '2026-05-15',
    '{"short_call": 195, "long_call": 200, "short_put": 155, "long_put": 150}', 1.82,
    NULL, 5, FALSE
);

-- Trade 14: USO Diagonal — OPEN
INSERT INTO src.trades (
    trade_number, underlying, strategy_type, category,
    opened_at,
    strikes, credit_debit,
    thesis, contracts, is_paper
) VALUES (
    14, 'USO', 'Diagonal Spread', 'Directional Debit',
    '2026-03-27 09:31:00-05',
    '{"short_put": 107, "long_put": 115, "short_expiry": "2026-04-08", "long_expiry": "2027-01-15"}', -14.80,
    NULL, 1, FALSE
);

-- Trade 15: GDX Calendar — OPEN
INSERT INTO src.trades (
    trade_number, underlying, strategy_type, category,
    opened_at,
    strikes, credit_debit,
    thesis, contracts, is_paper
) VALUES (
    15, 'GDX', 'Calendar Spread', 'Directional Debit',
    '2026-04-02 09:31:00-05',
    '{"call": 100, "short_expiry": "2026-04-10", "long_expiry": "2027-01-15"}', -12.14,
    NULL, 1, FALSE
);

-- Trade 16: SPY Iron Condor May15 — OPEN
INSERT INTO src.trades (
    trade_number, underlying, strategy_type, category,
    opened_at, expiry_date,
    strikes, credit_debit,
    thesis, contracts, is_paper
) VALUES (
    16, 'SPY', 'Iron Condor', 'Vol/Term Structure',
    '2026-04-01 09:31:00-05', '2026-05-15',
    '{"short_put": 600, "long_put": 590, "short_call": 690, "long_call": 700}', 3.03,
    NULL, 3, FALSE
);

-- Trade 17: QQQ Iron Condor May15 — OPEN (date corrected from garbled '41/2026' to 4/1/2026)
INSERT INTO src.trades (
    trade_number, underlying, strategy_type, category,
    opened_at, expiry_date,
    strikes, credit_debit,
    thesis, contracts, is_paper
) VALUES (
    17, 'QQQ', 'Iron Condor', 'Vol/Term Structure',
    '2026-04-01 09:31:00-05', '2026-05-15',
    '{"short_put": 515, "long_put": 525, "short_call": 620, "long_call": 630}', 3.04,
    NULL, 3, FALSE
);

-- Trade 18: XLE Diagonal — OPEN
INSERT INTO src.trades (
    trade_number, underlying, strategy_type, category,
    opened_at,
    strikes, credit_debit,
    thesis, contracts, is_paper
) VALUES (
    18, 'XLE', 'Diagonal Spread', 'Directional Debit',
    '2026-04-01 09:31:00-05',
    '{"short_put": 59.5, "long_put": 55, "short_expiry": "2026-04-10", "long_expiry": "2027-01-15"}', -2.08,
    NULL, 10, FALSE
);