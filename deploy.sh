#!/bin/bash
# Apex HRMS — VPS Deployment Script
# Run this on your VPS after cloning the repo
# Usage: bash deploy.sh

set -e

echo "=== Apex HRMS Deployment ==="

# 1. Install Docker if not present
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    curl -fsSL https://get.docker.com | sh
    sudo usermod -aG docker $USER
    echo "Docker installed. Please log out and back in, then re-run this script."
    exit 1
fi

# 2. Install Docker Compose plugin if not present
if ! docker compose version &> /dev/null; then
    echo "Installing Docker Compose plugin..."
    sudo apt-get update
    sudo apt-get install -y docker-compose-plugin
fi

# 3. Create .env from example if not exists
if [ ! -f .env ]; then
    echo "Creating .env from .env.example..."
    cp .env.example .env
    
    # Generate random secret key
    SECRET_KEY=$(openssl rand -hex 32)
    sed -i "s/change-this-to-a-random-secret-key-in-production-min-32-chars/$SECRET_KEY/" .env
    
    # Generate Fernet encryption key
    FERNET_KEY=$(python3 -c "from cryptography.fernet import Fernet; print(Fernet.generate_key().decode())" 2>/dev/null || echo "CHANGE_ME_GENERATE_WITH_PYTHON")
    
    echo ""
    echo "=== IMPORTANT: Edit .env file ==="
    echo "1. Set ENCRYPTION_KEY to: $FERNET_KEY"
    echo "2. Update CORS_ORIGINS with your domain"
    echo "3. Update POSTGRES_PASSWORD for production"
    echo ""
    read -p "Press Enter after editing .env..."
fi

# 4. Build Flutter frontend
echo "Building Flutter frontend..."
if command -v flutter &> /dev/null; then
    cd frontend
    flutter pub get
    flutter build web --release
    cd ..
else
    echo "Flutter not installed. Please install Flutter or build locally and upload build/web folder."
    echo "See: https://docs.flutter.dev/get-started/install"
    exit 1
fi

# 5. Create upload directory
mkdir -p uploads

# 6. Start Docker services
echo "Starting Docker services..."
docker compose up -d --build

# 7. Wait for services to be healthy
echo "Waiting for services to start..."
sleep 10

# 8. Run database migrations
echo "Running database migrations..."
docker compose exec backend alembic upgrade head

# 9. Check service status
echo ""
echo "=== Service Status ==="
docker compose ps

echo ""
echo "=== Deployment Complete ==="
echo "Backend API: http://localhost:8000"
echo "Frontend: Build at frontend/build/web"
echo ""
echo "Next steps:"
echo "1. Copy nginx/apex.conf to /etc/nginx/sites-available/apex"
echo "2. Edit the config with your domain"
echo "3. sudo ln -s /etc/nginx/sites-available/apex /etc/nginx/sites-enabled/"
echo "4. sudo nginx -t && sudo systemctl reload nginx"
echo "5. (Optional) sudo certbot --nginx -d YOUR_DOMAIN"
