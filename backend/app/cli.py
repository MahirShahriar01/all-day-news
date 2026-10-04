"""Command line helpers.

    python -m app.cli init        # migrate + first admin + demo data (used by Docker)
    python -m app.cli migrate
    python -m app.cli create-admin admin@example.com --role owner
    python -m app.cli reset-password admin@example.com
    python -m app.cli seed-demo
"""

from __future__ import annotations

import argparse
import getpass
import sys

from app.core.security import hash_password
from app.db.session import SessionLocal
from app.models import AdminUser
from app.services.bootstrap import bootstrap, run_migrations
from app.services.seed import seed_demo_content


def _ask_password() -> str:
    while True:
        pw = getpass.getpass("New password (min 10 characters): ")
        if len(pw) < 10:
            print("Too short.")
            continue
        if pw != getpass.getpass("Repeat password: "):
            print("Passwords do not match.")
            continue
        return pw


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="python -m app.cli")
    sub = parser.add_subparsers(dest="cmd", required=True)
    sub.add_parser("init", help="Apply migrations, create the first admin and demo data from the environment")
    sub.add_parser("migrate", help="Apply database migrations")
    p = sub.add_parser("create-admin", help="Create an administrator")
    p.add_argument("email")
    p.add_argument("--name", default="")
    p.add_argument("--role", choices=["owner", "editor"], default="owner")
    r = sub.add_parser("reset-password", help="Reset an administrator's password")
    r.add_argument("email")
    sub.add_parser("seed-demo", help="Insert demo categories and websites into an empty database")
    args = parser.parse_args(argv)

    run_migrations()
    if args.cmd == "migrate":
        print("Database is up to date.")
        return 0
    with SessionLocal() as db:
        if args.cmd == "init":
            bootstrap(db)
            print("Initialisation complete.")
        elif args.cmd == "create-admin":
            email = args.email.lower()
            if db.query(AdminUser).filter_by(email=email).first():
                print("An administrator with this e-mail already exists.", file=sys.stderr)
                return 1
            db.add(AdminUser(email=email, full_name=args.name, role=args.role, password_hash=hash_password(_ask_password())))
            db.commit()
            print(f"Created {args.role} {email}")
        elif args.cmd == "reset-password":
            admin = db.query(AdminUser).filter_by(email=args.email.lower()).first()
            if not admin:
                print("No such administrator.", file=sys.stderr)
                return 1
            admin.password_hash = hash_password(_ask_password())
            admin.token_version += 1
            admin.is_active = True
            db.commit()
            print("Password updated; all sessions signed out.")
        elif args.cmd == "seed-demo":
            seed_demo_content(db)
            print("Done.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
