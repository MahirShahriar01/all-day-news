#!/usr/bin/env sh
# Back up the database and uploaded media into ./backups/<timestamp>/.
# Schedule it daily, e.g.:  0 3 * * * cd /opt/all-in-one-news/deploy && ./backup.sh
set -eu
STAMP=$(date +%Y%m%d-%H%M%S)
DEST="backups/$STAMP"
mkdir -p "$DEST"
docker compose exec -T db pg_dump -U allinone -d allinone --format=custom > "$DEST/database.dump"
docker compose exec -T api tar -C /app -czf - uploads > "$DEST/uploads.tar.gz"
echo "Backup written to $DEST"
# Keep the 14 most recent backups.
ls -1d backups/*/ | sort | head -n -14 | xargs -r rm -rf
