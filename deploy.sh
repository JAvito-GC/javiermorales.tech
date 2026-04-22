#!/bin/bash
# Deploy javiermorales.tech to Hetzner VPS
# Run FROM the VPS after syncing source files
#
# Workflow:
#   1. From MacBook: scp -r site/ root@204.168.160.225:/opt/javiermorales.tech/
#   2. SSH into VPS: ssh -i ~/.ssh/id_motoradar root@204.168.160.225
#   3. On VPS: cd /opt/javiermorales.tech && bash deploy.sh

set -euo pipefail

SITE_DIR="/opt/javiermorales.tech"
PUBLIC_DIR="/var/www/javiermorales.tech"

cd "$SITE_DIR"

if ! command -v hugo &> /dev/null; then
    echo "Hugo not installed. Installing..."
    snap install hugo
fi

hugo --minify

mkdir -p "$PUBLIC_DIR"
rsync -a --delete public/ "$PUBLIC_DIR/"

echo "Deployed to $PUBLIC_DIR"
echo "Test: curl -I https://javiermorales.tech"
