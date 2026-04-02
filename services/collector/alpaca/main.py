from .client import AlpacaClient
from .repository import AlpacaRepository
from .models import AlpacaOrder


def run() -> None:
    client: AlpacaClient = AlpacaClient()
    repo: AlpacaRepository = AlpacaRepository()

    orders: list[AlpacaOrder] = client.fetch_orders()
    repo.upsert_orders(orders)

    print(f"Ingested {len(orders)} orders")


if __name__ == "__main__":
    run()