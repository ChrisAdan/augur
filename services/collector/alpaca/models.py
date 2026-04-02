from pydantic import BaseModel
from datetime import datetime
from typing import Optional


class AlpacaOrder(BaseModel):
    id: str
    client_order_id: Optional[str]
    symbol: str
    side: str
    type: str
    time_in_force: Optional[str]
    qty: Optional[float]
    notional: Optional[float]
    status: str
    submitted_at: datetime
    filled_at: Optional[datetime]
    filled_avg_price: Optional[float]


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
    last_updated: datetime