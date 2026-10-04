"""Media storage.

``LocalStorage`` writes into ``MEDIA_ROOT`` and the API serves files from
``/uploads``. To move media to S3 / Cloud Storage / a CDN, implement the
``Storage`` protocol and return it from ``get_storage()`` - nothing else in
the code base needs to change because records store the public URL.
"""

from __future__ import annotations

import io
import secrets
from dataclasses import dataclass
from pathlib import Path
from typing import BinaryIO, Protocol

from PIL import Image, UnidentifiedImageError

from app.core.config import get_settings

CHUNK = 1024 * 1024


class UploadRejected(ValueError):
    """The uploaded file is not acceptable (type, size or content)."""


@dataclass(frozen=True)
class DetectedFile:
    kind: str  # image | animation | video
    mime_type: str
    extension: str
    width: int | None = None
    height: int | None = None


def _sniff(head: bytes) -> tuple[str, str] | None:
    """Detect the real file type from its magic bytes (never trust the name)."""
    if head.startswith(b"\x89PNG\r\n\x1a\n"):
        return "image/png", "png"
    if head.startswith(b"\xff\xd8\xff"):
        return "image/jpeg", "jpg"
    if head[:6] in (b"GIF87a", b"GIF89a"):
        return "image/gif", "gif"
    if head[:4] == b"RIFF" and head[8:12] == b"WEBP":
        return "image/webp", "webp"
    if head[4:8] == b"ftyp":
        return "video/mp4", "mp4"
    if head.startswith(b"\x1a\x45\xdf\xa3"):
        return "video/webm", "webm"
    return None


def inspect_upload(data: bytes) -> DetectedFile:
    sniffed = _sniff(data[:32])
    if sniffed is None:
        raise UploadRejected("Unsupported file type. Allowed: PNG, JPG, WebP, GIF, MP4, WebM.")
    mime, ext = sniffed
    if mime.startswith("video/"):
        return DetectedFile(kind="video", mime_type=mime, extension=ext)
    try:
        with Image.open(io.BytesIO(data)) as img:
            img.verify()
        with Image.open(io.BytesIO(data)) as img:
            width, height = img.size
            animated = bool(getattr(img, "is_animated", False))
    except (UnidentifiedImageError, OSError, Image.DecompressionBombError) as exc:
        raise UploadRejected("The image file is damaged or not a valid image.") from exc
    if width * height > 40_000_000:
        raise UploadRejected("Image is too large (max 40 megapixels).")
    kind = "animation" if animated or mime == "image/gif" else "image"
    return DetectedFile(kind=kind, mime_type=mime, extension=ext, width=width, height=height)


class Storage(Protocol):
    def save(self, data: bytes, extension: str) -> tuple[str, str]:
        """Persist bytes; return (storage_key, public_url)."""

    def delete(self, storage_key: str) -> None: ...


class LocalStorage:
    def __init__(self, root: Path) -> None:
        self.root = root
        self.root.mkdir(parents=True, exist_ok=True)

    def save(self, data: bytes, extension: str) -> tuple[str, str]:
        key = f"{secrets.token_hex(16)}.{extension}"
        (self.root / key).write_bytes(data)
        return key, f"/uploads/{key}"

    def delete(self, storage_key: str) -> None:
        path = (self.root / storage_key).resolve()
        if path.parent == self.root.resolve() and path.exists():
            path.unlink()


def read_limited(stream: BinaryIO, limit: int) -> bytes:
    buf = bytearray()
    while chunk := stream.read(CHUNK):
        buf.extend(chunk)
        if len(buf) > limit:
            raise UploadRejected(f"File is too large (max {limit // (1024 * 1024)} MB).")
    if not buf:
        raise UploadRejected("The file is empty.")
    return bytes(buf)


def get_storage() -> Storage:
    return LocalStorage(get_settings().media_root)
