#!/bin/bash
# Deploy frontend with cache-busting
set -e

cd /opt/Apexv2
git pull
cp -r frontend/build/web/* /usr/share/nginx/html/

# Add cache-busting timestamp
TS=$(date +%Y%m%d%H%M%S)
sed -i "s/flutter_bootstrap\.js[?v=0-9]*/flutter_bootstrap.js?v=$TS/g" /usr/share/nginx/html/index.html
sed -i "s/main\.dart\.js[?v=0-9]*/main.dart.js?v=$TS/g" /usr/share/nginx/html/flutter_bootstrap.js

echo "Deployed with cache-bust v=$TS"
