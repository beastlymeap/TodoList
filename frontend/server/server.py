import os
import time
import threading
import requests
from flask import Flask, request, Response, send_from_directory
from google.auth.transport.requests import Request as GoogleRequest
from google.oauth2 import id_token

API_URL = os.environ.get("API_URL", "").rstrip("/")
STATIC_DIR = os.environ.get("STATIC_DIR", "dist")
PORT = int(os.environ.get("PORT", 8080))

app = Flask(__name__, static_folder=None)

_token_lock = threading.Lock()
_token_cache: dict = {"value": None, "exp": 0.0}


def _get_id_token() -> str | None:
    """Mint a Google ID token with audience=API_URL. Cached for ~55 min."""
    if not API_URL:
        return None
    now = time.time()
    with _token_lock:
        if _token_cache["value"] and now < _token_cache["exp"]:
            return _token_cache["value"]
        token = id_token.fetch_id_token(GoogleRequest(), API_URL)
        _token_cache["value"] = token
        _token_cache["exp"] = now + 55 * 60
        return token


@app.route(
    "/api/<path:subpath>",
    methods=["GET", "POST", "PATCH", "PUT", "DELETE"],
)
def proxy(subpath: str):
    if not API_URL:
        return {"error": "API_URL not configured"}, 500

    url = f"{API_URL}/api/{subpath}"
    hop_by_hop = {
        "host",
        "content-length",
        "connection",
        "keep-alive",
        "transfer-encoding",
        "upgrade",
        "te",
        "trailer",
        "proxy-authorization",
        "proxy-authenticate",
    }
    headers = {
        k: v for k, v in request.headers.items() if k.lower() not in hop_by_hop
    }
    token = _get_id_token()
    if token:
        headers["Authorization"] = f"Bearer {token}"

    upstream = requests.request(
        method=request.method,
        url=url,
        params=request.args,
        data=request.get_data(),
        headers=headers,
        allow_redirects=False,
        timeout=30,
    )

    excluded = {
        "content-encoding",
        "content-length",
        "transfer-encoding",
        "connection",
    }
    out_headers = [
        (k, v) for k, v in upstream.headers.items() if k.lower() not in excluded
    ]
    return Response(upstream.content, status=upstream.status_code, headers=out_headers)


@app.route("/", defaults={"path": ""})
@app.route("/<path:path>")
def static_files(path: str):
    full = os.path.join(STATIC_DIR, path)
    if path and os.path.isfile(full):
        return send_from_directory(STATIC_DIR, path)
    return send_from_directory(STATIC_DIR, "index.html")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=PORT, debug=False)
