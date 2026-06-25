#!/bin/bash
# Apex HRMS — VPS Deployment Script
# Run on Ubuntu 24.04 VPS
set -e

APP_DIR="/opt/Apexv2"
FRONTEND_DIR="/var/www/apexhrms"

echo "=== Apex HRMS VPS Deployment ==="
echo ""

# 1. Clone repo if not exists
if [ ! -d "$APP_DIR" ]; then
    echo "[1/7] Cloning repository..."
    cd /opt
    sudo git clone https://github.com/alpesh15gb/Apexv2.git
    sudo chown -R $USER:$USER $APP_DIR
else
    echo "[1/7] Pulling latest changes..."
    cd $APP_DIR
    git pull origin main
fi

cd $APP_DIR

# 2. Create .env if not exists
if [ ! -f .env ]; then
    echo "[2/7] Creating .env file..."
    cp .env.example .env
    
    # Generate random secret key
    SECRET_KEY=$(openssl rand -hex 32)
    sed -i "s|change-this-to-a-random-secret-key-in-production-min-32-chars|${SECRET_KEY}|g" .env
    
    echo ""
    echo "========================================"
    echo "  .env created with random SECRET_KEY"
    echo "  Edit .env to set ENCRYPTION_KEY"
    echo "========================================"
    echo ""
    echo "Run: nano $APP_DIR/.env"
    echo ""
    read -p "Press Enter after editing .env to continue..."
else
    echo "[2/7] .env already exists, skipping..."
fi

# 3. Build Flutter frontend
echo "[3/7] Building Flutter frontend..."
if command -v flutter &> /dev/null; then
    cd $APP_DIR/frontend
    flutter pub get
    flutter build web --release
    cd $APP_DIR
else
    echo "  Flutter not found. Installing Flutter..."
    sudo apt-get update
    sudo apt-get install -y snapd
    sudo snap install flutter --classic
    cd $APP_DIR/frontend
    flutter pub get
    flutter build web --release
    cd $APP_DIR
fi

# 4. Copy frontend build to web root
echo "[4/7] Deploying frontend..."
sudo mkdir -p $FRONTEND_DIR
sudo rm -rf $FRONTEND_DIR/frontend/build/web
sudo mkdir -p $FRONTEND_DIR/frontend/build
sudo cp -r $APP_DIR/frontend/build/web $FRONTEND_DIR/frontend/build/web
sudo chown -R www-data:www-data $FRONTEND_DIR

# 5. Start Docker services
echo "[5/7] Starting Docker services..."
cd $APP_DIR
docker compose up -d --build

# 6. Wait for services and run migrations
echo "[6/7] Waiting for database..."
sleep 15
echo "Running database migrations..."
docker compose exec -T backend alembic upgrade head

# 7. Configure Nginx
echo "[7/7] Configuring Nginx..."
sudo cp $APP_DIR/nginx/apex.conf /etc/nginx/sites-available/apexhrms.conf

# Check if symlink exists
if [ ! -L /etc/nginx/sites-enabled/apexhrms.conf ]; then
    sudo ln -s /etc/nginx/sites-available/apexhrms.conf /etc/nginx/sites-enabled/apexhrms.conf
fi

# Test and reload Nginx
sudo nginx -t
sudo systemctl reload nginx

echo ""
echo "============================================"
echo "  DEPLOYMENT COMPLETE"
echo "============================================"
echo ""
echo "  Frontend:  http://YOUR_VPS_IP:8084"
echo "  API:       http://127.0.0.1:8001/api/v1"
echo ""
echo "  Docker services:"
docker compose ps
echo ""
echo "  View logs:  docker compose logs -f"
echo "  Restart:    docker compose restart"
echo "  Stop:       docker compose down"
echo ""
