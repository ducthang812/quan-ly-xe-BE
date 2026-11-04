#!/usr/bin/env bash
# Chi chay tren may HN: cai Nginx + Java 17, cho san thu muc FE/BE va dich vu systemd cho BE.
#   sudo bash scripts/50-app-setup.sh
# Sau do: copy ban build FE vao /var/www/pa1, file jar cua BE thanh /opt/pa1-be/app.jar,
# sua mat khau trong /opt/pa1-be/be.env, roi:
#   sudo systemctl enable --now pa1-be
set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "Can chay voi sudo" >&2; exit 1; }
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OWNER="${SUDO_USER:-ubuntu}"

apt-get update -y
apt-get install -y nginx openjdk-17-jre-headless
java -version

mkdir -p /var/www/pa1 /opt/pa1-be
if [[ ! -f /var/www/pa1/index.html ]]; then
  echo '<h1>PA1: chua co ban build FE</h1>' > /var/www/pa1/index.html
fi
chown -R "$OWNER": /var/www/pa1 /opt/pa1-be

cp "$ROOT/app/nginx-pa1.conf" /etc/nginx/sites-available/pa1
ln -sf /etc/nginx/sites-available/pa1 /etc/nginx/sites-enabled/pa1
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

[[ -f /opt/pa1-be/be.env ]] || cp "$ROOT/app/be.env.example" /opt/pa1-be/be.env
chown "$OWNER": /opt/pa1-be/be.env; chmod 600 /opt/pa1-be/be.env
sed "s/^User=.*/User=$OWNER/" "$ROOT/app/pa1-be.service" > /etc/systemd/system/pa1-be.service
systemctl daemon-reload

echo
echo "XONG Nginx. Mo http://<Elastic IP cua may HN> se thay trang tam."
echo "Tiep theo: dua FE vao /var/www/pa1, jar cua BE thanh /opt/pa1-be/app.jar, kiem tra be.env, roi:"
echo "  sudo systemctl enable --now pa1-be && journalctl -u pa1-be -f"
