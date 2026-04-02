from typing import Any, List, cast
import alpaca_trade_api as tradeapi # type: ignore[import-untyped]
from alpaca_trade_api.common import URL # type: ignore[import-untyped]

from services.common.config import settings
from .models import AlpacaOrder, AlpacaPosition


from typing import Any, List, cast

from services.common.config import settings
from .models import AlpacaOrder, AlpacaPosition


class AlpacaClient:
    def __init__(self) -> None:
        base_url: URL = URL(str(settings.alpaca_base_url))
        self.api: tradeapi.REST = tradeapi.REST(
            settings.alpaca_api_key,
            settings.alpaca_secret_key,
            base_url)
        

    def fetch_orders(self) -> List[AlpacaOrder]:
        raw_orders: list[Any] = self.api.list_orders(status="all", limit=500)  # type: ignore

        orders: list[AlpacaOrder] = []
        for o in raw_orders:
            raw_data: dict[str, Any] = cast(dict[str, Any], getattr(o, "_raw", {}))
            orders.append(AlpacaOrder(**raw_data))

        return orders

    def fetch_positions(self) -> List[AlpacaPosition]:
        raw_positions: list[Any] = self.api.list_positions()  # type: ignore

        positions: list[AlpacaPosition] = []

        for p in raw_positions:
            positions.append(
                AlpacaPosition(
                    symbol=str(p.symbol),
                    qty=float(p.qty),
                    avg_entry_price=float(p.avg_entry_price),
                    market_value=float(p.market_value),
                    unrealized_pl=float(p.unrealized_pl),
                    last_updated=getattr(p, "lastday_price", None)  # type: ignore
                )
            )

        return positions