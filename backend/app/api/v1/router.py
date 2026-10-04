"""Version 1 of the API.

A future breaking change goes into ``app/api/v2`` mounted at ``/api/v2``
while v1 keeps serving app versions already installed on phones.
"""

from fastapi import APIRouter

from app.api.v1.endpoints import admins, auth, categories, dashboard, media, public, settings, sites

api_router = APIRouter()
api_router.include_router(public.router)

admin_router = APIRouter(prefix="/admin")
for module in (auth, dashboard, categories, sites, media, settings, admins):
    admin_router.include_router(module.router)
api_router.include_router(admin_router)
