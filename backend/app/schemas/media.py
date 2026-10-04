from datetime import datetime

from app.schemas.common import ORMModel


class MediaOut(ORMModel):
    id: int
    kind: str
    url: str
    absolute_url: str = ""
    mime_type: str
    size_bytes: int
    width: int | None
    height: int | None
    original_name: str
    created_at: datetime
