from app.core.config import get_settings


def absolute_url(value: str) -> str:
    """Turn a stored media path (``/uploads/x.png``) into a URL the app can load."""
    if not value:
        return ""
    if value.startswith("/"):
        return f"{get_settings().public_base_url}{value}"
    return value
