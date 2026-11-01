"""Basit kayan pencere hız sınırlayıcı.

Bellekte tutulur, yani tek süreçli kurulum içindir (Render ücretsiz plan gibi).
Birden fazla sunucu çalışırsa sayaçlar Redis gibi ortak bir yere taşınmalı.
"""

import threading
import time
from collections import defaultdict, deque

from fastapi import HTTPException, Request, status


class RateLimiter:
    def __init__(self) -> None:
        self._hits: dict[str, deque[float]] = defaultdict(deque)
        self._lock = threading.Lock()

    def hit(self, key: str, limit: int, window_seconds: float) -> None:
        now = time.monotonic()
        with self._lock:
            q = self._hits[key]
            while q and q[0] <= now - window_seconds:
                q.popleft()
            if len(q) >= limit:
                retry = max(1, int(q[0] + window_seconds - now) + 1)
                raise HTTPException(
                    status.HTTP_429_TOO_MANY_REQUESTS,
                    "Çok fazla deneme. Lütfen biraz sonra tekrar deneyin.",
                    headers={"Retry-After": str(retry)},
                )
            q.append(now)

    def reset(self) -> None:
        with self._lock:
            self._hits.clear()


def client_ip(request: Request) -> str:
    # Render gibi ters vekillerin arkasında gerçek istemci ilk X-Forwarded-For değeridir.
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else "?"
