from schwab import auth # type: ignore[import-untyped]
from schwab.client import Client # type: ignore[import-untyped]
import requests
import os
from dotenv import load_dotenv

if __name__ == "__main__":

    load_dotenv()

    client: Client = auth.easy_client(  # type: ignore[assignment]
        api_key=os.getenv('SCHWAB_API_KEY') or '',
        app_secret=os.getenv('SCHWAB_API_SECRET') or '',
        callback_url=os.getenv('SCHWAB_CALLBACK_URL') or '',
        token_path='token.json'
    )

    accounts: requests.Response = client.get_accounts()  # type: ignore[assignment]
    print(accounts.json()) # type: ignore[union-attr]