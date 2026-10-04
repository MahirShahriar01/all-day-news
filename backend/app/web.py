"""Small server-rendered pages: the public privacy policy (required by
Google Play and the App Store) and an index page."""

from __future__ import annotations

import html
from datetime import date

from fastapi import APIRouter
from fastapi.responses import HTMLResponse

from app.api.deps import DbSession
from app.services.settings_service import load_settings

router = APIRouter(include_in_schema=False)

DEFAULT_POLICY = """# Privacy Policy

Last updated: {today}

{app} ("the app") is published by {publisher}. This policy explains what information the app handles.

## Information we collect
The app does not require an account and does not ask for your name, e-mail address, phone number, location, contacts, photos or any other personal information.

## Information stored on your device
Your favourites, recently opened websites and app preferences are stored only on your device. They are never uploaded to our servers. Uninstalling the app or clearing its data deletes them.

## Information sent to our server
To show the latest list of websites, the app downloads its configuration from our server. Like any web server, it may briefly record technical data such as your IP address and the time of the request in security logs. These logs are used only to keep the service secure and working, are not used to identify you, and are deleted automatically.

## Third-party websites
The app opens websites and services run by other organisations. When you open one, that website may collect information according to its own privacy policy. We do not control and are not responsible for third-party websites; please review their policies.

## Children
The app is not directed at children under 13 and we do not knowingly collect information from children.

## Security
All communication between the app and our server is encrypted using HTTPS.

## Changes
We may update this policy. Changes are published on this page with a new "Last updated" date.

## Contact
Questions? Contact us at {contact}.
"""


def _render_markdownish(text: str) -> str:
    out: list[str] = []
    for block in text.strip().split("\n\n"):
        block = block.strip()
        if block.startswith("## "):
            out.append(f"<h2>{html.escape(block[3:])}</h2>")
        elif block.startswith("# "):
            out.append(f"<h1>{html.escape(block[2:])}</h1>")
        elif all(line.lstrip().startswith(("- ", "* ")) for line in block.splitlines()):
            items = "".join(f"<li>{html.escape(line.lstrip()[2:])}</li>" for line in block.splitlines())
            out.append(f"<ul>{items}</ul>")
        else:
            out.append(f"<p>{html.escape(block).replace(chr(10), '<br>')}</p>")
    return "\n".join(out)


PAGE = """<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>{title}</title>
<style>
:root{{color-scheme:light dark;--bg:#fff;--fg:#1b1f2a;--muted:#5b6275;--accent:#6c47ff}}
@media (prefers-color-scheme:dark){{:root{{--bg:#0a0e1a;--fg:#eef1ff;--muted:#a3aac4;--accent:#9c86ff}}}}
body{{margin:0;background:var(--bg);color:var(--fg);font:16px/1.65 system-ui,-apple-system,Segoe UI,Roboto,sans-serif}}
main{{max-width:760px;margin:0 auto;padding:40px 20px 80px}}h1{{font-size:2rem;margin:0 0 8px}}
h2{{font-size:1.2rem;margin:32px 0 8px;color:var(--accent)}}p,li{{color:var(--fg)}}
</style></head><body><main>{body}</main></body></html>"""


@router.get("/privacy-policy", response_class=HTMLResponse)
def privacy_policy(db: DbSession) -> HTMLResponse:
    cfg = load_settings(db)
    text = cfg.legal.privacy_policy_text.strip() or DEFAULT_POLICY.format(
        today=date.today().isoformat(),
        app=cfg.branding.app_name,
        publisher=cfg.legal.publisher_name or "the publisher of this app",
        contact=cfg.legal.contact_email or "the e-mail address listed on the store page",
    )
    return HTMLResponse(PAGE.format(title=html.escape(f"Privacy Policy – {cfg.branding.app_name}"), body=_render_markdownish(text)))


@router.get("/")
def index() -> dict:
    return {"name": "All in One News API", "docs": "/docs", "config": "/api/v1/config", "admin": "/admin"}
