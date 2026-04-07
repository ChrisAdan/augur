from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class AlpacaOrder(BaseModel):
    id: str
    client_order_id: Optional[str] = None
    symbol: str
    side: str
    type: str
    time_in_force: Optional[str] = None
    qty: Optional[float] = None
    notional: Optional[float] = None
    status: str
    submitted_at: datetime
    filled_at: Optional[datetime] = None
    filled_avg_price: Optional[float] = None


class AlpacaFill(BaseModel):
    id: str
    order_id: str
    symbol: str
    side: str
    qty: float
    price: float
    executed_at: datetime


class AlpacaPosition(BaseModel):
    symbol: str
    qty: float
    avg_entry_price: float
    market_value: float
    unrealized_pl: float
    last_updated: Optional[datetime] = None  # populated from API when available