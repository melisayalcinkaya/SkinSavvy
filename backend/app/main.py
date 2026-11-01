"""SkinSavvy API: hesap, cilt profili, ürün kataloğu, onaylı ürün ekleme ve yorumlar."""

from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware

from .config import Settings, get_settings
from .db import Database
from .ratelimit import RateLimiter
from .routers import admin, auth, products, users
from .seed import seed

_DOCS = ("/docs", "/redoc", "/openapi.json")


def create_app(settings: Settings | None = None) -> FastAPI:
    settings = settings or get_settings()
    db = Database(settings.database_url)

    @asynccontextmanager
    async def lifespan(app: FastAPI):
        db.create_all()
        with db.sessions() as s:
            seed(s, settings)
        yield
        db.engine.dispose()

    app = FastAPI(
        title="SkinSavvy API",
        version="1.0.0",
        description="Kişisel cilt bakım asistanı SkinSavvy'nin sunucusu.",
        lifespan=lifespan,
    )
    app.state.settings = settings
    app.state.db = db
    app.state.limiter = RateLimiter()

    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origin_list,
        allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
        allow_headers=["Authorization", "Content-Type"],
        max_age=600,
    )

    @app.middleware("http")
    async def security_headers(request: Request, call_next):
        response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["Referrer-Policy"] = "no-referrer"
        response.headers["X-Frame-Options"] = "DENY"
        if not request.url.path.startswith(_DOCS):
            # API yalnızca JSON döner; tarayıcıda hiçbir şey çalıştırılmasın.
            response.headers["Content-Security-Policy"] = "default-src 'none'; frame-ancestors 'none'"
        if settings.environment == "production":
            response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
        return response

    @app.get("/health", tags=["Sistem"])
    def health() -> dict:
        return {"status": "ok"}

    for r in (auth.router, users.router, products.router, admin.router):
        app.include_router(r)
    return app


app = create_app()
