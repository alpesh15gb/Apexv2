#!/bin/bash
set -e

echo "Starting Celery worker..."
celery -A app.tasks.celery_app worker --loglevel=info --concurrency=2 &

echo "Starting Celery beat..."
celery -A app.tasks.celery_app beat --loglevel=info &

echo "Starting Uvicorn..."
exec uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers 4
