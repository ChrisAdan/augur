from typing import Sequence

from services.db.connection import get_connection
from .models import AlpacaOrder


class AlpacaRepository:

    def upsert_orders(self, orders: Sequence[AlpacaOrder]) -> None:
        with get_connection() as conn:
            with conn.cursor() as cur:
                for o in orders:
                    cur.execute(
                        """
                        INSERT INTO alpaca_orders (
                            id, client_order_id, symbol, side, type,
                            time_in_force, qty, notional, status,
                            submitted_at, filled_at, filled_avg_price
                        )
                        VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
                        ON CONFLICT (id) DO UPDATE SET
                            status          = EXCLUDED.status,
                            filled_at       = EXCLUDED.filled_at,
                            filled_avg_price = EXCLUDED.filled_avg_price,
                            updated_at      = NOW()
                        """,
                        (
                            o.id,
                            o.client_order_id,
                            o.symbol,
                            o.side,
                            o.type,
                            o.time_in_force,
                            o.qty,
                            o.notional,
                            o.status,
                            o.submitted_at,
                            o.filled_at,
                            o.filled_avg_price,
                        ),
                    )
            conn.commit()