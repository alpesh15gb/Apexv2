@echo off
REM Apex Attendance Platform - Development Startup Script
echo ========================================
echo  Apex Attendance Platform - Dev Setup
echo ========================================

echo.
echo [1/4] Copying environment file...
if not exist .env (
    copy .env.example .env
    echo Created .env from .env.example
) else (
    echo .env already exists
)

echo.
echo [2/4] Starting Docker containers...
docker compose up -d postgres redis
echo Waiting for database to be ready...
timeout /t 10 /nobreak > nul

echo.
echo [3/4] Running database migrations...
cd backend
alembic upgrade head
echo Migrations complete.

echo.
echo [4/4] Starting backend server...
echo API will be available at: http://localhost:8000
echo API docs at: http://localhost:8000/docs
echo.
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
