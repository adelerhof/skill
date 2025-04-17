import os

import requests

port = os.getenv("PORT", "5000")
url = f"http://localhost:{port}/api/health"

try:
    response = requests.get(url)
    if response.status_code == 200:
        exit(0)
    else:
        exit(1)
except requests.exceptions.RequestException:
    exit(1)
