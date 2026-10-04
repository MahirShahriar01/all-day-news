"""FastAPI application factory."""

from __future__ import annotations

import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from fastapi.responses import FileResponse, JSONResponse
from fastapi.staticfiles import StaticFiles

from app.api.v1.router import api_router
from app.core.config import get_settings
from app.db.session import SessionLocal
from app.services.bootstrap import bootstrap, run_migrations
from app.web import router as web_router

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
log = logging.getLogger("allinone")


@asynccontextmanager
async def lifespan(_: FastAPI):
    settings = get_settings()
    if settings.is_production and settings.database_url.startswith("sqlite"):
        log.warning("Running production on SQLite. PostgreSQL is recommended.")
    if settings.auto_migrate:
        run_migrations()
        with SessionLocal() as db:
            bootstrap(db)
    yield


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(
        title=settings.app_name,
        version="1.0.0",
        lifespan=lifespan,
        docs_url="/docs",
        redoc_url="/redoc",
        openapi_url="/openapi.json",
    )

    app.add_middleware(GZipMiddleware, minimum_size=1024)
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.cors_origin_list,
        allow_credentials=False,
        allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
        allow_headers=["Authorization", "Content-Type", "If-None-Match"],
        expose_headers=["ETag"],
    )

    @app.middleware("http")
    async def security_headers(request: Request, call_next):
        response = await call_next(request)
        response.headers.setdefault("X-Content-Type-Options", "nosniff")
        response.headers.setdefault("Referrer-Policy", "strict-origin-when-cross-origin")
        response.headers.setdefault("X-Frame-Options", "DENY")
        if request.url.path.startswith("/uploads/"):
            # File names are random and never reused, so they can be cached forever.
            response.headers["Cache-Control"] = "public, max-age=31536000, immutable"
            response.headers["Content-Security-Policy"] = "default-src 'none'; sandbox"
        if settings.is_production:
            response.headers.setdefault("Strict-Transport-Security", "max-age=31536000; includeSubDomains")
        return response

    @app.exception_handler(Exception)
    async def unhandled(_: Request, exc: Exception):  # pragma: no cover - safety net
        log.exception("Unhandled error", exc_info=exc)
        return JSONResponse(status_code=500, content={"detail": "Something went wrong. Please try again."})

    app.include_router(api_router, prefix=settings.api_v1_prefix)
    app.include_router(web_router)

    settings.media_root.mkdir(parents=True, exist_ok=True)
    app.mount("/uploads", StaticFiles(directory=settings.media_root), name="uploads")

    if settings.admin_static_dir and settings.admin_static_dir.exists():
        admin_dir = settings.admin_static_dir.resolve()
        app.mount("/admin/assets", StaticFiles(directory=admin_dir / "assets"), name="admin-assets")

        @app.get("/admin/{path:path}", include_in_schema=False)
        def admin_spa(path: str):
            candidate = (admin_dir / path).resolve()
            if path and candidate.is_file() and admin_dir in candidate.parents:
                return FileResponse(candidate)
            return FileResponse(admin_dir / "index.html")

    return app


app = create_app()
