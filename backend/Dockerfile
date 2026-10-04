# syntax=docker/dockerfile:1
FROM python:3.12-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .
RUN useradd --create-home --uid 10001 appuser \
    && mkdir -p /app/uploads /app/data \
    && chown -R appuser:appuser /app
USER appuser

ENV APP_ENV=production \
    MEDIA_ROOT=/app/uploads \
    AUTO_MIGRATE=false \
    WEB_CONCURRENCY=2

EXPOSE 8000
# Apply migrations / create the first admin once, then start the workers.
CMD ["sh", "-c", "python -m app.cli init && exec uvicorn app.main:app --host 0.0.0.0 --port 8000 --proxy-headers --forwarded-allow-ips '*' --workers ${WEB_CONCURRENCY}"]
